import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';

/// Represents a notification received from Firebase Messaging and stored locally.
class AppNotification {
  final String id;
  final String? title;
  final String? body;
  final Map<String, dynamic> data;
  final DateTime receivedAt;
  final bool read;

  AppNotification({
    required this.id,
    this.title,
    this.body,
    Map<String, dynamic>? data,
    DateTime? receivedAt,
    this.read = false,
  })  : data = data ?? const <String, dynamic>{},
        receivedAt = receivedAt ?? DateTime.now();

  AppNotification copyWith({
    bool? read,
  }) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      data: data,
      receivedAt: receivedAt,
      read: read ?? this.read,
    );
  }

  /// Extracts the ticket ID from the notification data if present.
  String? get ticketId => data['ticketId'] as String?;

  factory AppNotification.fromRemoteMessage(
    RemoteMessage message, {
    bool read = false,
  }) {
    final notification = message.notification;
    final data = Map<String, dynamic>.from(message.data);
    final String id = _resolveMessageId(message, data);
    return AppNotification(
      id: id,
      title: notification?.title ?? message.data['title'] as String?,
      body: notification?.body ?? message.data['body'] as String?,
      data: data,
      receivedAt: _resolveReceivedAt(message),
      read: read,
    );
  }

  static DateTime _resolveReceivedAt(RemoteMessage message) {
    final sentTime = message.sentTime;
    if (sentTime == null) return DateTime.now();
    if (sentTime.millisecondsSinceEpoch <= 0) return DateTime.now();
    return sentTime;
  }

  static String _resolveMessageId(
    RemoteMessage message,
    Map<String, dynamic> data,
  ) {
    final messageId = message.messageId;
    if (messageId != null && messageId.isNotEmpty) {
      return messageId;
    }

    final dataId = data['id'] ??
        data['notificationId'] ??
        data['messageId'] ??
        data['ticketId'];
    if (dataId != null) {
      return dataId.toString();
    }

    final sentAt = message.sentTime?.millisecondsSinceEpoch ?? 0;
    final title = (message.notification?.title ?? data['title'] ?? '').toString();
    final body = (message.notification?.body ?? data['body'] ?? '').toString();
    final fallback = '$sentAt|$title|$body';
    return fallback.isNotEmpty
        ? fallback
        : DateTime.now().millisecondsSinceEpoch.toString();
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String,
      title: map['title'] as String?,
      body: map['body'] as String?,
      data: map['data'] is String
          ? json.decode(map['data'] as String) as Map<String, dynamic>
          : Map<String, dynamic>.from(map['data'] as Map),
      receivedAt:
          DateTime.fromMillisecondsSinceEpoch(map['received_at'] as int? ?? 0),
      read: (map['read'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'data': json.encode(data),
      'received_at': receivedAt.millisecondsSinceEpoch,
      'read': read ? 1 : 0,
    };
  }
}
