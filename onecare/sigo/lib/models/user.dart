import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    @Default('') String username,
    @Default('') String name,
    @Default('') String email,
    @Default('') String phone,
    @JsonKey(fromJson: _parseDateTime, toJson: _dateToIso) required DateTime creationDate,
    @JsonKey(fromJson: _parseDateTime, toJson: _dateToIso) required DateTime lastUpdate,
    UserConfig? config,
    @Default('') String type,
    @Default('') String href,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

@freezed
class UserConfig with _$UserConfig {
  const factory UserConfig({
    int? defaultDashboard,
    Notifications? notifications,
    OnecarePersonalConfig? onecarePersonalConfig,
  }) = _UserConfig;

  factory UserConfig.fromJson(Map<String, dynamic> json) =>
      _$UserConfigFromJson(json);
}

@freezed
class Notifications with _$Notifications {
  const factory Notifications({
    WatcherNotifications? watcher,
  }) = _Notifications;

  factory Notifications.fromJson(Map<String, dynamic> json) =>
      _$NotificationsFromJson(json);
}

@freezed
class WatcherNotifications with _$WatcherNotifications {
  const factory WatcherNotifications({
    @Default(false) bool email,
    @Default(false) bool sms,
  }) = _WatcherNotifications;

  factory WatcherNotifications.fromJson(Map<String, dynamic> json) =>
      _$WatcherNotificationsFromJson(json);
}

@freezed
class OnecarePersonalConfig with _$OnecarePersonalConfig {
  const factory OnecarePersonalConfig({
    String? defaultTeam,
    int? onecareView,
  }) = _OnecarePersonalConfig;

  factory OnecarePersonalConfig.fromJson(Map<String, dynamic> json) =>
      _$OnecarePersonalConfigFromJson(json);
}

DateTime _parseDateTime(Object? value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.parse(value);
  }
  return DateTime.now();
}

String _dateToIso(DateTime value) => value.toIso8601String();
