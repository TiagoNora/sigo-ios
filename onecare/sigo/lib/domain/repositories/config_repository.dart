import '../../models/tenant_config.dart';

/// Abstract repository for tenant configuration operations.
/// Defines the contract for managing multi-tenant configuration.
abstract class ConfigRepository {
  /// Save a tenant configuration.
  ///
  /// [config] - The tenant configuration to save
  ///
  /// Returns true if save was successful, false otherwise.
  Future<bool> saveConfig(TenantConfig config);

  /// Parse and save a tenant configuration from QR code data.
  ///
  /// [qrData] - The raw QR code data string
  ///
  /// Returns true if save was successful, false otherwise.
  Future<bool> saveConfigFromQrCode(String qrData);

  /// Clear the current tenant configuration.
  Future<void> clearConfig();

  /// Check if a tenant configuration is currently loaded.
  bool get isConfigured;

  /// Check if configuration is still initializing.
  bool get isInitializing;

  /// Get the current tenant configuration.
  TenantConfig? get currentConfig;

  /// Watch for configuration changes.
  ///
  /// Returns a stream that emits the current config when it changes.
  Stream<TenantConfig?> get configStream;

  /// Wait for configuration initialization to complete.
  Future<void> get ready;

  /// Ensures subscription to tenant FCM topic if config exists.
  /// Call this after NotificationService is initialized.
  Future<void> ensureTopicSubscription();
}
