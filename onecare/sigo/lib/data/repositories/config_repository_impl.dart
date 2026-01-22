import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

import '../../config/app_features.dart';
import '../../core/di/injection.dart';
import '../../domain/repositories/config_repository.dart';
import '../../models/tenant_config.dart';
import '../../services/notification_service.dart';

/// Implementation of ConfigRepository with encrypted QR code support.
///
/// Manages tenant configuration persistence using FlutterSecureStorage.
/// Fetches decryption key from Firestore and decrypts QR code data.
@Singleton(as: ConfigRepository)
class ConfigRepositoryImpl implements ConfigRepository {
  static const String _configKey = 'tenant_config';
  static const String _encryptionKeyKey = 'qr_encryption_key';
  static const int _ivLength = 12; // 96 bits for GCM

  // Firestore paths for encryption key
  static const String _firestoreCollection = 'config';
  static const String _firestoreDocument = 'encryption';
  static const String _firestoreKeyField = 'qr_key';

  final FlutterSecureStorage _secureStorage;
  final FirebaseFirestore _firestore;

  final Completer<void> _initCompleter = Completer<void>();

  final StreamController<TenantConfig?> _configController =
      StreamController<TenantConfig?>.broadcast();

  TenantConfig? _currentConfig;
  bool _isInitializing = true;
  String? _cachedEncryptionKey;

  ConfigRepositoryImpl(
    this._secureStorage,
    this._firestore,
  ) {
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final configJson = await _secureStorage.read(key: _configKey);

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

  /// Ensures subscription to tenant FCM topic if config exists.
  /// Call this after NotificationService is initialized.
  Future<void> ensureTopicSubscription() async {
    if (_currentConfig == null || !AppFeatures.enableNotifications) return;

    try {
      final notificationService = getIt<NotificationService>();
      await notificationService.subscribeToTenantTopic(
        tenant: _currentConfig!.tenant,
        isDev: _currentConfig!.isDev,
      );
    } catch (e) {
      debugPrint('ConfigRepository: Failed to ensure topic subscription: $e');
    }
  }

  // ============================================
  // Encryption Key Management
  // ============================================

  /// Fetches the encryption key from Firestore (caches locally).
  Future<String?> _getEncryptionKey() async {
    // Return from memory cache
    if (_cachedEncryptionKey != null) {
      return _cachedEncryptionKey;
    }

    // Try secure storage first
    try {
      final storedKey = await _secureStorage.read(key: _encryptionKeyKey);
      if (storedKey != null && storedKey.isNotEmpty) {
        _cachedEncryptionKey = storedKey;
        debugPrint('ConfigRepository: Encryption key loaded from secure storage');
        return _cachedEncryptionKey;
      }
    } catch (e) {
      debugPrint('ConfigRepository: Error reading encryption key from storage: $e');
    }

    // Fetch from Firestore
    try {
      debugPrint('ConfigRepository: Fetching encryption key from Firestore...');
      final doc = await _firestore
          .collection(_firestoreCollection)
          .doc(_firestoreDocument)
          .get();

      if (doc.exists) {
        final key = doc.data()?[_firestoreKeyField] as String?;
        if (key != null && key.isNotEmpty) {
          // Cache in secure storage
          await _secureStorage.write(key: _encryptionKeyKey, value: key);
          _cachedEncryptionKey = key;
          debugPrint('ConfigRepository: Encryption key fetched from Firestore and cached');
          return _cachedEncryptionKey;
        }
      }
      debugPrint('ConfigRepository: Encryption key not found in Firestore');
    } catch (e) {
      debugPrint('ConfigRepository: Error fetching encryption key from Firestore: $e');
    }

    return null;
  }

  // ============================================
  // QR Code Decryption (AES-256-GCM)
  // ============================================

  /// Decrypts QR code data using AES-256-GCM.
  ///
  /// Expected format: base64(iv[12] + ciphertext + authTag[16])
  /// Returns decrypted JSON string or null if decryption fails.
  String? _decryptQrData(String encryptedBase64, String secretKey) {
    try {
      // Decode base64
      final combined = base64Decode(encryptedBase64);

      if (combined.length < _ivLength + 17) {
        debugPrint('ConfigRepository: Encrypted data too short');
        return null;
      }

      // Extract IV (first 12 bytes)
      final iv = combined.sublist(0, _ivLength);

      // Extract ciphertext + authTag (rest of the data)
      final ciphertextWithTag = combined.sublist(_ivLength);

      // Derive 256-bit key from secret using SHA-256
      final keyBytes = sha256.convert(utf8.encode(secretKey)).bytes;
      final key = encrypt.Key(Uint8List.fromList(keyBytes));

      // Create encrypter with GCM mode
      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.gcm),
      );

      // Decrypt
      final decrypted = encrypter.decryptBytes(
        encrypt.Encrypted(Uint8List.fromList(ciphertextWithTag)),
        iv: encrypt.IV(Uint8List.fromList(iv)),
      );

      return utf8.decode(decrypted);
    } catch (e) {
      debugPrint('ConfigRepository: AES-GCM decrypt error: $e');
      return null;
    }
  }

  // ============================================
  // Config Operations
  // ============================================

  @override
  Future<bool> saveConfig(TenantConfig config) async {
    try {
      final configJson = jsonEncode(config.toJson());
      await _secureStorage.write(key: _configKey, value: configJson);

      _currentConfig = config;
      _configController.add(_currentConfig);

      // Subscribe to tenant FCM topic for general alerts
      if (AppFeatures.enableNotifications) {
        try {
          final notificationService = getIt<NotificationService>();
          await notificationService.subscribeToTenantTopic(
            tenant: config.tenant,
            isDev: config.isDev,
          );
        } catch (e) {
          debugPrint('ConfigRepository: Failed to subscribe to tenant topic: $e');
        }
      }

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
      // Get encryption key from Firestore
      final encryptionKey = await _getEncryptionKey();

      if (encryptionKey == null) {
        debugPrint('ConfigRepository: Encryption key not available');
        throw FormatException('Encryption key not available. Check your network connection.');
      }

      // Decrypt the QR code data
      final decryptedJson = _decryptQrData(qrData, encryptionKey);

      if (decryptedJson == null) {
        debugPrint('ConfigRepository: Failed to decrypt QR code');
        throw FormatException('Failed to decrypt QR code. Invalid or corrupted data.');
      }

      debugPrint('ConfigRepository: Decrypted QR data: $decryptedJson');

      // Parse the decrypted JSON using existing TenantConfig.fromQrCode logic
      final config = TenantConfig.fromQrCode(decryptedJson);
      return await saveConfig(config);
    } on FormatException catch (e) {
      debugPrint('ConfigRepository: Invalid QR code format: $e');
      rethrow;
    } catch (e) {
      debugPrint('ConfigRepository: Error parsing QR code: $e');
      return false;
    }
  }

  @override
  Future<void> clearConfig() async {
    try {
      // Unsubscribe from tenant FCM topic
      if (AppFeatures.enableNotifications) {
        try {
          final notificationService = getIt<NotificationService>();
          await notificationService.unsubscribeFromCurrentTopic();
        } catch (e) {
          debugPrint('ConfigRepository: Failed to unsubscribe from topic: $e');
        }
      }

      await _secureStorage.delete(key: _configKey);

      _currentConfig = null;
      _configController.add(_currentConfig);

      debugPrint('ConfigRepository: Config cleared');
    } catch (e) {
      debugPrint('ConfigRepository: Error clearing config: $e');
    }
  }

  /// Clears all cached data including encryption key (for full reset).
  Future<void> clearAll() async {
    // Unsubscribe from tenant FCM topic
    if (AppFeatures.enableNotifications) {
      try {
        final notificationService = getIt<NotificationService>();
        await notificationService.unsubscribeFromCurrentTopic();
      } catch (e) {
        debugPrint('ConfigRepository: Failed to unsubscribe from topic: $e');
      }
    }

    await _secureStorage.delete(key: _configKey);
    await _secureStorage.delete(key: _encryptionKeyKey);
    _currentConfig = null;
    _cachedEncryptionKey = null;
    _configController.add(_currentConfig);
    debugPrint('ConfigRepository: All data cleared');
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
