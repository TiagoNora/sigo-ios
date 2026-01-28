import 'app_exception.dart';

/// Exception thrown when a network-related error occurs.
///
/// This includes connectivity issues, timeouts, and other network failures.
class NetworkException extends AppException {
  NetworkException({
    required super.message,
    super.originalError,
    super.stackTrace,
  });
}
