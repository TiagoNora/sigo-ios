import 'dart:ui';

import 'package:bloc/bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleCubit extends Cubit<Locale> {
  static const String _languageKey = 'app_language';

  LocaleCubit() : super(const Locale('en')) {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageKey);
      if (languageCode != null && languageCode.isNotEmpty) {
        emit(Locale(languageCode));
      }
    } catch (_) {
      // ignore persistence errors
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (state == locale) return;

    emit(locale);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, locale.languageCode);
    } catch (_) {
      // ignore persistence errors
    }
  }
}
