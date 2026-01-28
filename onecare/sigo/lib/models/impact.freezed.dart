// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'impact.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Impact _$ImpactFromJson(Map<String, dynamic> json) {
  return _Impact.fromJson(json);
}

/// @nodoc
mixin _$Impact {
  String get name => throw _privateConstructorUsedError;
  int get level => throw _privateConstructorUsedError;
  String? get color => throw _privateConstructorUsedError;
  Map<String, String> get translations => throw _privateConstructorUsedError;
  bool get enabled => throw _privateConstructorUsedError;

  /// Serializes this Impact to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Impact
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ImpactCopyWith<Impact> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ImpactCopyWith<$Res> {
  factory $ImpactCopyWith(Impact value, $Res Function(Impact) then) =
      _$ImpactCopyWithImpl<$Res, Impact>;
  @useResult
  $Res call({
    String name,
    int level,
    String? color,
    Map<String, String> translations,
    bool enabled,
  });
}

/// @nodoc
class _$ImpactCopyWithImpl<$Res, $Val extends Impact>
    implements $ImpactCopyWith<$Res> {
  _$ImpactCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Impact
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? level = null,
    Object? color = freezed,
    Object? translations = null,
    Object? enabled = null,
  }) {
    return _then(
      _value.copyWith(
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            level: null == level
                ? _value.level
                : level // ignore: cast_nullable_to_non_nullable
                      as int,
            color: freezed == color
                ? _value.color
                : color // ignore: cast_nullable_to_non_nullable
                      as String?,
            translations: null == translations
                ? _value.translations
                : translations // ignore: cast_nullable_to_non_nullable
                      as Map<String, String>,
            enabled: null == enabled
                ? _value.enabled
                : enabled // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ImpactImplCopyWith<$Res> implements $ImpactCopyWith<$Res> {
  factory _$$ImpactImplCopyWith(
    _$ImpactImpl value,
    $Res Function(_$ImpactImpl) then,
  ) = __$$ImpactImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String name,
    int level,
    String? color,
    Map<String, String> translations,
    bool enabled,
  });
}

/// @nodoc
class __$$ImpactImplCopyWithImpl<$Res>
    extends _$ImpactCopyWithImpl<$Res, _$ImpactImpl>
    implements _$$ImpactImplCopyWith<$Res> {
  __$$ImpactImplCopyWithImpl(
    _$ImpactImpl _value,
    $Res Function(_$ImpactImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Impact
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? level = null,
    Object? color = freezed,
    Object? translations = null,
    Object? enabled = null,
  }) {
    return _then(
      _$ImpactImpl(
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        level: null == level
            ? _value.level
            : level // ignore: cast_nullable_to_non_nullable
                  as int,
        color: freezed == color
            ? _value.color
            : color // ignore: cast_nullable_to_non_nullable
                  as String?,
        translations: null == translations
            ? _value._translations
            : translations // ignore: cast_nullable_to_non_nullable
                  as Map<String, String>,
        enabled: null == enabled
            ? _value.enabled
            : enabled // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ImpactImpl extends _Impact {
  const _$ImpactImpl({
    this.name = '',
    this.level = 0,
    this.color,
    final Map<String, String> translations = const <String, String>{},
    this.enabled = true,
  }) : _translations = translations,
       super._();

  factory _$ImpactImpl.fromJson(Map<String, dynamic> json) =>
      _$$ImpactImplFromJson(json);

  @override
  @JsonKey()
  final String name;
  @override
  @JsonKey()
  final int level;
  @override
  final String? color;
  final Map<String, String> _translations;
  @override
  @JsonKey()
  Map<String, String> get translations {
    if (_translations is EqualUnmodifiableMapView) return _translations;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_translations);
  }

  @override
  @JsonKey()
  final bool enabled;

  @override
  String toString() {
    return 'Impact(name: $name, level: $level, color: $color, translations: $translations, enabled: $enabled)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ImpactImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.level, level) || other.level == level) &&
            (identical(other.color, color) || other.color == color) &&
            const DeepCollectionEquality().equals(
              other._translations,
              _translations,
            ) &&
            (identical(other.enabled, enabled) || other.enabled == enabled));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    name,
    level,
    color,
    const DeepCollectionEquality().hash(_translations),
    enabled,
  );

  /// Create a copy of Impact
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ImpactImplCopyWith<_$ImpactImpl> get copyWith =>
      __$$ImpactImplCopyWithImpl<_$ImpactImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ImpactImplToJson(this);
  }
}

abstract class _Impact extends Impact {
  const factory _Impact({
    final String name,
    final int level,
    final String? color,
    final Map<String, String> translations,
    final bool enabled,
  }) = _$ImpactImpl;
  const _Impact._() : super._();

  factory _Impact.fromJson(Map<String, dynamic> json) = _$ImpactImpl.fromJson;

  @override
  String get name;
  @override
  int get level;
  @override
  String? get color;
  @override
  Map<String, String> get translations;
  @override
  bool get enabled;

  /// Create a copy of Impact
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ImpactImplCopyWith<_$ImpactImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
