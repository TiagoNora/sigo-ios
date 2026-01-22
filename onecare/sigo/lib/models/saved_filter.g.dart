// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_filter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SavedFilterImpl _$$SavedFilterImplFromJson(Map<String, dynamic> json) =>
    _$SavedFilterImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      owner: json['owner'] as String,
      description: json['description'] as String?,
      lastUpdatedBy: json['lastUpdatedBy'] as String,
      lastUpdate: _parseDateTime(json['lastUpdate']),
      creationDate: _parseDateTime(json['creationDate']),
      type: json['type'] as String,
      visibility: json['visibility'] as String,
      config: FilterConfig.fromJson(json['config'] as Map<String, dynamic>),
      href: json['href'] as String,
    );

Map<String, dynamic> _$$SavedFilterImplToJson(_$SavedFilterImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'owner': instance.owner,
      'description': instance.description,
      'lastUpdatedBy': instance.lastUpdatedBy,
      'lastUpdate': _dateToIso(instance.lastUpdate),
      'creationDate': _dateToIso(instance.creationDate),
      'type': instance.type,
      'visibility': instance.visibility,
      'config': instance.config,
      'href': instance.href,
    };

_$FilterConfigImpl _$$FilterConfigImplFromJson(Map<String, dynamic> json) =>
    _$FilterConfigImpl(
      name: json['name'] as String?,
      operator: json['operator'] as String,
      conditions:
          (json['conditions'] as List<dynamic>?)
              ?.map((e) => FilterCondition.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <FilterCondition>[],
    );

Map<String, dynamic> _$$FilterConfigImplToJson(_$FilterConfigImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'operator': instance.operator,
      'conditions': instance.conditions,
    };

_$FilterConditionImpl _$$FilterConditionImplFromJson(
  Map<String, dynamic> json,
) => _$FilterConditionImpl(
  value: json['value'],
  operator: json['operator'] as String,
  attribute: json['attribute'] as String,
);

Map<String, dynamic> _$$FilterConditionImplToJson(
  _$FilterConditionImpl instance,
) => <String, dynamic>{
  'value': instance.value,
  'operator': instance.operator,
  'attribute': instance.attribute,
};
