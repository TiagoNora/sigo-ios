// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'impact.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ImpactImpl _$$ImpactImplFromJson(Map<String, dynamic> json) => _$ImpactImpl(
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

Map<String, dynamic> _$$ImpactImplToJson(_$ImpactImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'level': instance.level,
      'color': instance.color,
      'translations': instance.translations,
      'enabled': instance.enabled,
    };
