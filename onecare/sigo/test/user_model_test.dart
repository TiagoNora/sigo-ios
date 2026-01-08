import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigo/models/user.dart';

void main() {
  group('User', () {
    group('constructor', () {
      test('creates instance with required fields', () {
        final creationDate = DateTime(2024, 1, 1);
        final lastUpdate = DateTime(2024, 12, 1);

        final user = User(
          username: 'john.doe',
          name: 'John Doe',
          email: 'john@example.com',
          phone: '+1234567890',
          creationDate: creationDate,
          lastUpdate: lastUpdate,
        );

        expect(user.username, 'john.doe');
        expect(user.name, 'John Doe');
        expect(user.email, 'john@example.com');
        expect(user.phone, '+1234567890');
        expect(user.creationDate, creationDate);
        expect(user.lastUpdate, lastUpdate);
        expect(user.config, null);
        expect(user.type, '');
        expect(user.href, '');
      });

      test('uses default values for optional string fields', () {
        final user = User(
          creationDate: DateTime.now(),
          lastUpdate: DateTime.now(),
        );

        expect(user.username, '');
        expect(user.name, '');
        expect(user.email, '');
        expect(user.phone, '');
        expect(user.type, '');
        expect(user.href, '');
      });

      test('accepts user config', () {
        final config = UserConfig(
          defaultDashboard: 1,
          onecarePersonalConfig: OnecarePersonalConfig(
            defaultTeam: 'TeamA',
          ),
        );

        final user = User(
          username: 'test',
          creationDate: DateTime.now(),
          lastUpdate: DateTime.now(),
          config: config,
        );

        expect(user.config, config);
        expect(user.config?.defaultDashboard, 1);
        expect(user.config?.onecarePersonalConfig?.defaultTeam, 'TeamA');
      });
    });

    group('fromJson', () {
      test('parses valid JSON with all fields', () {
        final json = {
          'username': 'john.doe',
          'name': 'John Doe',
          'email': 'john@example.com',
          'phone': '+1234567890',
          'creationDate': '2024-01-01T00:00:00.000Z',
          'lastUpdate': '2024-12-01T00:00:00.000Z',
          'type': 'admin',
          'href': '/users/john.doe',
          'config': {
            'defaultDashboard': 1,
            'onecarePersonalConfig': {
              'defaultTeam': 'TeamA',
              'onecareView': 2,
            },
          },
        };

        final user = User.fromJson(json);

        expect(user.username, 'john.doe');
        expect(user.name, 'John Doe');
        expect(user.email, 'john@example.com');
        expect(user.phone, '+1234567890');
        expect(user.creationDate, DateTime.parse('2024-01-01T00:00:00.000Z'));
        expect(user.lastUpdate, DateTime.parse('2024-12-01T00:00:00.000Z'));
        expect(user.type, 'admin');
        expect(user.href, '/users/john.doe');
        expect(user.config?.defaultDashboard, 1);
        expect(user.config?.onecarePersonalConfig?.defaultTeam, 'TeamA');
        expect(user.config?.onecarePersonalConfig?.onecareView, 2);
      });

      test('parses JSON with minimal fields', () {
        final json = {
          'creationDate': '2024-01-01T00:00:00.000Z',
          'lastUpdate': '2024-12-01T00:00:00.000Z',
        };

        final user = User.fromJson(json);

        expect(user.username, '');
        expect(user.name, '');
        expect(user.email, '');
        expect(user.phone, '');
        expect(user.config, null);
      });

      test('handles empty string dates by using DateTime.now()', () {
        final before = DateTime.now();
        final json = {
          'username': 'test',
          'creationDate': '',
          'lastUpdate': '',
        };

        final user = User.fromJson(json);
        final after = DateTime.now();

        // Should use DateTime.now() for empty strings
        expect(
          user.creationDate.isAfter(before) ||
              user.creationDate.isAtSameMomentAs(before),
          true,
        );
        expect(
          user.creationDate.isBefore(after) ||
              user.creationDate.isAtSameMomentAs(after),
          true,
        );
      });

      test('parses ISO 8601 date strings correctly', () {
        final json = {
          'creationDate': '2024-01-15T10:30:45.123Z',
          'lastUpdate': '2024-12-20T15:45:30.456Z',
        };

        final user = User.fromJson(json);

        expect(user.creationDate.year, 2024);
        expect(user.creationDate.month, 1);
        expect(user.creationDate.day, 15);
        expect(user.lastUpdate.year, 2024);
        expect(user.lastUpdate.month, 12);
        expect(user.lastUpdate.day, 20);
      });
    });

    group('toJson', () {
      test('serializes to JSON with all fields', () {
        final user = User(
          username: 'john.doe',
          name: 'John Doe',
          email: 'john@example.com',
          phone: '+1234567890',
          creationDate: DateTime.parse('2024-01-01T00:00:00.000Z'),
          lastUpdate: DateTime.parse('2024-12-01T00:00:00.000Z'),
          type: 'admin',
          href: '/users/john.doe',
          config: UserConfig(
            defaultDashboard: 1,
            onecarePersonalConfig: OnecarePersonalConfig(
              defaultTeam: 'TeamA',
            ),
          ),
        );

        // Use json encode/decode to ensure proper serialization
        final jsonString = json.encode(user.toJson());
        final parsed = json.decode(jsonString) as Map<String, dynamic>;

        expect(parsed['username'], 'john.doe');
        expect(parsed['name'], 'John Doe');
        expect(parsed['email'], 'john@example.com');
        expect(parsed['phone'], '+1234567890');
        expect(parsed['creationDate'], '2024-01-01T00:00:00.000Z');
        expect(parsed['lastUpdate'], '2024-12-01T00:00:00.000Z');
        expect(parsed['type'], 'admin');
        expect(parsed['href'], '/users/john.doe');

        final config = parsed['config'] as Map<String, dynamic>;
        expect(config['defaultDashboard'], 1);

        final onecareConfig = config['onecarePersonalConfig'] as Map<String, dynamic>;
        expect(onecareConfig['defaultTeam'], 'TeamA');
      });

      test('converts dates to ISO 8601 strings', () {
        final user = User(
          creationDate: DateTime.utc(2024, 6, 15, 10, 30, 45),
          lastUpdate: DateTime.utc(2024, 12, 20, 15, 45, 30),
        );

        final json = user.toJson();

        expect(json['creationDate'], isA<String>());
        expect(json['lastUpdate'], isA<String>());
        expect(json['creationDate'], contains('2024-06-15'));
        expect(json['lastUpdate'], contains('2024-12-20'));
      });
    });

    group('fromJson and toJson round-trip', () {
      test('preserves all data through serialization', () {
        // Use a JSON object directly to test the round-trip
        final originalJson = {
          'username': 'john.doe',
          'name': 'John Doe',
          'email': 'john@example.com',
          'phone': '+1234567890',
          'creationDate': '2024-01-01T00:00:00.000Z',
          'lastUpdate': '2024-12-01T00:00:00.000Z',
          'type': 'admin',
          'href': '/users/john.doe',
          'config': {
            'defaultDashboard': 1,
            'notifications': {
              'watcher': {
                'email': true,
                'sms': false,
              },
            },
            'onecarePersonalConfig': {
              'defaultTeam': 'TeamA',
              'onecareView': 2,
            },
          },
        };

        final user = User.fromJson(originalJson);

        // Use json encode/decode to ensure proper serialization
        final jsonString = json.encode(user.toJson());
        final restoredJson = json.decode(jsonString) as Map<String, dynamic>;

        expect(restoredJson['username'], originalJson['username']);
        expect(restoredJson['name'], originalJson['name']);
        expect(restoredJson['email'], originalJson['email']);
        expect(restoredJson['phone'], originalJson['phone']);
        expect(restoredJson['creationDate'], originalJson['creationDate']);
        expect(restoredJson['lastUpdate'], originalJson['lastUpdate']);
        expect(restoredJson['type'], originalJson['type']);
        expect(restoredJson['href'], originalJson['href']);

        final config = restoredJson['config'] as Map<String, dynamic>;
        final originalConfig = originalJson['config'] as Map<String, dynamic>;
        expect(config['defaultDashboard'], originalConfig['defaultDashboard']);

        final notifications = config['notifications'] as Map<String, dynamic>;
        final originalNotifications = originalConfig['notifications'] as Map<String, dynamic>;
        final watcher = notifications['watcher'] as Map<String, dynamic>;
        final originalWatcher = originalNotifications['watcher'] as Map<String, dynamic>;
        expect(watcher['email'], originalWatcher['email']);
        expect(watcher['sms'], originalWatcher['sms']);

        final onecareConfig = config['onecarePersonalConfig'] as Map<String, dynamic>;
        final originalOnecareConfig = originalConfig['onecarePersonalConfig'] as Map<String, dynamic>;
        expect(onecareConfig['defaultTeam'], originalOnecareConfig['defaultTeam']);
        expect(onecareConfig['onecareView'], originalOnecareConfig['onecareView']);
      });
    });

    group('copyWith', () {
      test('creates copy with updated fields', () {
        final original = User(
          username: 'john.doe',
          name: 'John Doe',
          creationDate: DateTime(2024, 1, 1),
          lastUpdate: DateTime(2024, 12, 1),
        );

        final updated = original.copyWith(
          name: 'Jane Doe',
          email: 'jane@example.com',
        );

        expect(updated.username, 'john.doe'); // unchanged
        expect(updated.name, 'Jane Doe'); // changed
        expect(updated.email, 'jane@example.com'); // changed
        expect(updated.creationDate, original.creationDate); // unchanged
      });
    });

    group('equality', () {
      test('two users with same data are equal', () {
        final creationDate = DateTime(2024, 1, 1);
        final lastUpdate = DateTime(2024, 12, 1);

        final user1 = User(
          username: 'john.doe',
          name: 'John Doe',
          creationDate: creationDate,
          lastUpdate: lastUpdate,
        );

        final user2 = User(
          username: 'john.doe',
          name: 'John Doe',
          creationDate: creationDate,
          lastUpdate: lastUpdate,
        );

        expect(user1, equals(user2));
        expect(user1.hashCode, equals(user2.hashCode));
      });

      test('two users with different data are not equal', () {
        final user1 = User(
          username: 'john.doe',
          creationDate: DateTime(2024, 1, 1),
          lastUpdate: DateTime(2024, 12, 1),
        );

        final user2 = User(
          username: 'jane.doe',
          creationDate: DateTime(2024, 1, 1),
          lastUpdate: DateTime(2024, 12, 1),
        );

        expect(user1, isNot(equals(user2)));
      });
    });
  });

  group('UserConfig', () {
    test('creates instance with all fields', () {
      final config = UserConfig(
        defaultDashboard: 1,
        notifications: Notifications(
          watcher: WatcherNotifications(email: true, sms: true),
        ),
        onecarePersonalConfig: OnecarePersonalConfig(
          defaultTeam: 'TeamA',
          onecareView: 2,
        ),
      );

      expect(config.defaultDashboard, 1);
      expect(config.notifications?.watcher?.email, true);
      expect(config.onecarePersonalConfig?.defaultTeam, 'TeamA');
    });

    test('all fields are optional', () {
      final config = UserConfig();

      expect(config.defaultDashboard, null);
      expect(config.notifications, null);
      expect(config.onecarePersonalConfig, null);
    });
  });

  group('WatcherNotifications', () {
    test('defaults email and sms to false', () {
      final watcher = WatcherNotifications();

      expect(watcher.email, false);
      expect(watcher.sms, false);
    });

    test('accepts custom values', () {
      final watcher = WatcherNotifications(email: true, sms: true);

      expect(watcher.email, true);
      expect(watcher.sms, true);
    });
  });

  group('OnecarePersonalConfig', () {
    test('all fields are optional', () {
      final config = OnecarePersonalConfig();

      expect(config.defaultTeam, null);
      expect(config.onecareView, null);
    });

    test('accepts custom values', () {
      final config = OnecarePersonalConfig(
        defaultTeam: 'TeamB',
        onecareView: 3,
      );

      expect(config.defaultTeam, 'TeamB');
      expect(config.onecareView, 3);
    });
  });
}
