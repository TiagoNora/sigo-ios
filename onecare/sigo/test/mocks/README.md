# Test Mocks Directory

This directory contains mock implementations for testing purposes.

## Structure

- `mock_repositories.dart` - Mock implementations of repository interfaces
- `mock_services.dart` - Mock implementations of service classes
- `mock_blocs.dart` - Mock BLoC implementations for widget testing

## Usage

```dart
import 'package:sigo/test/mocks/mock_repositories.dart';

void main() {
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
  });

  test('should authenticate user', () async {
    // Test implementation
  });
}
```

## Best Practices

1. Use `mockito` or manual mocks for creating test doubles
2. Keep mocks simple and focused on the interface contract
3. Share common mocks across test files to avoid duplication
4. Update mocks when interfaces change
