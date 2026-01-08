// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'saved_filter.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

SavedFilter _$SavedFilterFromJson(Map<String, dynamic> json) {
  return _SavedFilter.fromJson(json);
}

/// @nodoc
mixin _$SavedFilter {
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get owner => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String get lastUpdatedBy => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseDateTime, toJson: _dateToIso)
  DateTime get lastUpdate => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseDateTime, toJson: _dateToIso)
  DateTime get creationDate => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  String get visibility => throw _privateConstructorUsedError;
  FilterConfig get config => throw _privateConstructorUsedError;
  String get href => throw _privateConstructorUsedError;

  /// Serializes this SavedFilter to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SavedFilter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SavedFilterCopyWith<SavedFilter> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SavedFilterCopyWith<$Res> {
  factory $SavedFilterCopyWith(
    SavedFilter value,
    $Res Function(SavedFilter) then,
  ) = _$SavedFilterCopyWithImpl<$Res, SavedFilter>;
  @useResult
  $Res call({
    int id,
    String name,
    String owner,
    String? description,
    String lastUpdatedBy,
    @JsonKey(fromJson: _parseDateTime, toJson: _dateToIso) DateTime lastUpdate,
    @JsonKey(fromJson: _parseDateTime, toJson: _dateToIso)
    DateTime creationDate,
    String type,
    String visibility,
    FilterConfig config,
    String href,
  });

  $FilterConfigCopyWith<$Res> get config;
}

/// @nodoc
class _$SavedFilterCopyWithImpl<$Res, $Val extends SavedFilter>
    implements $SavedFilterCopyWith<$Res> {
  _$SavedFilterCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SavedFilter
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? owner = null,
    Object? description = freezed,
    Object? lastUpdatedBy = null,
    Object? lastUpdate = null,
    Object? creationDate = null,
    Object? type = null,
    Object? visibility = null,
    Object? config = null,
    Object? href = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            owner: null == owner
                ? _value.owner
                : owner // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            lastUpdatedBy: null == lastUpdatedBy
                ? _value.lastUpdatedBy
                : lastUpdatedBy // ignore: cast_nullable_to_non_nullable
                      as String,
            lastUpdate: null == lastUpdate
                ? _value.lastUpdate
                : lastUpdate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            creationDate: null == creationDate
                ? _value.creationDate
                : creationDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            visibility: null == visibility
                ? _value.visibility
                : visibility // ignore: cast_nullable_to_non_nullable
                      as String,
            config: null == config
                ? _value.config
                : config // ignore: cast_nullable_to_non_nullable
                      as FilterConfig,
            href: null == href
                ? _value.href
                : href // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }

  /// Create a copy of SavedFilter
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $FilterConfigCopyWith<$Res> get config {
    return $FilterConfigCopyWith<$Res>(_value.config, (value) {
      return _then(_value.copyWith(config: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SavedFilterImplCopyWith<$Res>
    implements $SavedFilterCopyWith<$Res> {
  factory _$$SavedFilterImplCopyWith(
    _$SavedFilterImpl value,
    $Res Function(_$SavedFilterImpl) then,
  ) = __$$SavedFilterImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    String name,
    String owner,
    String? description,
    String lastUpdatedBy,
    @JsonKey(fromJson: _parseDateTime, toJson: _dateToIso) DateTime lastUpdate,
    @JsonKey(fromJson: _parseDateTime, toJson: _dateToIso)
    DateTime creationDate,
    String type,
    String visibility,
    FilterConfig config,
    String href,
  });

  @override
  $FilterConfigCopyWith<$Res> get config;
}

/// @nodoc
class __$$SavedFilterImplCopyWithImpl<$Res>
    extends _$SavedFilterCopyWithImpl<$Res, _$SavedFilterImpl>
    implements _$$SavedFilterImplCopyWith<$Res> {
  __$$SavedFilterImplCopyWithImpl(
    _$SavedFilterImpl _value,
    $Res Function(_$SavedFilterImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SavedFilter
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? owner = null,
    Object? description = freezed,
    Object? lastUpdatedBy = null,
    Object? lastUpdate = null,
    Object? creationDate = null,
    Object? type = null,
    Object? visibility = null,
    Object? config = null,
    Object? href = null,
  }) {
    return _then(
      _$SavedFilterImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        owner: null == owner
            ? _value.owner
            : owner // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        lastUpdatedBy: null == lastUpdatedBy
            ? _value.lastUpdatedBy
            : lastUpdatedBy // ignore: cast_nullable_to_non_nullable
                  as String,
        lastUpdate: null == lastUpdate
            ? _value.lastUpdate
            : lastUpdate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        creationDate: null == creationDate
            ? _value.creationDate
            : creationDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        visibility: null == visibility
            ? _value.visibility
            : visibility // ignore: cast_nullable_to_non_nullable
                  as String,
        config: null == config
            ? _value.config
            : config // ignore: cast_nullable_to_non_nullable
                  as FilterConfig,
        href: null == href
            ? _value.href
            : href // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SavedFilterImpl implements _SavedFilter {
  const _$SavedFilterImpl({
    required this.id,
    required this.name,
    required this.owner,
    this.description,
    required this.lastUpdatedBy,
    @JsonKey(fromJson: _parseDateTime, toJson: _dateToIso)
    required this.lastUpdate,
    @JsonKey(fromJson: _parseDateTime, toJson: _dateToIso)
    required this.creationDate,
    required this.type,
    required this.visibility,
    required this.config,
    required this.href,
  });

  factory _$SavedFilterImpl.fromJson(Map<String, dynamic> json) =>
      _$$SavedFilterImplFromJson(json);

  @override
  final int id;
  @override
  final String name;
  @override
  final String owner;
  @override
  final String? description;
  @override
  final String lastUpdatedBy;
  @override
  @JsonKey(fromJson: _parseDateTime, toJson: _dateToIso)
  final DateTime lastUpdate;
  @override
  @JsonKey(fromJson: _parseDateTime, toJson: _dateToIso)
  final DateTime creationDate;
  @override
  final String type;
  @override
  final String visibility;
  @override
  final FilterConfig config;
  @override
  final String href;

  @override
  String toString() {
    return 'SavedFilter(id: $id, name: $name, owner: $owner, description: $description, lastUpdatedBy: $lastUpdatedBy, lastUpdate: $lastUpdate, creationDate: $creationDate, type: $type, visibility: $visibility, config: $config, href: $href)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SavedFilterImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.owner, owner) || other.owner == owner) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.lastUpdatedBy, lastUpdatedBy) ||
                other.lastUpdatedBy == lastUpdatedBy) &&
            (identical(other.lastUpdate, lastUpdate) ||
                other.lastUpdate == lastUpdate) &&
            (identical(other.creationDate, creationDate) ||
                other.creationDate == creationDate) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.visibility, visibility) ||
                other.visibility == visibility) &&
            (identical(other.config, config) || other.config == config) &&
            (identical(other.href, href) || other.href == href));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    owner,
    description,
    lastUpdatedBy,
    lastUpdate,
    creationDate,
    type,
    visibility,
    config,
    href,
  );

  /// Create a copy of SavedFilter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SavedFilterImplCopyWith<_$SavedFilterImpl> get copyWith =>
      __$$SavedFilterImplCopyWithImpl<_$SavedFilterImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SavedFilterImplToJson(this);
  }
}

abstract class _SavedFilter implements SavedFilter {
  const factory _SavedFilter({
    required final int id,
    required final String name,
    required final String owner,
    final String? description,
    required final String lastUpdatedBy,
    @JsonKey(fromJson: _parseDateTime, toJson: _dateToIso)
    required final DateTime lastUpdate,
    @JsonKey(fromJson: _parseDateTime, toJson: _dateToIso)
    required final DateTime creationDate,
    required final String type,
    required final String visibility,
    required final FilterConfig config,
    required final String href,
  }) = _$SavedFilterImpl;

  factory _SavedFilter.fromJson(Map<String, dynamic> json) =
      _$SavedFilterImpl.fromJson;

  @override
  int get id;
  @override
  String get name;
  @override
  String get owner;
  @override
  String? get description;
  @override
  String get lastUpdatedBy;
  @override
  @JsonKey(fromJson: _parseDateTime, toJson: _dateToIso)
  DateTime get lastUpdate;
  @override
  @JsonKey(fromJson: _parseDateTime, toJson: _dateToIso)
  DateTime get creationDate;
  @override
  String get type;
  @override
  String get visibility;
  @override
  FilterConfig get config;
  @override
  String get href;

  /// Create a copy of SavedFilter
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SavedFilterImplCopyWith<_$SavedFilterImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FilterConfig _$FilterConfigFromJson(Map<String, dynamic> json) {
  return _FilterConfig.fromJson(json);
}

/// @nodoc
mixin _$FilterConfig {
  String? get name => throw _privateConstructorUsedError;
  String get operator => throw _privateConstructorUsedError;
  List<FilterCondition> get conditions => throw _privateConstructorUsedError;

  /// Serializes this FilterConfig to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FilterConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FilterConfigCopyWith<FilterConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FilterConfigCopyWith<$Res> {
  factory $FilterConfigCopyWith(
    FilterConfig value,
    $Res Function(FilterConfig) then,
  ) = _$FilterConfigCopyWithImpl<$Res, FilterConfig>;
  @useResult
  $Res call({String? name, String operator, List<FilterCondition> conditions});
}

/// @nodoc
class _$FilterConfigCopyWithImpl<$Res, $Val extends FilterConfig>
    implements $FilterConfigCopyWith<$Res> {
  _$FilterConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FilterConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = freezed,
    Object? operator = null,
    Object? conditions = null,
  }) {
    return _then(
      _value.copyWith(
            name: freezed == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String?,
            operator: null == operator
                ? _value.operator
                : operator // ignore: cast_nullable_to_non_nullable
                      as String,
            conditions: null == conditions
                ? _value.conditions
                : conditions // ignore: cast_nullable_to_non_nullable
                      as List<FilterCondition>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FilterConfigImplCopyWith<$Res>
    implements $FilterConfigCopyWith<$Res> {
  factory _$$FilterConfigImplCopyWith(
    _$FilterConfigImpl value,
    $Res Function(_$FilterConfigImpl) then,
  ) = __$$FilterConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String? name, String operator, List<FilterCondition> conditions});
}

/// @nodoc
class __$$FilterConfigImplCopyWithImpl<$Res>
    extends _$FilterConfigCopyWithImpl<$Res, _$FilterConfigImpl>
    implements _$$FilterConfigImplCopyWith<$Res> {
  __$$FilterConfigImplCopyWithImpl(
    _$FilterConfigImpl _value,
    $Res Function(_$FilterConfigImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FilterConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = freezed,
    Object? operator = null,
    Object? conditions = null,
  }) {
    return _then(
      _$FilterConfigImpl(
        name: freezed == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String?,
        operator: null == operator
            ? _value.operator
            : operator // ignore: cast_nullable_to_non_nullable
                  as String,
        conditions: null == conditions
            ? _value._conditions
            : conditions // ignore: cast_nullable_to_non_nullable
                  as List<FilterCondition>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$FilterConfigImpl implements _FilterConfig {
  const _$FilterConfigImpl({
    this.name,
    required this.operator,
    final List<FilterCondition> conditions = const <FilterCondition>[],
  }) : _conditions = conditions;

  factory _$FilterConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$FilterConfigImplFromJson(json);

  @override
  final String? name;
  @override
  final String operator;
  final List<FilterCondition> _conditions;
  @override
  @JsonKey()
  List<FilterCondition> get conditions {
    if (_conditions is EqualUnmodifiableListView) return _conditions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_conditions);
  }

  @override
  String toString() {
    return 'FilterConfig(name: $name, operator: $operator, conditions: $conditions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FilterConfigImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.operator, operator) ||
                other.operator == operator) &&
            const DeepCollectionEquality().equals(
              other._conditions,
              _conditions,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    name,
    operator,
    const DeepCollectionEquality().hash(_conditions),
  );

  /// Create a copy of FilterConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FilterConfigImplCopyWith<_$FilterConfigImpl> get copyWith =>
      __$$FilterConfigImplCopyWithImpl<_$FilterConfigImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FilterConfigImplToJson(this);
  }
}

abstract class _FilterConfig implements FilterConfig {
  const factory _FilterConfig({
    final String? name,
    required final String operator,
    final List<FilterCondition> conditions,
  }) = _$FilterConfigImpl;

  factory _FilterConfig.fromJson(Map<String, dynamic> json) =
      _$FilterConfigImpl.fromJson;

  @override
  String? get name;
  @override
  String get operator;
  @override
  List<FilterCondition> get conditions;

  /// Create a copy of FilterConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FilterConfigImplCopyWith<_$FilterConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FilterCondition _$FilterConditionFromJson(Map<String, dynamic> json) {
  return _FilterCondition.fromJson(json);
}

/// @nodoc
mixin _$FilterCondition {
  Object? get value => throw _privateConstructorUsedError;
  String get operator => throw _privateConstructorUsedError;
  String get attribute => throw _privateConstructorUsedError;

  /// Serializes this FilterCondition to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FilterCondition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FilterConditionCopyWith<FilterCondition> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FilterConditionCopyWith<$Res> {
  factory $FilterConditionCopyWith(
    FilterCondition value,
    $Res Function(FilterCondition) then,
  ) = _$FilterConditionCopyWithImpl<$Res, FilterCondition>;
  @useResult
  $Res call({Object? value, String operator, String attribute});
}

/// @nodoc
class _$FilterConditionCopyWithImpl<$Res, $Val extends FilterCondition>
    implements $FilterConditionCopyWith<$Res> {
  _$FilterConditionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FilterCondition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? value = freezed,
    Object? operator = null,
    Object? attribute = null,
  }) {
    return _then(
      _value.copyWith(
            value: freezed == value ? _value.value : value,
            operator: null == operator
                ? _value.operator
                : operator // ignore: cast_nullable_to_non_nullable
                      as String,
            attribute: null == attribute
                ? _value.attribute
                : attribute // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FilterConditionImplCopyWith<$Res>
    implements $FilterConditionCopyWith<$Res> {
  factory _$$FilterConditionImplCopyWith(
    _$FilterConditionImpl value,
    $Res Function(_$FilterConditionImpl) then,
  ) = __$$FilterConditionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Object? value, String operator, String attribute});
}

/// @nodoc
class __$$FilterConditionImplCopyWithImpl<$Res>
    extends _$FilterConditionCopyWithImpl<$Res, _$FilterConditionImpl>
    implements _$$FilterConditionImplCopyWith<$Res> {
  __$$FilterConditionImplCopyWithImpl(
    _$FilterConditionImpl _value,
    $Res Function(_$FilterConditionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FilterCondition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? value = freezed,
    Object? operator = null,
    Object? attribute = null,
  }) {
    return _then(
      _$FilterConditionImpl(
        value: freezed == value ? _value.value : value,
        operator: null == operator
            ? _value.operator
            : operator // ignore: cast_nullable_to_non_nullable
                  as String,
        attribute: null == attribute
            ? _value.attribute
            : attribute // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$FilterConditionImpl implements _FilterCondition {
  const _$FilterConditionImpl({
    this.value,
    required this.operator,
    required this.attribute,
  });

  factory _$FilterConditionImpl.fromJson(Map<String, dynamic> json) =>
      _$$FilterConditionImplFromJson(json);

  @override
  final Object? value;
  @override
  final String operator;
  @override
  final String attribute;

  @override
  String toString() {
    return 'FilterCondition(value: $value, operator: $operator, attribute: $attribute)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FilterConditionImpl &&
            const DeepCollectionEquality().equals(other.value, value) &&
            (identical(other.operator, operator) ||
                other.operator == operator) &&
            (identical(other.attribute, attribute) ||
                other.attribute == attribute));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(value),
    operator,
    attribute,
  );

  /// Create a copy of FilterCondition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FilterConditionImplCopyWith<_$FilterConditionImpl> get copyWith =>
      __$$FilterConditionImplCopyWithImpl<_$FilterConditionImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$FilterConditionImplToJson(this);
  }
}

abstract class _FilterCondition implements FilterCondition {
  const factory _FilterCondition({
    final Object? value,
    required final String operator,
    required final String attribute,
  }) = _$FilterConditionImpl;

  factory _FilterCondition.fromJson(Map<String, dynamic> json) =
      _$FilterConditionImpl.fromJson;

  @override
  Object? get value;
  @override
  String get operator;
  @override
  String get attribute;

  /// Create a copy of FilterCondition
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FilterConditionImplCopyWith<_$FilterConditionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
