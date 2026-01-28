import 'package:freezed_annotation/freezed_annotation.dart';

part 'saved_filter.freezed.dart';
part 'saved_filter.g.dart';

@freezed
class SavedFilter with _$SavedFilter {
  const factory SavedFilter({
    required int id,
    required String name,
    required String owner,
    String? description,
    required String lastUpdatedBy,
    @JsonKey(fromJson: _parseDateTime, toJson: _dateToIso) required DateTime lastUpdate,
    @JsonKey(fromJson: _parseDateTime, toJson: _dateToIso) required DateTime creationDate,
    required String type,
    required String visibility,
    required FilterConfig config,
    required String href,
  }) = _SavedFilter;

  factory SavedFilter.fromJson(Map<String, dynamic> json) =>
      _$SavedFilterFromJson(json);
}

@freezed
class FilterConfig with _$FilterConfig {
  const factory FilterConfig({
    String? name,
    required String operator,
    @Default(<FilterCondition>[]) List<FilterCondition> conditions,
  }) = _FilterConfig;

  factory FilterConfig.fromJson(Map<String, dynamic> json) =>
      _$FilterConfigFromJson(json);
}

@freezed
class FilterCondition with _$FilterCondition {
  const factory FilterCondition({
    Object? value,
    required String operator,
    required String attribute,
  }) = _FilterCondition;

  factory FilterCondition.fromJson(Map<String, dynamic> json) =>
      _$FilterConditionFromJson(json);
}

DateTime _parseDateTime(Object? value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.parse(value);
  }
  return DateTime.now();
}

String _dateToIso(DateTime value) => value.toIso8601String();
