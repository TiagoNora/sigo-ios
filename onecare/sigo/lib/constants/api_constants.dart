/// API-related constants
class ApiConstants {
  ApiConstants._(); // Private constructor to prevent instantiation

  // Pagination
  static const int defaultPageSize = 10;
  static const int maxPageSize = 100;

  // Scroll thresholds
  static const double paginationScrollThreshold = 200.0;

  // Retry configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // Cache configuration
  static const int maxCacheSize = 1000;
  static const Duration cacheExpiration = Duration(hours: 1);
  static const Duration notificationCacheExpiration = Duration(days: 30);

  // Request timeouts (in seconds)
  static const int connectTimeout = 30;
  static const int receiveTimeout = 30;
  static const int sendTimeout = 30;

  // HTTP headers
  static const String contentTypeJson = 'application/json';
  static const String accept = 'application/json';
}
