import 'package:freezed_annotation/freezed_annotation.dart';

part 'impact.freezed.dart';
part 'impact.g.dart';

@freezed
class Impact with _$Impact {
  const factory Impact({
    @Default('') String name,
    @Default(0) int level,
    String? color,
    @Default(<String, String>{}) Map<String, String> translations,
    @Default(true) bool enabled,
  }) = _Impact;

  const Impact._();

  factory Impact.fromJson(Map<String, dynamic> json) => _$ImpactFromJson(json);

  String getTranslation(String languageCode) {
    final translation = translations[languageCode];
    if (translation == null || translation.isEmpty) {
      return name;
    }
    return translation;
  }
}
