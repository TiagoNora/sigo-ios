import 'app_exception.dart';

/// Exception thrown when a requested resource is not found (HTTP 404).
class NotFoundException extends AppException {
  final String? resourceType;
  final dynamic resourceId;

  NotFoundException({
    required super.message,
    this.resourceType,
    this.resourceId,
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() {
    if (resourceType != null && resourceId != null) {
      return 'NotFoundException: $resourceType with ID $resourceId not found - $message';
    }
    return super.toString();
  }
}
