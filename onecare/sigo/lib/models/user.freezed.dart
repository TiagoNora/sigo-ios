// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

User _$UserFromJson(Map<String, dynamic> json) {
  return _User.fromJson(json);
}

/// @nodoc
mixin _$User {
  String get username => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String get phone => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseDateTime, toJson: _dateToIso)
  DateTime get creationDate => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseDateTime, toJson: _dateToIso)
  DateTime get lastUpdate => throw _privateConstructorUsedError;
  UserConfig? get config => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  String get href => throw _privateConstructorUsedError;

  /// Serializes this User to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserCopyWith<User> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserCopyWith<$Res> {
  factory $UserCopyWith(User value, $Res Function(User) then) =
      _$UserCopyWithImpl<$Res, User>;
  @useResult
  $Res call({
    String username,
    String name,
    String email,
    String phone,
    @JsonKey(fromJson: _parseDateTime, toJson: _dateToIso)
    DateTime creationDate,
    @JsonKey(fromJson: _parseDateTime, toJson: _dateToIso) DateTime lastUpdate,
    UserConfig? config,
    String type,
    String href,
  });

  $UserConfigCopyWith<$Res>? get config;
}

/// @nodoc
class _$UserCopyWithImpl<$Res, $Val extends User>
    implements $UserCopyWith<$Res> {
  _$UserCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? username = null,
    Object? name = null,
    Object? email = null,
    Object? phone = null,
    Object? creationDate = null,
    Object? lastUpdate = null,
    Object? config = freezed,
    Object? type = null,
    Object? href = null,
  }) {
    return _then(
      _value.copyWith(
            username: null == username
                ? _value.username
                : username // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            email: null == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String,
            phone: null == phone
                ? _value.phone
                : phone // ignore: cast_nullable_to_non_nullable
                      as String,
            creationDate: null == creationDate
                ? _value.creationDate
                : creationDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            lastUpdate: null == lastUpdate
                ? _value.lastUpdate
                : lastUpdate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            config: freezed == config
                ? _value.config
                : config // ignore: cast_nullable_to_non_nullable
                      as UserConfig?,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            href: null == href
                ? _value.href
                : href // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UserConfigCopyWith<$Res>? get config {
    if (_value.config == null) {
      return null;
    }

    return $UserConfigCopyWith<$Res>(_value.config!, (value) {
      return _then(_value.copyWith(config: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$UserImplCopyWith<$Res> implements $UserCopyWith<$Res> {
  factory _$$UserImplCopyWith(
    _$UserImpl value,
    $Res Function(_$UserImpl) then,
  ) = __$$UserImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String username,
    String name,
    String email,
    String phone,
    @JsonKey(fromJson: _parseDateTime, toJson: _dateToIso)
    DateTime creationDate,
    @JsonKey(fromJson: _parseDateTime, toJson: _dateToIso) DateTime lastUpdate,
    UserConfig? config,
    String type,
    String href,
  });

  @override
  $UserConfigCopyWith<$Res>? get config;
}

/// @nodoc
class __$$UserImplCopyWithImpl<$Res>
    extends _$UserCopyWithImpl<$Res, _$UserImpl>
    implements _$$UserImplCopyWith<$Res> {
  __$$UserImplCopyWithImpl(_$UserImpl _value, $Res Function(_$UserImpl) _then)
    : super(_value, _then);

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? username = null,
    Object? name = null,
    Object? email = null,
    Object? phone = null,
    Object? creationDate = null,
    Object? lastUpdate = null,
    Object? config = freezed,
    Object? type = null,
    Object? href = null,
  }) {
    return _then(
      _$UserImpl(
        username: null == username
            ? _value.username
            : username // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        email: null == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String,
        phone: null == phone
            ? _value.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String,
        creationDate: null == creationDate
            ? _value.creationDate
            : creationDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        lastUpdate: null == lastUpdate
            ? _value.lastUpdate
            : lastUpdate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        config: freezed == config
            ? _value.config
            : config // ignore: cast_nullable_to_non_nullable
                  as UserConfig?,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
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
class _$UserImpl implements _User {
  const _$UserImpl({
    this.username = '',
    this.name = '',
    this.email = '',
    this.phone = '',
    @JsonKey(fromJson: _parseDateTime, toJson: _dateToIso)
    required this.creationDate,
    @JsonKey(fromJson: _parseDateTime, toJson: _dateToIso)
    required this.lastUpdate,
    this.config,
    this.type = '',
    this.href = '',
  });

  factory _$UserImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserImplFromJson(json);

  @override
  @JsonKey()
  final String username;
  @override
  @JsonKey()
  final String name;
  @override
  @JsonKey()
  final String email;
  @override
  @JsonKey()
  final String phone;
  @override
  @JsonKey(fromJson: _parseDateTime, toJson: _dateToIso)
  final DateTime creationDate;
  @override
  @JsonKey(fromJson: _parseDateTime, toJson: _dateToIso)
  final DateTime lastUpdate;
  @override
  final UserConfig? config;
  @override
  @JsonKey()
  final String type;
  @override
  @JsonKey()
  final String href;

  @override
  String toString() {
    return 'User(username: $username, name: $name, email: $email, phone: $phone, creationDate: $creationDate, lastUpdate: $lastUpdate, config: $config, type: $type, href: $href)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserImpl &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.creationDate, creationDate) ||
                other.creationDate == creationDate) &&
            (identical(other.lastUpdate, lastUpdate) ||
                other.lastUpdate == lastUpdate) &&
            (identical(other.config, config) || other.config == config) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.href, href) || other.href == href));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    username,
    name,
    email,
    phone,
    creationDate,
    lastUpdate,
    config,
    type,
    href,
  );

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserImplCopyWith<_$UserImpl> get copyWith =>
      __$$UserImplCopyWithImpl<_$UserImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserImplToJson(this);
  }
}

abstract class _User implements User {
  const factory _User({
    final String username,
    final String name,
    final String email,
    final String phone,
    @JsonKey(fromJson: _parseDateTime, toJson: _dateToIso)
    required final DateTime creationDate,
    @JsonKey(fromJson: _parseDateTime, toJson: _dateToIso)
    required final DateTime lastUpdate,
    final UserConfig? config,
    final String type,
    final String href,
  }) = _$UserImpl;

  factory _User.fromJson(Map<String, dynamic> json) = _$UserImpl.fromJson;

  @override
  String get username;
  @override
  String get name;
  @override
  String get email;
  @override
  String get phone;
  @override
  @JsonKey(fromJson: _parseDateTime, toJson: _dateToIso)
  DateTime get creationDate;
  @override
  @JsonKey(fromJson: _parseDateTime, toJson: _dateToIso)
  DateTime get lastUpdate;
  @override
  UserConfig? get config;
  @override
  String get type;
  @override
  String get href;

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserImplCopyWith<_$UserImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserConfig _$UserConfigFromJson(Map<String, dynamic> json) {
  return _UserConfig.fromJson(json);
}

/// @nodoc
mixin _$UserConfig {
  int? get defaultDashboard => throw _privateConstructorUsedError;
  Notifications? get notifications => throw _privateConstructorUsedError;
  OnecarePersonalConfig? get onecarePersonalConfig =>
      throw _privateConstructorUsedError;

  /// Serializes this UserConfig to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserConfigCopyWith<UserConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserConfigCopyWith<$Res> {
  factory $UserConfigCopyWith(
    UserConfig value,
    $Res Function(UserConfig) then,
  ) = _$UserConfigCopyWithImpl<$Res, UserConfig>;
  @useResult
  $Res call({
    int? defaultDashboard,
    Notifications? notifications,
    OnecarePersonalConfig? onecarePersonalConfig,
  });

  $NotificationsCopyWith<$Res>? get notifications;
  $OnecarePersonalConfigCopyWith<$Res>? get onecarePersonalConfig;
}

/// @nodoc
class _$UserConfigCopyWithImpl<$Res, $Val extends UserConfig>
    implements $UserConfigCopyWith<$Res> {
  _$UserConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? defaultDashboard = freezed,
    Object? notifications = freezed,
    Object? onecarePersonalConfig = freezed,
  }) {
    return _then(
      _value.copyWith(
            defaultDashboard: freezed == defaultDashboard
                ? _value.defaultDashboard
                : defaultDashboard // ignore: cast_nullable_to_non_nullable
                      as int?,
            notifications: freezed == notifications
                ? _value.notifications
                : notifications // ignore: cast_nullable_to_non_nullable
                      as Notifications?,
            onecarePersonalConfig: freezed == onecarePersonalConfig
                ? _value.onecarePersonalConfig
                : onecarePersonalConfig // ignore: cast_nullable_to_non_nullable
                      as OnecarePersonalConfig?,
          )
          as $Val,
    );
  }

  /// Create a copy of UserConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $NotificationsCopyWith<$Res>? get notifications {
    if (_value.notifications == null) {
      return null;
    }

    return $NotificationsCopyWith<$Res>(_value.notifications!, (value) {
      return _then(_value.copyWith(notifications: value) as $Val);
    });
  }

  /// Create a copy of UserConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $OnecarePersonalConfigCopyWith<$Res>? get onecarePersonalConfig {
    if (_value.onecarePersonalConfig == null) {
      return null;
    }

    return $OnecarePersonalConfigCopyWith<$Res>(_value.onecarePersonalConfig!, (
      value,
    ) {
      return _then(_value.copyWith(onecarePersonalConfig: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$UserConfigImplCopyWith<$Res>
    implements $UserConfigCopyWith<$Res> {
  factory _$$UserConfigImplCopyWith(
    _$UserConfigImpl value,
    $Res Function(_$UserConfigImpl) then,
  ) = __$$UserConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int? defaultDashboard,
    Notifications? notifications,
    OnecarePersonalConfig? onecarePersonalConfig,
  });

  @override
  $NotificationsCopyWith<$Res>? get notifications;
  @override
  $OnecarePersonalConfigCopyWith<$Res>? get onecarePersonalConfig;
}

/// @nodoc
class __$$UserConfigImplCopyWithImpl<$Res>
    extends _$UserConfigCopyWithImpl<$Res, _$UserConfigImpl>
    implements _$$UserConfigImplCopyWith<$Res> {
  __$$UserConfigImplCopyWithImpl(
    _$UserConfigImpl _value,
    $Res Function(_$UserConfigImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UserConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? defaultDashboard = freezed,
    Object? notifications = freezed,
    Object? onecarePersonalConfig = freezed,
  }) {
    return _then(
      _$UserConfigImpl(
        defaultDashboard: freezed == defaultDashboard
            ? _value.defaultDashboard
            : defaultDashboard // ignore: cast_nullable_to_non_nullable
                  as int?,
        notifications: freezed == notifications
            ? _value.notifications
            : notifications // ignore: cast_nullable_to_non_nullable
                  as Notifications?,
        onecarePersonalConfig: freezed == onecarePersonalConfig
            ? _value.onecarePersonalConfig
            : onecarePersonalConfig // ignore: cast_nullable_to_non_nullable
                  as OnecarePersonalConfig?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UserConfigImpl implements _UserConfig {
  const _$UserConfigImpl({
    this.defaultDashboard,
    this.notifications,
    this.onecarePersonalConfig,
  });

  factory _$UserConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserConfigImplFromJson(json);

  @override
  final int? defaultDashboard;
  @override
  final Notifications? notifications;
  @override
  final OnecarePersonalConfig? onecarePersonalConfig;

  @override
  String toString() {
    return 'UserConfig(defaultDashboard: $defaultDashboard, notifications: $notifications, onecarePersonalConfig: $onecarePersonalConfig)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserConfigImpl &&
            (identical(other.defaultDashboard, defaultDashboard) ||
                other.defaultDashboard == defaultDashboard) &&
            (identical(other.notifications, notifications) ||
                other.notifications == notifications) &&
            (identical(other.onecarePersonalConfig, onecarePersonalConfig) ||
                other.onecarePersonalConfig == onecarePersonalConfig));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    defaultDashboard,
    notifications,
    onecarePersonalConfig,
  );

  /// Create a copy of UserConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserConfigImplCopyWith<_$UserConfigImpl> get copyWith =>
      __$$UserConfigImplCopyWithImpl<_$UserConfigImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserConfigImplToJson(this);
  }
}

abstract class _UserConfig implements UserConfig {
  const factory _UserConfig({
    final int? defaultDashboard,
    final Notifications? notifications,
    final OnecarePersonalConfig? onecarePersonalConfig,
  }) = _$UserConfigImpl;

  factory _UserConfig.fromJson(Map<String, dynamic> json) =
      _$UserConfigImpl.fromJson;

  @override
  int? get defaultDashboard;
  @override
  Notifications? get notifications;
  @override
  OnecarePersonalConfig? get onecarePersonalConfig;

  /// Create a copy of UserConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserConfigImplCopyWith<_$UserConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Notifications _$NotificationsFromJson(Map<String, dynamic> json) {
  return _Notifications.fromJson(json);
}

/// @nodoc
mixin _$Notifications {
  WatcherNotifications? get watcher => throw _privateConstructorUsedError;

  /// Serializes this Notifications to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Notifications
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NotificationsCopyWith<Notifications> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NotificationsCopyWith<$Res> {
  factory $NotificationsCopyWith(
    Notifications value,
    $Res Function(Notifications) then,
  ) = _$NotificationsCopyWithImpl<$Res, Notifications>;
  @useResult
  $Res call({WatcherNotifications? watcher});

  $WatcherNotificationsCopyWith<$Res>? get watcher;
}

/// @nodoc
class _$NotificationsCopyWithImpl<$Res, $Val extends Notifications>
    implements $NotificationsCopyWith<$Res> {
  _$NotificationsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Notifications
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? watcher = freezed}) {
    return _then(
      _value.copyWith(
            watcher: freezed == watcher
                ? _value.watcher
                : watcher // ignore: cast_nullable_to_non_nullable
                      as WatcherNotifications?,
          )
          as $Val,
    );
  }

  /// Create a copy of Notifications
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $WatcherNotificationsCopyWith<$Res>? get watcher {
    if (_value.watcher == null) {
      return null;
    }

    return $WatcherNotificationsCopyWith<$Res>(_value.watcher!, (value) {
      return _then(_value.copyWith(watcher: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$NotificationsImplCopyWith<$Res>
    implements $NotificationsCopyWith<$Res> {
  factory _$$NotificationsImplCopyWith(
    _$NotificationsImpl value,
    $Res Function(_$NotificationsImpl) then,
  ) = __$$NotificationsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({WatcherNotifications? watcher});

  @override
  $WatcherNotificationsCopyWith<$Res>? get watcher;
}

/// @nodoc
class __$$NotificationsImplCopyWithImpl<$Res>
    extends _$NotificationsCopyWithImpl<$Res, _$NotificationsImpl>
    implements _$$NotificationsImplCopyWith<$Res> {
  __$$NotificationsImplCopyWithImpl(
    _$NotificationsImpl _value,
    $Res Function(_$NotificationsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Notifications
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? watcher = freezed}) {
    return _then(
      _$NotificationsImpl(
        watcher: freezed == watcher
            ? _value.watcher
            : watcher // ignore: cast_nullable_to_non_nullable
                  as WatcherNotifications?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$NotificationsImpl implements _Notifications {
  const _$NotificationsImpl({this.watcher});

  factory _$NotificationsImpl.fromJson(Map<String, dynamic> json) =>
      _$$NotificationsImplFromJson(json);

  @override
  final WatcherNotifications? watcher;

  @override
  String toString() {
    return 'Notifications(watcher: $watcher)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NotificationsImpl &&
            (identical(other.watcher, watcher) || other.watcher == watcher));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, watcher);

  /// Create a copy of Notifications
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NotificationsImplCopyWith<_$NotificationsImpl> get copyWith =>
      __$$NotificationsImplCopyWithImpl<_$NotificationsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NotificationsImplToJson(this);
  }
}

abstract class _Notifications implements Notifications {
  const factory _Notifications({final WatcherNotifications? watcher}) =
      _$NotificationsImpl;

  factory _Notifications.fromJson(Map<String, dynamic> json) =
      _$NotificationsImpl.fromJson;

  @override
  WatcherNotifications? get watcher;

  /// Create a copy of Notifications
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NotificationsImplCopyWith<_$NotificationsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

WatcherNotifications _$WatcherNotificationsFromJson(Map<String, dynamic> json) {
  return _WatcherNotifications.fromJson(json);
}

/// @nodoc
mixin _$WatcherNotifications {
  bool get email => throw _privateConstructorUsedError;
  bool get sms => throw _privateConstructorUsedError;

  /// Serializes this WatcherNotifications to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WatcherNotifications
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WatcherNotificationsCopyWith<WatcherNotifications> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WatcherNotificationsCopyWith<$Res> {
  factory $WatcherNotificationsCopyWith(
    WatcherNotifications value,
    $Res Function(WatcherNotifications) then,
  ) = _$WatcherNotificationsCopyWithImpl<$Res, WatcherNotifications>;
  @useResult
  $Res call({bool email, bool sms});
}

/// @nodoc
class _$WatcherNotificationsCopyWithImpl<
  $Res,
  $Val extends WatcherNotifications
>
    implements $WatcherNotificationsCopyWith<$Res> {
  _$WatcherNotificationsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WatcherNotifications
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? email = null, Object? sms = null}) {
    return _then(
      _value.copyWith(
            email: null == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as bool,
            sms: null == sms
                ? _value.sms
                : sms // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$WatcherNotificationsImplCopyWith<$Res>
    implements $WatcherNotificationsCopyWith<$Res> {
  factory _$$WatcherNotificationsImplCopyWith(
    _$WatcherNotificationsImpl value,
    $Res Function(_$WatcherNotificationsImpl) then,
  ) = __$$WatcherNotificationsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool email, bool sms});
}

/// @nodoc
class __$$WatcherNotificationsImplCopyWithImpl<$Res>
    extends _$WatcherNotificationsCopyWithImpl<$Res, _$WatcherNotificationsImpl>
    implements _$$WatcherNotificationsImplCopyWith<$Res> {
  __$$WatcherNotificationsImplCopyWithImpl(
    _$WatcherNotificationsImpl _value,
    $Res Function(_$WatcherNotificationsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of WatcherNotifications
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? email = null, Object? sms = null}) {
    return _then(
      _$WatcherNotificationsImpl(
        email: null == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as bool,
        sms: null == sms
            ? _value.sms
            : sms // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$WatcherNotificationsImpl implements _WatcherNotifications {
  const _$WatcherNotificationsImpl({this.email = false, this.sms = false});

  factory _$WatcherNotificationsImpl.fromJson(Map<String, dynamic> json) =>
      _$$WatcherNotificationsImplFromJson(json);

  @override
  @JsonKey()
  final bool email;
  @override
  @JsonKey()
  final bool sms;

  @override
  String toString() {
    return 'WatcherNotifications(email: $email, sms: $sms)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WatcherNotificationsImpl &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.sms, sms) || other.sms == sms));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, email, sms);

  /// Create a copy of WatcherNotifications
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WatcherNotificationsImplCopyWith<_$WatcherNotificationsImpl>
  get copyWith =>
      __$$WatcherNotificationsImplCopyWithImpl<_$WatcherNotificationsImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$WatcherNotificationsImplToJson(this);
  }
}

abstract class _WatcherNotifications implements WatcherNotifications {
  const factory _WatcherNotifications({final bool email, final bool sms}) =
      _$WatcherNotificationsImpl;

  factory _WatcherNotifications.fromJson(Map<String, dynamic> json) =
      _$WatcherNotificationsImpl.fromJson;

  @override
  bool get email;
  @override
  bool get sms;

  /// Create a copy of WatcherNotifications
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WatcherNotificationsImplCopyWith<_$WatcherNotificationsImpl>
  get copyWith => throw _privateConstructorUsedError;
}

OnecarePersonalConfig _$OnecarePersonalConfigFromJson(
  Map<String, dynamic> json,
) {
  return _OnecarePersonalConfig.fromJson(json);
}

/// @nodoc
mixin _$OnecarePersonalConfig {
  String? get defaultTeam => throw _privateConstructorUsedError;
  int? get onecareView => throw _privateConstructorUsedError;

  /// Serializes this OnecarePersonalConfig to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OnecarePersonalConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OnecarePersonalConfigCopyWith<OnecarePersonalConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OnecarePersonalConfigCopyWith<$Res> {
  factory $OnecarePersonalConfigCopyWith(
    OnecarePersonalConfig value,
    $Res Function(OnecarePersonalConfig) then,
  ) = _$OnecarePersonalConfigCopyWithImpl<$Res, OnecarePersonalConfig>;
  @useResult
  $Res call({String? defaultTeam, int? onecareView});
}

/// @nodoc
class _$OnecarePersonalConfigCopyWithImpl<
  $Res,
  $Val extends OnecarePersonalConfig
>
    implements $OnecarePersonalConfigCopyWith<$Res> {
  _$OnecarePersonalConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OnecarePersonalConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? defaultTeam = freezed, Object? onecareView = freezed}) {
    return _then(
      _value.copyWith(
            defaultTeam: freezed == defaultTeam
                ? _value.defaultTeam
                : defaultTeam // ignore: cast_nullable_to_non_nullable
                      as String?,
            onecareView: freezed == onecareView
                ? _value.onecareView
                : onecareView // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$OnecarePersonalConfigImplCopyWith<$Res>
    implements $OnecarePersonalConfigCopyWith<$Res> {
  factory _$$OnecarePersonalConfigImplCopyWith(
    _$OnecarePersonalConfigImpl value,
    $Res Function(_$OnecarePersonalConfigImpl) then,
  ) = __$$OnecarePersonalConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String? defaultTeam, int? onecareView});
}

/// @nodoc
class __$$OnecarePersonalConfigImplCopyWithImpl<$Res>
    extends
        _$OnecarePersonalConfigCopyWithImpl<$Res, _$OnecarePersonalConfigImpl>
    implements _$$OnecarePersonalConfigImplCopyWith<$Res> {
  __$$OnecarePersonalConfigImplCopyWithImpl(
    _$OnecarePersonalConfigImpl _value,
    $Res Function(_$OnecarePersonalConfigImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OnecarePersonalConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? defaultTeam = freezed, Object? onecareView = freezed}) {
    return _then(
      _$OnecarePersonalConfigImpl(
        defaultTeam: freezed == defaultTeam
            ? _value.defaultTeam
            : defaultTeam // ignore: cast_nullable_to_non_nullable
                  as String?,
        onecareView: freezed == onecareView
            ? _value.onecareView
            : onecareView // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$OnecarePersonalConfigImpl implements _OnecarePersonalConfig {
  const _$OnecarePersonalConfigImpl({this.defaultTeam, this.onecareView});

  factory _$OnecarePersonalConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$OnecarePersonalConfigImplFromJson(json);

  @override
  final String? defaultTeam;
  @override
  final int? onecareView;

  @override
  String toString() {
    return 'OnecarePersonalConfig(defaultTeam: $defaultTeam, onecareView: $onecareView)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OnecarePersonalConfigImpl &&
            (identical(other.defaultTeam, defaultTeam) ||
                other.defaultTeam == defaultTeam) &&
            (identical(other.onecareView, onecareView) ||
                other.onecareView == onecareView));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, defaultTeam, onecareView);

  /// Create a copy of OnecarePersonalConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OnecarePersonalConfigImplCopyWith<_$OnecarePersonalConfigImpl>
  get copyWith =>
      __$$OnecarePersonalConfigImplCopyWithImpl<_$OnecarePersonalConfigImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$OnecarePersonalConfigImplToJson(this);
  }
}

abstract class _OnecarePersonalConfig implements OnecarePersonalConfig {
  const factory _OnecarePersonalConfig({
    final String? defaultTeam,
    final int? onecareView,
  }) = _$OnecarePersonalConfigImpl;

  factory _OnecarePersonalConfig.fromJson(Map<String, dynamic> json) =
      _$OnecarePersonalConfigImpl.fromJson;

  @override
  String? get defaultTeam;
  @override
  int? get onecareView;

  /// Create a copy of OnecarePersonalConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OnecarePersonalConfigImplCopyWith<_$OnecarePersonalConfigImpl>
  get copyWith => throw _privateConstructorUsedError;
}
