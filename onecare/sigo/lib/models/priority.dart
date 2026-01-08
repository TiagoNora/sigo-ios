import 'package:freezed_annotation/freezed_annotation.dart';

part 'priority.freezed.dart';
part 'priority.g.dart';

@freezed
class Priority with _$Priority {
  const factory Priority({
    @Default('') String name,
    @Default(0) int level,
    String? color,
    @Default(<String, String>{}) Map<String, String> translations,
    @Default(true) bool enabled,
  }) = _Priority;

  const Priority._();

  factory Priority.fromJson(Map<String, dynamic> json) =>
      _$PriorityFromJson(json);

  String getTranslation(String languageCode) {
    final translation = translations[languageCode];
    if (translation == null || translation.isEmpty) {
      return name;
    }
    return translation;
  }
}
