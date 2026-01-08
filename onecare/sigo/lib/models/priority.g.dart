// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'priority.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PriorityImpl _$$PriorityImplFromJson(Map<String, dynamic> json) =>
    _$PriorityImpl(
      name: json['name'] as String? ?? '',
      level: (json['level'] as num?)?.toInt() ?? 0,
      color: json['color'] as String?,
      translations:
          (json['translations'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const <String, String>{},
      enabled: json['enabled'] as bool? ?? true,
    );

Map<String, dynamic> _$$PriorityImplToJson(_$PriorityImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'level': instance.level,
      'color': instance.color,
      'translations': instance.translations,
      'enabled': instance.enabled,
    };
