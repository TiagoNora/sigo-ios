import 'dart:convert';

class TenantConfig {
  final String tenant;
  final String baseUrl;
  final String iamUrl;
  final String serviceId;
  final String servicePassword;

  TenantConfig({
    required this.tenant,
    required this.baseUrl,
    required this.iamUrl,
    required this.serviceId,
    required this.servicePassword,
  });

  factory TenantConfig.fromJson(Map<String, dynamic> json) {
    return TenantConfig(
      tenant: json['tenant'] as String,
      baseUrl: json['baseurl'] as String,
      iamUrl: json['iam_url'] as String,
      serviceId: json['service_id'] as String,
      servicePassword: json['service_password'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant': tenant,
      'baseurl': baseUrl,
      'iam_url': iamUrl,
      'service_id': serviceId,
      'service_password': servicePassword,
    };
  }

  factory TenantConfig.fromQrCode(String qrData) {
    final json = jsonDecode(qrData) as Map<String, dynamic>;
    return TenantConfig.fromJson(json);
  }

  String toQrCode() {
    return jsonEncode(toJson());
  }

  @override
  String toString() => 'TenantConfig(tenant: $tenant, baseUrl: $baseUrl, iamUrl: $iamUrl)';
}
