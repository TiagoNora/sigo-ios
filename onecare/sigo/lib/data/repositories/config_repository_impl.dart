import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/config_repository.dart';
import '../../models/tenant_config.dart';

/// Implementation of ConfigRepository.
///
/// Manages tenant configuration persistence using SharedPreferences.
/// Provides async initialization pattern and reactive updates via streams.
@Singleton(as: ConfigRepository)
class ConfigRepositoryImpl implements ConfigRepository {
  static const String _configKey = 'tenant_config';

  final SharedPreferences _prefs;

  final Completer<void> _initCompleter = Completer<void>();

  final StreamController<TenantConfig?> _configController =
      StreamController<TenantConfig?>.broadcast();

  TenantConfig? _currentConfig;
  bool _isInitializing = true;

  ConfigRepositoryImpl(this._prefs) {
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final configJson = _prefs.getString(_configKey);

      if (configJson != null) {
        final json = jsonDecode(configJson) as Map<String, dynamic>;
        _currentConfig = TenantConfig.fromJson(json);
        debugPrint(
            'ConfigRepository: Loaded config for tenant: ${_currentConfig!.tenant}');
      } else {
        debugPrint('ConfigRepository: No config found, needs QR scan');
      }
    } catch (e) {
      debugPrint('ConfigRepository: Error loading config: $e');
      _currentConfig = null;
    } finally {
      _isInitializing = false;
      _configController.add(_currentConfig);
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
    }
  }

  @override
  Future<bool> saveConfig(TenantConfig config) async {
    try {
      final configJson = jsonEncode(config.toJson());
      await _prefs.setString(_configKey, configJson);

      _currentConfig = config;
      _configController.add(_currentConfig);

      debugPrint('ConfigRepository: Saved config for tenant: ${config.tenant}');
      return true;
    } catch (e) {
      debugPrint('ConfigRepository: Error saving config: $e');
      return false;
    }
  }

  @override
  Future<bool> saveConfigFromQrCode(String qrData) async {
    try {
      final config = TenantConfig.fromQrCode(qrData);
      return await saveConfig(config);
    } catch (e) {
      debugPrint('ConfigRepository: Error parsing QR code: $e');
      return false;
    }
  }

  @override
  Future<void> clearConfig() async {
    try {
      await _prefs.remove(_configKey);

      _currentConfig = null;
      _configController.add(_currentConfig);

      debugPrint('ConfigRepository: Config cleared');
    } catch (e) {
      debugPrint('ConfigRepository: Error clearing config: $e');
    }
  }

  @override
  bool get isConfigured => _currentConfig != null;

  @override
  bool get isInitializing => _isInitializing;

  @override
  TenantConfig? get currentConfig => _currentConfig;

  @override
  Stream<TenantConfig?> get configStream => _configController.stream;

  @override
  Future<void> get ready => _initCompleter.future;

  void dispose() {
    _configController.close();
  }
}
