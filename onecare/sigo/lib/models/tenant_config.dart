import 'dart:convert';

class TenantConfig {
  final String tenant;
  final String baseUrl;
  final String iamUrl;
  final String serviceId;
  final bool isDev;

  TenantConfig({
    required this.tenant,
    required this.baseUrl,
    required this.iamUrl,
    required this.serviceId,
    this.isDev = false,
  });

  factory TenantConfig.fromJson(Map<String, dynamic> json) {
    // Validate required fields
    final requiredFields = [
      'tenant',
      'baseurl',
      'iam_url',
      'service_id',
    ];

    final missingFields = requiredFields.where((field) => !json.containsKey(field)).toList();
    if (missingFields.isNotEmpty) {
      throw FormatException(
        'Invalid configuration: missing required fields: ${missingFields.join(", ")}',
      );
    }

    return TenantConfig(
      tenant: json['tenant'] as String,
      baseUrl: json['baseurl'] as String,
      iamUrl: json['iam_url'] as String,
      serviceId: json['service_id'] as String,
      isDev: json['dev'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant': tenant,
      'baseurl': baseUrl,
      'iam_url': iamUrl,
      'service_id': serviceId,
      'dev': isDev,
    };
  }

  factory TenantConfig.fromQrCode(String qrData) {
    final json = jsonDecode(qrData) as Map<String, dynamic>;

    // Validate that the QR code contains the "onecare" key
    if (!json.containsKey('onecare')) {
      throw FormatException(
        'Invalid QR code format: missing "onecare" key. '
        'Expected format: {"onecare": {...}}',
      );
    }

    // Extract and validate the "onecare" object
    final onecareData = json['onecare'];
    if (onecareData is! Map<String, dynamic>) {
      throw FormatException(
        'Invalid QR code format: "onecare" must be an object',
      );
    }

    // Validate required root-level fields
    if (!json.containsKey('tenant')) {
      throw FormatException('Invalid QR code format: missing "tenant" field');
    }
    if (!json.containsKey('iam_url')) {
      throw FormatException('Invalid QR code format: missing "iam_url" field');
    }

    // Validate required onecare fields
    if (!onecareData.containsKey('baseurl')) {
      throw FormatException('Invalid QR code format: missing "onecare.baseurl" field');
    }
    if (!onecareData.containsKey('service_id')) {
      throw FormatException('Invalid QR code format: missing "onecare.service_id" field');
    }

    // Merge root-level fields with onecare-specific fields
    final mergedConfig = {
      'tenant': json['tenant'],
      'iam_url': json['iam_url'],
      'dev': json['dev'] ?? false,
      'baseurl': onecareData['baseurl'],
      'service_id': onecareData['service_id'],
    };

    return TenantConfig.fromJson(mergedConfig);
  }

  String toQrCode() {
    return jsonEncode(toJson());
  }

  @override
  String toString() =>
      'TenantConfig(tenant: $tenant, baseUrl: $baseUrl, iamUrl: $iamUrl)';
}
