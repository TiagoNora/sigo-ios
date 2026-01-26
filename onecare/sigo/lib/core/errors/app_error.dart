/// Base class for all application errors.
///
/// This sealed class hierarchy provides typed error handling throughout the app,
/// replacing generic string error messages with structured error types.
sealed class AppError implements Exception {
  final String message;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppError(
    this.message, {
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => message;
}

/// Error occurring during network operations.
class NetworkError extends AppError {
  const NetworkError(
    super.message, {
    super.originalError,
    super.stackTrace,
  });

  factory NetworkError.noConnection() =>
      const NetworkError('No internet connection');

  factory NetworkError.timeout() =>
      const NetworkError('Request timed out');

  factory NetworkError.serverUnreachable() =>
      const NetworkError('Server is unreachable');
}

/// Error occurring during authentication or authorization.
class AuthError extends AppError {
  const AuthError(
    super.message, {
    super.originalError,
    super.stackTrace,
  });

  factory AuthError.unauthorized() =>
      const AuthError('Unauthorized access');

  factory AuthError.tokenExpired() =>
      const AuthError('Authentication token expired');

  factory AuthError.tokenRefreshFailed() =>
      const AuthError('Failed to refresh authentication token');

  factory AuthError.invalidCredentials() =>
      const AuthError('Invalid credentials');

  factory AuthError.sessionExpired() =>
      const AuthError('Session has expired. Please login again.');
}

/// Error occurring during data validation.
class ValidationError extends AppError {
  final Map<String, String> fieldErrors;

  const ValidationError(
    super.message, {
    this.fieldErrors = const {},
    super.originalError,
    super.stackTrace,
  });

  factory ValidationError.requiredField(String fieldName) =>
      ValidationError(
        '$fieldName is required',
        fieldErrors: {fieldName: 'Required field'},
      );

  factory ValidationError.invalidFormat(String fieldName) =>
      ValidationError(
        '$fieldName has invalid format',
        fieldErrors: {fieldName: 'Invalid format'},
      );

  factory ValidationError.multipleFields(Map<String, String> errors) =>
      ValidationError(
        'Multiple validation errors',
        fieldErrors: errors,
      );
}

/// Error occurring when a resource is not found.
class NotFoundError extends AppError {
  final String? resourceType;
  final String? resourceId;

  const NotFoundError(
    super.message, {
    this.resourceType,
    this.resourceId,
    super.originalError,
    super.stackTrace,
  });

  factory NotFoundError.resource(String type, String id) =>
      NotFoundError(
        '$type with ID $id not found',
        resourceType: type,
        resourceId: id,
      );

  factory NotFoundError.ticket(String id) =>
      NotFoundError.resource('Ticket', id);
}

/// Error occurring during server operations.
class ServerError extends AppError {
  final int? statusCode;

  const ServerError(
    super.message, {
    this.statusCode,
    super.originalError,
    super.stackTrace,
  });

  factory ServerError.internal() =>
      const ServerError('Internal server error', statusCode: 500);

  factory ServerError.badRequest() =>
      const ServerError('Bad request', statusCode: 400);

  factory ServerError.forbidden() =>
      const ServerError('Access forbidden', statusCode: 403);

  factory ServerError.withStatus(int status, String message) =>
      ServerError(message, statusCode: status);
}

/// Error occurring during data parsing or serialization.
class DataError extends AppError {
  const DataError(
    super.message, {
    super.originalError,
    super.stackTrace,
  });

  factory DataError.parsingFailed(String dataType) =>
      DataError('Failed to parse $dataType');

  factory DataError.serializationFailed(String dataType) =>
      DataError('Failed to serialize $dataType');

  factory DataError.invalidFormat() =>
      const DataError('Invalid data format');
}

/// Error occurring during file operations.
class FileError extends AppError {
  final String? filePath;

  const FileError(
    super.message, {
    this.filePath,
    super.originalError,
    super.stackTrace,
  });

  factory FileError.uploadFailed(String fileName) =>
      FileError('Failed to upload file', filePath: fileName);

  factory FileError.downloadFailed(String fileName) =>
      FileError('Failed to download file', filePath: fileName);

  factory FileError.invalidType(String fileName) =>
      FileError('Invalid file type', filePath: fileName);

  factory FileError.sizeTooLarge(String fileName, int maxSizeMB) =>
      FileError(
        'File size exceeds limit of ${maxSizeMB}MB',
        filePath: fileName,
      );
}

/// Error occurring during caching operations.
class CacheError extends AppError {
  const CacheError(
    super.message, {
    super.originalError,
    super.stackTrace,
  });

  factory CacheError.readFailed() =>
      const CacheError('Failed to read from cache');

  factory CacheError.writeFailed() =>
      const CacheError('Failed to write to cache');

  factory CacheError.invalidData() =>
      const CacheError('Invalid cached data');
}

/// Unknown or unexpected error.
class UnknownError extends AppError {
  const UnknownError(
    super.message, {
    super.originalError,
    super.stackTrace,
  });

  factory UnknownError.fromException(dynamic error, [StackTrace? stackTrace]) =>
      UnknownError(
        'An unexpected error occurred: ${error.toString()}',
        originalError: error,
        stackTrace: stackTrace,
      );
}
