/// App-wide duration constants for animations, timeouts, and debouncing
class AppDurations {
  AppDurations._(); // Private constructor to prevent instantiation

  // Animation durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 250);
  static const Duration animationSlow = Duration(milliseconds: 350);
  static const Duration animationVerySlow = Duration(milliseconds: 500);

  // Debounce durations
  static const Duration searchDebounce = Duration(milliseconds: 350);
  static const Duration scrollDebounce = Duration(milliseconds: 300);
  static const Duration inputDebounce = Duration(milliseconds: 500);

  // Timeout durations
  static const Duration apiTimeout = Duration(seconds: 15);
  static const Duration shortTimeout = Duration(seconds: 10);
  static const Duration longTimeout = Duration(seconds: 60);

  // UI feedback durations
  static const Duration snackBarShort = Duration(seconds: 2);
  static const Duration snackBarNormal = Duration(seconds: 4);
  static const Duration snackBarLong = Duration(seconds: 6);

  // Polling/refresh intervals
  static const Duration refreshInterval = Duration(seconds: 30);
  static const Duration backgroundSyncInterval = Duration(minutes: 5);
}
