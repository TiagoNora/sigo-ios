import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigo/models/app_notification.dart';

void main() {
  group('AppNotification', () {
    group('constructor', () {
      test('creates instance with required fields', () {
        final notification = AppNotification(
          id: 'test-id',
          title: 'Test Title',
          body: 'Test Body',
        );

        expect(notification.id, 'test-id');
        expect(notification.title, 'Test Title');
        expect(notification.body, 'Test Body');
        expect(notification.data, isEmpty);
        expect(notification.read, false);
        expect(notification.receivedAt, isA<DateTime>());
      });

      test('creates instance with custom data', () {
        final customData = {'key': 'value', 'ticketId': 'TT-123'};
        final receivedAt = DateTime(2025, 1, 1);

        final notification = AppNotification(
          id: 'test-id',
          title: 'Test',
          data: customData,
          receivedAt: receivedAt,
          read: true,
        );

        expect(notification.data, customData);
        expect(notification.receivedAt, receivedAt);
        expect(notification.read, true);
      });

      test('defaults data to empty map if null', () {
        final notification = AppNotification(id: 'test-id');

        expect(notification.data, isEmpty);
      });

      test('defaults receivedAt to now if null', () {
        final before = DateTime.now();
        final notification = AppNotification(id: 'test-id');
        final after = DateTime.now();

        expect(
          notification.receivedAt.isAfter(before) ||
              notification.receivedAt.isAtSameMomentAs(before),
          true,
        );
        expect(
          notification.receivedAt.isBefore(after) ||
              notification.receivedAt.isAtSameMomentAs(after),
          true,
        );
      });

      test('defaults read to false', () {
        final notification = AppNotification(id: 'test-id');

        expect(notification.read, false);
      });
    });

    group('copyWith', () {
      test('creates copy with updated read status', () {
        final original = AppNotification(
          id: 'test-id',
          title: 'Test',
          body: 'Body',
          read: false,
        );

        final updated = original.copyWith(read: true);

        expect(updated.id, original.id);
        expect(updated.title, original.title);
        expect(updated.body, original.body);
        expect(updated.data, original.data);
        expect(updated.receivedAt, original.receivedAt);
        expect(updated.read, true);
      });

      test('preserves all fields when read is not provided', () {
        final original = AppNotification(
          id: 'test-id',
          title: 'Test',
          body: 'Body',
          data: {'key': 'value'},
          read: true,
        );

        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.title, original.title);
        expect(copy.body, original.body);
        expect(copy.data, original.data);
        expect(copy.receivedAt, original.receivedAt);
        expect(copy.read, original.read);
      });
    });

    group('ticketId getter', () {
      test('returns ticketId from data when present', () {
        final notification = AppNotification(
          id: 'test-id',
          data: {'ticketId': 'TT-2025-123'},
        );

        expect(notification.ticketId, 'TT-2025-123');
      });

      test('returns null when ticketId not in data', () {
        final notification = AppNotification(
          id: 'test-id',
          data: {'other': 'value'},
        );

        expect(notification.ticketId, null);
      });

      test('returns null when data is empty', () {
        final notification = AppNotification(id: 'test-id');

        expect(notification.ticketId, null);
      });
    });

    group('fromMap', () {
      test('creates instance from database map with string data', () {
        final map = {
          'id': 'notif-123',
          'title': 'Title',
          'body': 'Body',
          'data': json.encode({'ticketId': 'TT-123'}),
          'received_at': 1704067200000, // 2024-01-01 00:00:00 UTC
          'read': 1,
        };

        final notification = AppNotification.fromMap(map);

        expect(notification.id, 'notif-123');
        expect(notification.title, 'Title');
        expect(notification.body, 'Body');
        expect(notification.data['ticketId'], 'TT-123');
        expect(
          notification.receivedAt,
          DateTime.fromMillisecondsSinceEpoch(1704067200000),
        );
        expect(notification.read, true);
      });

      test('creates instance from database map with map data', () {
        final map = {
          'id': 'notif-123',
          'title': 'Title',
          'body': 'Body',
          'data': {'ticketId': 'TT-123'},
          'received_at': 1704067200000,
          'read': 0,
        };

        final notification = AppNotification.fromMap(map);

        expect(notification.data['ticketId'], 'TT-123');
        expect(notification.read, false);
      });

      test('handles null values gracefully', () {
        final map = {
          'id': 'notif-123',
          'title': null,
          'body': null,
          'data': json.encode({}),
          'received_at': null,
          'read': null,
        };

        final notification = AppNotification.fromMap(map);

        expect(notification.id, 'notif-123');
        expect(notification.title, null);
        expect(notification.body, null);
        expect(notification.data, isEmpty);
        expect(notification.receivedAt, DateTime.fromMillisecondsSinceEpoch(0));
        expect(notification.read, false);
      });
    });

    group('toMap', () {
      test('converts instance to database map', () {
        final receivedAt = DateTime.fromMillisecondsSinceEpoch(1704067200000);
        final notification = AppNotification(
          id: 'notif-123',
          title: 'Title',
          body: 'Body',
          data: {'ticketId': 'TT-123', 'other': 'value'},
          receivedAt: receivedAt,
          read: true,
        );

        final map = notification.toMap();

        expect(map['id'], 'notif-123');
        expect(map['title'], 'Title');
        expect(map['body'], 'Body');
        expect(json.decode(map['data'] as String), {
          'ticketId': 'TT-123',
          'other': 'value',
        });
        expect(map['received_at'], 1704067200000);
        expect(map['read'], 1);
      });

      test('converts unread notification correctly', () {
        final notification = AppNotification(
          id: 'notif-123',
          read: false,
        );

        final map = notification.toMap();

        expect(map['read'], 0);
      });

      test('handles null title and body', () {
        final notification = AppNotification(id: 'notif-123');

        final map = notification.toMap();

        expect(map['title'], null);
        expect(map['body'], null);
      });
    });

    group('toMap and fromMap round-trip', () {
      test('preserves all data through serialization', () {
        final original = AppNotification(
          id: 'notif-123',
          title: 'Test Title',
          body: 'Test Body',
          data: {'ticketId': 'TT-123', 'key': 'value'},
          receivedAt: DateTime.fromMillisecondsSinceEpoch(1704067200000),
          read: true,
        );

        final map = original.toMap();
        final restored = AppNotification.fromMap(map);

        expect(restored.id, original.id);
        expect(restored.title, original.title);
        expect(restored.body, original.body);
        expect(restored.data, original.data);
        expect(restored.receivedAt, original.receivedAt);
        expect(restored.read, original.read);
      });
    });
  });
}
