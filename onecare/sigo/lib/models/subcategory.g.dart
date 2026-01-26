// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subcategory.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SubcategoryImpl _$$SubcategoryImplFromJson(Map<String, dynamic> json) =>
    _$SubcategoryImpl(
      name: json['name'] as String? ?? '',
      translations:
          (json['translations'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const <String, String>{},
      enabled: json['enabled'] as bool? ?? true,
    );

Map<String, dynamic> _$$SubcategoryImplToJson(_$SubcategoryImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'translations': instance.translations,
      'enabled': instance.enabled,
    };
