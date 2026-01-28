import 'package:freezed_annotation/freezed_annotation.dart';

part 'severity.freezed.dart';
part 'severity.g.dart';

@freezed
class Severity with _$Severity {
  const factory Severity({
    @Default('') String name,
    @Default(0) int level,
    String? color,
    @Default(<String, String>{}) Map<String, String> translations,
    @Default(true) bool enabled,
  }) = _Severity;

  const Severity._();

  factory Severity.fromJson(Map<String, dynamic> json) =>
      _$SeverityFromJson(json);

  String getTranslation(String languageCode) {
    final translation = translations[languageCode];
    if (translation == null || translation.isEmpty) {
      return name;
    }
    return translation;
  }
}
