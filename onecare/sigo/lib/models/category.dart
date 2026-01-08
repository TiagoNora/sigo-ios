import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';
part 'category.g.dart';

@freezed
class Category with _$Category {
  const factory Category({
    @Default('') String name,
    @Default(<String, String>{}) Map<String, String> translations,
    @Default(true) bool enabled,
  }) = _Category;

  const Category._();

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);

  String getTranslation(String languageCode) {
    final translation = translations[languageCode];
    if (translation == null || translation.isEmpty) {
      return name;
    }
    return translation;
  }
}
