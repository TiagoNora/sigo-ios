// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserImpl _$$UserImplFromJson(Map<String, dynamic> json) => _$UserImpl(
  username: json['username'] as String? ?? '',
  name: json['name'] as String? ?? '',
  email: json['email'] as String? ?? '',
  phone: json['phone'] as String? ?? '',
  creationDate: _parseDateTime(json['creationDate']),
  lastUpdate: _parseDateTime(json['lastUpdate']),
  config: json['config'] == null
      ? null
      : UserConfig.fromJson(json['config'] as Map<String, dynamic>),
  type: json['type'] as String? ?? '',
  href: json['href'] as String? ?? '',
);

Map<String, dynamic> _$$UserImplToJson(_$UserImpl instance) =>
    <String, dynamic>{
      'username': instance.username,
      'name': instance.name,
      'email': instance.email,
      'phone': instance.phone,
      'creationDate': _dateToIso(instance.creationDate),
      'lastUpdate': _dateToIso(instance.lastUpdate),
      'config': instance.config,
      'type': instance.type,
      'href': instance.href,
    };

_$UserConfigImpl _$$UserConfigImplFromJson(Map<String, dynamic> json) =>
    _$UserConfigImpl(
      defaultDashboard: (json['defaultDashboard'] as num?)?.toInt(),
      notifications: json['notifications'] == null
          ? null
          : Notifications.fromJson(
              json['notifications'] as Map<String, dynamic>,
            ),
      onecarePersonalConfig: json['onecarePersonalConfig'] == null
          ? null
          : OnecarePersonalConfig.fromJson(
              json['onecarePersonalConfig'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$$UserConfigImplToJson(_$UserConfigImpl instance) =>
    <String, dynamic>{
      'defaultDashboard': instance.defaultDashboard,
      'notifications': instance.notifications,
      'onecarePersonalConfig': instance.onecarePersonalConfig,
    };

_$NotificationsImpl _$$NotificationsImplFromJson(Map<String, dynamic> json) =>
    _$NotificationsImpl(
      watcher: json['watcher'] == null
          ? null
          : WatcherNotifications.fromJson(
              json['watcher'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$$NotificationsImplToJson(_$NotificationsImpl instance) =>
    <String, dynamic>{'watcher': instance.watcher};

_$WatcherNotificationsImpl _$$WatcherNotificationsImplFromJson(
  Map<String, dynamic> json,
) => _$WatcherNotificationsImpl(
  email: json['email'] as bool? ?? false,
  sms: json['sms'] as bool? ?? false,
);

Map<String, dynamic> _$$WatcherNotificationsImplToJson(
  _$WatcherNotificationsImpl instance,
) => <String, dynamic>{'email': instance.email, 'sms': instance.sms};

_$OnecarePersonalConfigImpl _$$OnecarePersonalConfigImplFromJson(
  Map<String, dynamic> json,
) => _$OnecarePersonalConfigImpl(
  defaultTeam: json['defaultTeam'] as String?,
  onecareView: (json['onecareView'] as num?)?.toInt(),
);

Map<String, dynamic> _$$OnecarePersonalConfigImplToJson(
  _$OnecarePersonalConfigImpl instance,
) => <String, dynamic>{
  'defaultTeam': instance.defaultTeam,
  'onecareView': instance.onecareView,
};
