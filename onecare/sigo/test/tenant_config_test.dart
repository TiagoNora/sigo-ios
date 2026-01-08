import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigo/models/tenant_config.dart';

void main() {
  group('TenantConfig', () {
    group('constructor', () {
      test('creates instance with all required fields', () {
        final config = TenantConfig(
          tenant: 'test-tenant',
          baseUrl: 'https://api.example.com',
          iamUrl: 'https://iam.example.com',
          serviceId: 'service-123',
          servicePassword: 'secret-password',
        );

        expect(config.tenant, 'test-tenant');
        expect(config.baseUrl, 'https://api.example.com');
        expect(config.iamUrl, 'https://iam.example.com');
        expect(config.serviceId, 'service-123');
        expect(config.servicePassword, 'secret-password');
      });
    });

    group('fromJson', () {
      test('creates instance from JSON map', () {
        final json = {
          'tenant': 'OXG',
          'baseurl': 'https://sigo-api.example.com',
          'iam_url': 'https://iam.example.com',
          'service_id': 'onecare-mobile',
          'service_password': 'password123',
        };

        final config = TenantConfig.fromJson(json);

        expect(config.tenant, 'OXG');
        expect(config.baseUrl, 'https://sigo-api.example.com');
        expect(config.iamUrl, 'https://iam.example.com');
        expect(config.serviceId, 'onecare-mobile');
        expect(config.servicePassword, 'password123');
      });

      test('handles different JSON keys correctly', () {
        // Note: 'baseurl' vs 'baseUrl', 'iam_url' vs 'iamUrl', etc.
        final json = {
          'tenant': 'TEST',
          'baseurl': 'http://localhost:8080', // Note: lowercase 'u'
          'iam_url': 'http://localhost:8081', // Note: underscore
          'service_id': 'test-service',
          'service_password': 'test-pass',
        };

        final config = TenantConfig.fromJson(json);

        expect(config.tenant, 'TEST');
        expect(config.baseUrl, 'http://localhost:8080');
        expect(config.iamUrl, 'http://localhost:8081');
        expect(config.serviceId, 'test-service');
        expect(config.servicePassword, 'test-pass');
      });
    });

    group('toJson', () {
      test('converts instance to JSON map', () {
        final config = TenantConfig(
          tenant: 'OXG',
          baseUrl: 'https://sigo-api.example.com',
          iamUrl: 'https://iam.example.com',
          serviceId: 'onecare-mobile',
          servicePassword: 'password123',
        );

        final json = config.toJson();

        expect(json['tenant'], 'OXG');
        expect(json['baseurl'], 'https://sigo-api.example.com');
        expect(json['iam_url'], 'https://iam.example.com');
        expect(json['service_id'], 'onecare-mobile');
        expect(json['service_password'], 'password123');
      });

      test('uses correct JSON keys', () {
        final config = TenantConfig(
          tenant: 'TEST',
          baseUrl: 'http://test',
          iamUrl: 'http://iam',
          serviceId: 'svc',
          servicePassword: 'pwd',
        );

        final json = config.toJson();

        // Verify the exact key names used in serialization
        expect(json.containsKey('baseurl'), true); // lowercase 'u'
        expect(json.containsKey('baseUrl'), false); // camelCase should not exist
        expect(json.containsKey('iam_url'), true); // underscore
        expect(json.containsKey('iamUrl'), false); // camelCase should not exist
      });
    });

    group('fromJson and toJson round-trip', () {
      test('preserves all data through serialization', () {
        final original = TenantConfig(
          tenant: 'OXG',
          baseUrl: 'https://sigo-api.example.com',
          iamUrl: 'https://iam.example.com',
          serviceId: 'onecare-mobile',
          servicePassword: 'password123',
        );

        final json = original.toJson();
        final restored = TenantConfig.fromJson(json);

        expect(restored.tenant, original.tenant);
        expect(restored.baseUrl, original.baseUrl);
        expect(restored.iamUrl, original.iamUrl);
        expect(restored.serviceId, original.serviceId);
        expect(restored.servicePassword, original.servicePassword);
      });
    });

    group('fromQrCode', () {
      test('creates instance from QR code JSON string', () {
        final qrData = json.encode({
          'tenant': 'OXG',
          'baseurl': 'https://sigo-api.example.com',
          'iam_url': 'https://iam.example.com',
          'service_id': 'onecare-mobile',
          'service_password': 'password123',
        });

        final config = TenantConfig.fromQrCode(qrData);

        expect(config.tenant, 'OXG');
        expect(config.baseUrl, 'https://sigo-api.example.com');
        expect(config.iamUrl, 'https://iam.example.com');
        expect(config.serviceId, 'onecare-mobile');
        expect(config.servicePassword, 'password123');
      });

      test('handles compact JSON without whitespace', () {
        final qrData =
            '{"tenant":"TEST","baseurl":"http://api","iam_url":"http://iam","service_id":"svc","service_password":"pwd"}';

        final config = TenantConfig.fromQrCode(qrData);

        expect(config.tenant, 'TEST');
        expect(config.baseUrl, 'http://api');
      });

      test('handles pretty-printed JSON with whitespace', () {
        final qrData = '''
{
  "tenant": "TEST",
  "baseurl": "http://api",
  "iam_url": "http://iam",
  "service_id": "svc",
  "service_password": "pwd"
}
''';

        final config = TenantConfig.fromQrCode(qrData);

        expect(config.tenant, 'TEST');
        expect(config.baseUrl, 'http://api');
      });
    });

    group('toQrCode', () {
      test('converts instance to QR code JSON string', () {
        final config = TenantConfig(
          tenant: 'OXG',
          baseUrl: 'https://sigo-api.example.com',
          iamUrl: 'https://iam.example.com',
          serviceId: 'onecare-mobile',
          servicePassword: 'password123',
        );

        final qrCode = config.toQrCode();
        final decoded = json.decode(qrCode) as Map<String, dynamic>;

        expect(decoded['tenant'], 'OXG');
        expect(decoded['baseurl'], 'https://sigo-api.example.com');
        expect(decoded['iam_url'], 'https://iam.example.com');
        expect(decoded['service_id'], 'onecare-mobile');
        expect(decoded['service_password'], 'password123');
      });

      test('produces valid JSON string', () {
        final config = TenantConfig(
          tenant: 'TEST',
          baseUrl: 'http://test',
          iamUrl: 'http://iam',
          serviceId: 'svc',
          servicePassword: 'pwd',
        );

        final qrCode = config.toQrCode();

        // Should not throw
        expect(() => json.decode(qrCode), returnsNormally);
      });
    });

    group('fromQrCode and toQrCode round-trip', () {
      test('preserves all data through QR code serialization', () {
        final original = TenantConfig(
          tenant: 'OXG',
          baseUrl: 'https://sigo-api.example.com',
          iamUrl: 'https://iam.example.com',
          serviceId: 'onecare-mobile',
          servicePassword: 'password123',
        );

        final qrCode = original.toQrCode();
        final restored = TenantConfig.fromQrCode(qrCode);

        expect(restored.tenant, original.tenant);
        expect(restored.baseUrl, original.baseUrl);
        expect(restored.iamUrl, original.iamUrl);
        expect(restored.serviceId, original.serviceId);
        expect(restored.servicePassword, original.servicePassword);
      });
    });

    group('toString', () {
      test('returns formatted string representation', () {
        final config = TenantConfig(
          tenant: 'OXG',
          baseUrl: 'https://sigo-api.example.com',
          iamUrl: 'https://iam.example.com',
          serviceId: 'onecare-mobile',
          servicePassword: 'password123',
        );

        final str = config.toString();

        expect(str, contains('TenantConfig'));
        expect(str, contains('tenant: OXG'));
        expect(str, contains('baseUrl: https://sigo-api.example.com'));
        expect(str, contains('iamUrl: https://iam.example.com'));
        // Note: servicePassword should NOT be in toString for security
        expect(str, isNot(contains('password123')));
      });
    });
  });
}
