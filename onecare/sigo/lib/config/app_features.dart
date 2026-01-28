/// Centralized feature toggles for the app.
class AppFeatures {
  AppFeatures._();

  /// Gate notifications UI entry points.
  static const bool enableNotifications = true;

  /// Whether the app is running in the 'dev' flavor.
  /// This is determined at runtime based on the package name.
  static bool isDev = false;
}
