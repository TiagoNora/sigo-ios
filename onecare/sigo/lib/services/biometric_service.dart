import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

@injectable
class BiometricService {
  final SharedPreferences _prefs;
  final LocalAuthentication _localAuth = LocalAuthentication();

  BiometricService(this._prefs);

  // Check if biometric authentication is available on the device
  Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  // Get list of available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  // Authenticate using biometrics
  Future<bool> authenticate({required String reason}) async {
    try {
      return await _localAuth.authenticate(localizedReason: reason);
    } on PlatformException catch (e) {
      debugPrint('Biometric authentication error: $e');
      return false;
    }
  }

  // Check if biometric authentication is enabled in settings
  Future<bool> isBiometricEnabled() async {
    return _prefs.getBool('biometric_enabled') ?? false;
  }

  // Enable/disable biometric authentication
  Future<void> setBiometricEnabled(bool enabled) async {
    await _prefs.setBool('biometric_enabled', enabled);
  }

  // Save credentials for biometric login
  Future<void> saveCredentials(String username, String password) async {
    await _prefs.setString('biometric_username', username);
    await _prefs.setString('biometric_password', password);
  }

  // Get saved credentials
  Future<Map<String, String>?> getCredentials() async {
    final username = _prefs.getString('biometric_username');
    final password = _prefs.getString('biometric_password');

    if (username != null && password != null) {
      return {'username': username, 'password': password};
    }
    return null;
  }

  // Clear saved credentials
  Future<void> clearCredentials() async {
    await _prefs.remove('biometric_username');
    await _prefs.remove('biometric_password');
    await _prefs.remove('biometric_enabled');
  }
}
