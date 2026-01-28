import 'dart:ui';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleCubit extends Cubit<Locale> {
  static const String _languageKey = 'app_language';
  static const String _languageSourceKey = 'app_language_source';
  static const String _languageUserSelectedKey = 'app_language_user_selected';
  static const String _sourceUser = 'user';
  static const String _sourceSystem = 'system';

  // Supported languages in the app
  static const List<String> _supportedLanguages = ['en', 'pt', 'de', 'fr'];
  bool _followSystem = true;

  LocaleCubit() : super(const Locale('en')) {
    _init();
  }

  Future<void> _init() async {
    await _loadLocale();
    _setupLocaleListener();
  }

  void _setupLocaleListener() {
    PlatformDispatcher.instance.onLocaleChanged = _handleSystemLocaleChanged;
  }

  void _handleSystemLocaleChanged() {
    if (!_followSystem) return;
    final systemLocale = _getSystemLocale();
    final resolvedLocale = _resolveLocale(systemLocale);
    debugPrint(
      'LocaleCubit: system locale changed to ${systemLocale.toLanguageTag()}, '
      'resolved to ${resolvedLocale.languageCode}',
    );
    if (state != resolvedLocale) {
      emit(resolvedLocale);
    }
    _persistSystemLocale(resolvedLocale);
  }

  void syncWithSystem() {
    debugPrint('LocaleCubit: syncWithSystem called');
    _handleSystemLocaleChanged();
  }

  void _persistSystemLocale(Locale locale) {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_languageKey, locale.languageCode);
      prefs.setString(_languageSourceKey, _sourceSystem);
      prefs.setBool(_languageUserSelectedKey, false);
    }).catchError((_) {
      // ignore persistence errors
    });
  }

  Locale _getSystemLocale() {
    final locales = PlatformDispatcher.instance.locales;
    if (locales.isNotEmpty) {
      return locales.first;
    }
    return PlatformDispatcher.instance.locale;
  }

  Locale _resolveLocale(Locale locale) {
    final languageCode = locale.languageCode;
    if (_supportedLanguages.contains(languageCode)) {
      return Locale(languageCode);
    }
    return const Locale('en');
  }

  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguageCode = prefs.getString(_languageKey);
      final savedSource = prefs.getString(_languageSourceKey);
      final userSelected = prefs.getBool(_languageUserSelectedKey) ?? false;

      final deviceLocale = PlatformDispatcher.instance.locale;
      debugPrint(
        'LocaleCubit: loadLocale savedLanguage=$savedLanguageCode '
        'savedSource=$savedSource userSelected=$userSelected '
        'deviceLocale=${deviceLocale.toLanguageTag()}',
      );

      if (savedSource == _sourceUser && userSelected) {
        _followSystem = false;
        emit(
          _resolveLocale(
            Locale(savedLanguageCode ?? _supportedLanguages.first),
          ),
        );
        debugPrint('LocaleCubit: using user-selected locale, followSystem=false');
        return;
      }

      if (savedSource == _sourceSystem) {
        _followSystem = true;
        final resolvedDeviceLocale = _resolveLocale(deviceLocale);
        emit(resolvedDeviceLocale);
        await prefs.setString(_languageKey, resolvedDeviceLocale.languageCode);
        debugPrint(
          'LocaleCubit: using system locale ${resolvedDeviceLocale.languageCode}',
        );
        return;
      }

      // If user has previously saved a language preference, use it
      if (savedLanguageCode != null && savedLanguageCode.isNotEmpty) {
        _followSystem = true;
        final resolvedDeviceLocale = _resolveLocale(deviceLocale);
        emit(resolvedDeviceLocale);
        await prefs.setString(_languageSourceKey, _sourceSystem);
        await prefs.setString(_languageKey, resolvedDeviceLocale.languageCode);
        return;
      }

      // No saved preference - check device language
      _followSystem = true;
      final resolvedDeviceLocale = _resolveLocale(deviceLocale);
      emit(resolvedDeviceLocale);
      await prefs.setString(_languageSourceKey, _sourceSystem);
      await prefs.setString(_languageKey, resolvedDeviceLocale.languageCode);
      debugPrint(
        'LocaleCubit: no saved preference, using '
        '${resolvedDeviceLocale.languageCode}',
      );
    } catch (_) {
      // ignore persistence errors - will default to English
    }
  }

  Future<void> setLocale(Locale locale) async {
    final resolvedLocale = _resolveLocale(locale);
    _followSystem = false;
    if (state == resolvedLocale) {
      return;
    }

    emit(resolvedLocale);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, resolvedLocale.languageCode);
      await prefs.setString(_languageSourceKey, _sourceUser);
      await prefs.setBool(_languageUserSelectedKey, true);
    } catch (_) {
      // ignore persistence errors
    }
  }

  @override
  Future<void> close() {
    if (PlatformDispatcher.instance.onLocaleChanged == _handleSystemLocaleChanged) {
      PlatformDispatcher.instance.onLocaleChanged = null;
    }
    return super.close();
  }
}
