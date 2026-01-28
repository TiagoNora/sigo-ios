/// Base exception class for all application-specific exceptions.
abstract class AppException implements Exception {
  final String message;
  final dynamic originalError;
  final StackTrace? stackTrace;

  AppException({
    required this.message,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => '$runtimeType: $message';
}

/// Exception thrown when authentication fails or token is invalid.
class AuthException extends AppException {
  final String? reason;

  AuthException({
    required super.message,
    this.reason,
    super.originalError,
    super.stackTrace,
  });
}

/// Exception thrown when user input validation fails.
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  ValidationException({
    required super.message,
    this.fieldErrors,
    super.originalError,
    super.stackTrace,
  });
}

/// Exception thrown when server returns an error response.
class ServerException extends AppException {
  final int? statusCode;
  final String? responseBody;

  ServerException({
    required super.message,
    this.statusCode,
    this.responseBody,
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() {
    if (statusCode != null) {
      return 'ServerException (${statusCode}): $message';
    }
    return super.toString();
  }
}
