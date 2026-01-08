import 'package:freezed_annotation/freezed_annotation.dart';

part 'subcategory.freezed.dart';
part 'subcategory.g.dart';

@freezed
class Subcategory with _$Subcategory {
  const factory Subcategory({
    @Default('') String name,
    @Default(<String, String>{}) Map<String, String> translations,
    @Default(true) bool enabled,
  }) = _Subcategory;

  const Subcategory._();

  factory Subcategory.fromJson(Map<String, dynamic> json) =>
      _$SubcategoryFromJson(json);

  String getTranslation(String languageCode) {
    final translation = translations[languageCode];
    if (translation == null || translation.isEmpty) {
      return name;
    }
    return translation;
  }
}
