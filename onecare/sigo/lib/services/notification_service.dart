import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../firebase_options.dart';
import '../models/app_notification.dart';
import '../domain/repositories/auth_repository.dart';
import '../core/constants/notification_constants.dart';
import '../l10n/app_localizations.dart';
import '../l10n/app_localizations_en.dart';
import '../l10n/app_localizations_pt.dart';
import '../l10n/app_localizations_fr.dart';
import '../l10n/app_localizations_de.dart';
import 'api_service.dart';

/// Gets AppLocalizations for a given locale without requiring BuildContext.
AppLocalizations _getLocalizationsForLocale(Locale locale) {
  switch (locale.languageCode) {
    case 'pt':
      return AppLocalizationsPt();
    case 'fr':
      return AppLocalizationsFr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
    default:
      return AppLocalizationsEn();
  }
}

/// Gets AppLocalizations for the current device locale.
AppLocalizations _getDeviceLocalizations() {
  final locale = PlatformDispatcher.instance.locale;
  return _getLocalizationsForLocale(locale);
}

/// Gets AppLocalizations for the app's selected locale (from SharedPreferences).
Future<AppLocalizations> _getAppLocalizations() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('app_language') ?? 'en';
    return _getLocalizationsForLocale(Locale(languageCode));
  } catch (e) {
    return AppLocalizationsEn();
  }
}

/// Translates a title key to localized text.
String _translateTitleKey(String? titleKey, String ticketId, AppLocalizations l10n) {
  switch (titleKey) {
    case 'ticket_created_title':
      return l10n.ticketCreatedTitle(ticketId);
    case 'ticket_updated_title':
      return l10n.ticketUpdatedTitle(ticketId);
    case 'ticket_resolved_title':
      return l10n.ticketUpdatedTitle(ticketId); // Use updated as fallback
    case 'ticket_closed_title':
      return l10n.ticketUpdatedTitle(ticketId);
    case 'ticket_cancelled_title':
      return l10n.ticketUpdatedTitle(ticketId);
    case 'ticket_reopened_title':
      return l10n.ticketUpdatedTitle(ticketId);
    default:
      return l10n.ticketUpdatedTitle(ticketId);
  }
}

/// Translates a body key to localized text.
String _translateBodyKey(String? bodyKey, AppLocalizations l10n) {
  switch (bodyKey) {
    case 'body_ticket_created':
      return l10n.newTicketCreated;
    case 'body_note_added':
      return l10n.noteAdded;
    case 'body_attachment_added':
      return l10n.attachmentAdded;
    case 'body_attachment_removed':
      return l10n.attachmentRemoved;
    case 'body_impact_changed':
      return l10n.fieldChanged;
    case 'body_severity_changed':
      return l10n.fieldChanged;
    case 'body_status_changed':
      return l10n.fieldChanged;
    case 'ticket_updated':
      return l10n.ticketUpdated;
    default:
      return l10n.ticketUpdated;
  }
}

/// Formats a date string for notification display.
String _formatNotificationDate(String? isoDate, Locale locale) {
  if (isoDate == null || isoDate.isEmpty) return '';
  try {
    final dateTime = DateTime.parse(isoDate);
    final formatter = DateFormat('dd MMM yyyy, HH:mm', locale.languageCode);
    return formatter.format(dateTime.toLocal());
  } catch (e) {
    return isoDate;
  }
}

/// Checks if a change item is displayable.
bool _isDisplayableChange(Map<String, dynamic> changeItem) {
  final type = changeItem['type'] as String?;
  if (type == null) return false;

  switch (type) {
    case 'Create':
    case 'Created':
    case 'Note':
    case 'Attachment':
    case 'ExtraAttribute':
    case 'CI':
    case 'Relation':
    case 'Service':
    case 'Watcher':
    case 'Pendency':
      // These types are always displayable
      return true;

    case 'FieldChange':
      // Only status, impact, and severity field changes are displayed
      final fieldName = (changeItem['fieldName'] as String?)?.toLowerCase();
      return fieldName == 'status' || fieldName == 'impact' || fieldName == 'severity';

    default:
      return false;
  }
}

/// Filters the changes in notification data to only include displayable changes.
/// Returns null if no displayable changes exist, otherwise returns filtered data.
Map<String, dynamic>? _filterDisplayableChanges(Map<String, dynamic> data) {
  final changesRaw = data['changes'];
  if (changesRaw == null) {
    // No changes field - this might be a topic notification or other type
    return data;
  }

  List<dynamic>? changesData;
  if (changesRaw is String && changesRaw.isNotEmpty) {
    try {
      final parsed = json.decode(changesRaw);
      changesData = parsed is List ? parsed : null;
    } catch (e) {
      // If we can't parse, return original data
      return data;
    }
  } else if (changesRaw is List) {
    changesData = changesRaw;
  }

  if (changesData == null || changesData.isEmpty) {
    // No changes to display
    return null;
  }

  // Filter to only displayable changes
  final filteredChanges = changesData
      .where((item) => item is Map<String, dynamic> && _isDisplayableChange(item))
      .toList();

  if (filteredChanges.isEmpty) {
    // No displayable changes found
    return null;
  }

  // Return data with filtered changes
  final filteredData = Map<String, dynamic>.from(data);
  filteredData['changes'] = json.encode(filteredChanges);
  return filteredData;
}

/// Handles Firebase Cloud Messaging, local notifications, and persistence.
@singleton
class NotificationService {
  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;

  NotificationService(this._messaging, this._localNotifications) {
    instance = this;
  }

  static late NotificationService instance;
  static String _computeBackendBaseUrl(AuthRepository? authRepository) {
    final tenantBase = authRepository?.tenantConfig?.baseUrl;
    if (tenantBase != null && tenantBase.isNotEmpty) {
      return tenantBase;
    }
    // No hardcoded fallback URLs in production
    // If no tenant config is available, return empty string
    debugPrint('WARNING: No tenant config available for backend URL');
    return '';
  }

  Database? _db;
  bool _initialized = false;
  String? _cachedToken;
  final StreamController<List<AppNotification>> _notificationsController =
      StreamController<List<AppNotification>>.broadcast();
  final StreamController<String> _navigationController =
      StreamController<String>.broadcast();
  final StreamController<String?> _tokenController =
      StreamController<String?>.broadcast();
  List<AppNotification> _cache = <AppNotification>[];
  AuthRepository? _authRepository;
  String? _lastSyncedToken;
  String? _lastSyncedUserId;
  String? _persistedToken;
  String? _currentTopic;

  Stream<List<AppNotification>> get notificationsStream =>
      _notificationsController.stream;

  /// Stream that emits ticket IDs when a notification is tapped.
  Stream<String> get navigationStream => _navigationController.stream;

  /// Stream that emits FCM token updates.
  Stream<String?> get tokenStream => _tokenController.stream;

  List<AppNotification> get notifications => List.unmodifiable(_cache);

  String? get fcmToken => _cachedToken ?? _persistedToken;

  Future<void> initialize({bool fromBackground = false}) async {
    if (_initialized) return;

    await _ensureFirebaseInitialized();
    await _initLocalNotifications();
    await _initDatabase();
    await _loadStoredNotifications();

    if (!fromBackground) {
      await _requestPermissionAndToken();
      _listenForMessages();
    }

    _initialized = true;
  }

  Future<void> _ensureFirebaseInitialized() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }

  Future<void> _initDatabase() async {
    if (_db != null) return;

    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      '$dbPath/notifications.db',
      version: 4,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE notifications (
            id TEXT PRIMARY KEY,
            title TEXT,
            body TEXT,
            data TEXT,
            received_at INTEGER,
            read INTEGER,
            is_topic INTEGER DEFAULT 0,
            topic TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE tokens (
            id INTEGER PRIMARY KEY,
            token TEXT,
            user_id TEXT,
            saved_at INTEGER
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS tokens (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              token TEXT,
              user_id TEXT,
              saved_at INTEGER
            )
          ''');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE notifications ADD COLUMN is_topic INTEGER DEFAULT 0');
          await db.execute('ALTER TABLE notifications ADD COLUMN topic TEXT');
        }
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS tokens_new (
              id INTEGER PRIMARY KEY,
              token TEXT,
              user_id TEXT,
              saved_at INTEGER
            )
          ''');

          final rows = await db.query(
            'tokens',
            orderBy: 'saved_at DESC',
            limit: 1,
          );
          if (rows.isNotEmpty) {
            final row = rows.first;
            await db.insert(
              'tokens_new',
              {
                'id': 1,
                'token': row['token'],
                'user_id': row['user_id'],
                'saved_at': row['saved_at'],
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }

          await db.execute('DROP TABLE IF EXISTS tokens');
          await db.execute('ALTER TABLE tokens_new RENAME TO tokens');
        }
      },
    );

    await _loadStoredToken();
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings(NotificationConstants.icon);
    const iOSInit = DarwinInitializationSettings();
    const initSettings =
        InitializationSettings(android: androidInit, iOS: iOSInit);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) async {
        if (response.payload == null) return;
        try {
          final map = json.decode(response.payload!) as Map<String, dynamic>;
          final notification = AppNotification.fromMap(map);
          await markAsRead(notification.id);

          // Navigate to notifications screen and open this notification's modal
          _navigationController.add(notification.id);
        } catch (e) {
          debugPrint('Notification payload parse error: $e');
        }
      },
    );

    const channel = AndroidNotificationChannel(
      NotificationConstants.channelId,
      NotificationConstants.channelName,
      description: NotificationConstants.channelDescription,
      importance: Importance.high,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);
  }

  Future<void> _requestPermissionAndToken() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: true,
    );

    debugPrint('Notification permission: ${settings.authorizationStatus}');

    try {
      // Force new token generation (temporary fix for stale token)
      try {
        await _messaging.deleteToken();
      } catch (e) {
        debugPrint('Failed to delete old token: $e');
      }
      _cachedToken = await _messaging.getToken();
      if (_cachedToken != null) {
        await _persistToken(_cachedToken!, _authRepository?.userId);
        _tokenController.add(_cachedToken);
        if (kDebugMode) {
          debugPrint('FCM token: $_cachedToken');
        }
      }
    } catch (e) {
      debugPrint('Failed to obtain FCM token (will retry later): $e');
      _cachedToken = null;
      _tokenController.add(null);
    }

    _messaging.onTokenRefresh.listen((token) async {
      _cachedToken = token;
      await _persistToken(token, _authRepository?.userId);
      _tokenController.add(token);
      debugPrint('FCM token refreshed: $token');
      await _registerWithBackend();
    });
  }

  Future<void> _persistToken(String token, String? userId) async {
    try {
      await _initDatabase();
      _persistedToken = token;
      await _db?.insert(
        'tokens',
        {
          'id': 1,
          'token': token,
          'user_id': userId,
          'saved_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Failed to persist FCM token: $e');
    }
  }

  Future<void> _loadStoredToken() async {
    try {
      final rows = await _db?.query(
        'tokens',
        orderBy: 'saved_at DESC',
        limit: 1,
      );
      if (rows != null && rows.isNotEmpty) {
        _persistedToken = rows.first['token'] as String?;
        _tokenController.add(_persistedToken);
      }
    } catch (e) {
      debugPrint('Failed to load stored FCM token: $e');
    }
  }

  void _listenForMessages() {
    FirebaseMessaging.onMessage.listen(
      (message) => handleRemoteMessage(message, showNotification: true),
    );

    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => handleRemoteMessage(
        message,
        showNotification: false,
        markRead: true,
      ),
    );

    _messaging.getInitialMessage().then((message) {
      if (message != null) {
        handleRemoteMessage(
          message,
          showNotification: false,
          markRead: true,
        );
      }
    });
  }

  Future<void> handleRemoteMessage(
    RemoteMessage message, {
    bool showNotification = false,
    bool markRead = false,
  }) async {
    await _ensureFirebaseInitialized();
    await _initDatabase();

    var notification =
        AppNotification.fromRemoteMessage(message, read: markRead);

    final hasTitle = notification.title?.trim().isNotEmpty ?? false;
    final hasBody = notification.body?.trim().isNotEmpty ?? false;
    final hasData = notification.data.isNotEmpty;
    if (!hasTitle && !hasBody && !hasData) {
      return;
    }

    // Filter changes to only include displayable ones (status, impact, severity)
    // Skip notifications that have no displayable changes
    final filteredData = _filterDisplayableChanges(notification.data);
    if (filteredData == null) {
      debugPrint('Skipping notification with no displayable changes');
      return;
    }

    // Create notification with filtered data
    notification = AppNotification(
      id: notification.id,
      title: notification.title,
      body: notification.body,
      data: filteredData,
      receivedAt: notification.receivedAt,
      read: notification.read,
      isTopicNotification: notification.isTopicNotification,
      topic: notification.topic,
    );

    await _saveNotification(notification);

    if (showNotification) {
      // Generate localized title/body using app's selected language
      final localizedNotification = await _resolveLocalizedContent(notification);
      final hasContent = (localizedNotification.title?.isNotEmpty ?? false) ||
          (localizedNotification.body?.isNotEmpty ?? false);
      if (hasContent) {
        await _showLocalNotification(localizedNotification);
      }
    }

    // If markRead is true, it means the user tapped the notification to open the app
    // Navigate to notifications screen and open this notification's modal
    if (markRead) {
      _navigationController.add(notification.id);
    }
  }

  /// Resolves localized content for notifications using the app's selected language.
  /// This translates titleKey/bodyKey from the backend into localized text.
  Future<AppNotification> _resolveLocalizedContent(AppNotification notification) async {
    final type = notification.data['type']?.toString().toLowerCase();
    final l10n = await _getAppLocalizations();

    // Handle topic notifications (maintenance/general)
    if (type == 'maintenance') {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString('app_language') ?? 'en';
      final locale = Locale(languageCode);
      final startAt = notification.data['startAt']?.toString();
      final endAt = notification.data['endAt']?.toString();

      if (startAt != null && endAt != null) {
        final startFormatted = _formatNotificationDate(startAt, locale);
        final endFormatted = _formatNotificationDate(endAt, locale);

        return AppNotification(
          id: notification.id,
          title: l10n.maintenanceWindowTitle,
          body: l10n.maintenanceWindowBody(startFormatted, endFormatted),
          data: notification.data,
          receivedAt: notification.receivedAt,
          read: notification.read,
          isTopicNotification: notification.isTopicNotification,
          topic: notification.topic,
        );
      }
    } else if (type == 'general') {
      // Always use localized "General Information" title
      final body = notification.data['body']?.toString() ?? notification.body;

      if (body != null && body.isNotEmpty) {
        return AppNotification(
          id: notification.id,
          title: l10n.generalInformationTitle,
          body: body,
          data: notification.data,
          receivedAt: notification.receivedAt,
          read: notification.read,
          isTopicNotification: notification.isTopicNotification,
          topic: notification.topic,
        );
      }
    }

    // Handle ticket notifications with titleKey/bodyKey from backend
    final ticketId = notification.data['ticketId']?.toString();
    final titleKey = notification.data['titleKey']?.toString();
    final bodyKey = notification.data['bodyKey']?.toString();

    if (ticketId != null && ticketId.isNotEmpty) {
      // Use titleKey/bodyKey if provided by backend
      if (titleKey != null || bodyKey != null) {
        return AppNotification(
          id: notification.id,
          title: _translateTitleKey(titleKey, ticketId, l10n),
          body: _translateBodyKey(bodyKey, l10n),
          data: notification.data,
          receivedAt: notification.receivedAt,
          read: notification.read,
          isTopicNotification: notification.isTopicNotification,
          topic: notification.topic,
        );
      }

      // Fallback: check changes array for Create type
      final changesRaw = notification.data['changes'];
      if (changesRaw != null) {
        List<dynamic>? changesData;
        if (changesRaw is String && changesRaw.isNotEmpty) {
          try {
            final parsed = json.decode(changesRaw);
            changesData = parsed is List ? parsed : null;
          } catch (_) {}
        } else if (changesRaw is List) {
          changesData = changesRaw;
        }

        if (changesData != null) {
          for (final change in changesData) {
            if (change is Map<String, dynamic>) {
              final changeType = change['type']?.toString();
              if (changeType == 'Create' || changeType == 'Created') {
                return AppNotification(
                  id: notification.id,
                  title: l10n.ticketCreatedTitle(ticketId),
                  body: l10n.newTicketCreated,
                  data: notification.data,
                  receivedAt: notification.receivedAt,
                  read: notification.read,
                  isTopicNotification: notification.isTopicNotification,
                  topic: notification.topic,
                );
              }
            }
          }
        }
      }

      // Default ticket notification
      return AppNotification(
        id: notification.id,
        title: l10n.ticketUpdatedTitle(ticketId),
        body: l10n.ticketUpdated,
        data: notification.data,
        receivedAt: notification.receivedAt,
        read: notification.read,
        isTopicNotification: notification.isTopicNotification,
        topic: notification.topic,
      );
    }

    return notification;
  }

  Future<void> _showLocalNotification(AppNotification notification) async {
    const androidDetails = AndroidNotificationDetails(
      NotificationConstants.channelId,
      NotificationConstants.channelName,
      channelDescription: NotificationConstants.channelDescription,
      icon: NotificationConstants.icon,
      importance: Importance.high,
      priority: Priority.high,
    );
    // iOS: Use timeSensitive interruption level to show heads-up banner
    // This matches Android's high importance/priority behavior
    const iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const details =
        NotificationDetails(android: androidDetails, iOS: iOSDetails);

    await _localNotifications.show(
      notification.receivedAt.millisecondsSinceEpoch ~/ 1000,
      notification.title ?? 'Notification',
      notification.body ?? '',
      details,
      payload: json.encode(notification.toMap()),
    );
  }

  Future<void> _saveNotification(AppNotification notification) async {
    await _db?.insert(
      'notifications',
      notification.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    final existingIndex =
        _cache.indexWhere((element) => element.id == notification.id);
    if (existingIndex >= 0) {
      _cache[existingIndex] = notification;
    } else {
      _cache.insert(0, notification);
    }
    _emitCache();
  }

  Future<void> _loadStoredNotifications() async {
    final rows = await _db?.query(
          'notifications',
          orderBy: 'received_at DESC',
        ) ??
        [];
    _cache = rows.map(AppNotification.fromMap).toList(growable: true);
    _emitCache();
  }

  Future<void> reloadFromStorage() async {
    await _initDatabase();
    await _loadStoredNotifications();
  }

  Future<void> markAsRead(String id) async {
    await _db?.update(
      'notifications',
      {'read': 1},
      where: 'id = ?',
      whereArgs: [id],
    );

    final index = _cache.indexWhere((element) => element.id == id);
    if (index >= 0) {
      _cache[index] = _cache[index].copyWith(read: true);
      _emitCache();
    }
  }

  Future<void> markAllAsRead() async {
    await _db?.update('notifications', {'read': 1});
    _cache = _cache.map((n) => n.copyWith(read: true)).toList();
    _emitCache();
  }

  Future<void> clearAll() async {
    await _db?.delete('notifications');
    _cache = <AppNotification>[];
    _emitCache();
  }

  Future<void> clearLocalCache() async {
    try {
      await _initDatabase();
      await _db?.delete('notifications');
      // Don't delete FCM token - it's device-specific, not user-specific
      _cache = <AppNotification>[];
      _lastSyncedToken = null;
      _lastSyncedUserId = null;
      _emitCache();
      await _localNotifications.cancelAll();
    } catch (e) {
      debugPrint('Failed to clear notification cache: $e');
    }
  }

  void _emitCache() {
    _notificationsController.add(List.unmodifiable(_cache));
  }

  void bindAuthService(AuthRepository authRepository) {
    _authRepository = authRepository;
    // Ensure token is emitted to stream when binding (in case UI is listening)
    final currentToken = _cachedToken ?? _persistedToken;
    if (currentToken != null) {
      _tokenController.add(currentToken);
    }
    _registerWithBackend();
  }

  void unbindAuthService() {
    _unregisterFromBackend();
    _authRepository = null;
  }

  Future<void> _registerWithBackend() async {
    try {
      await initialize();
      final auth = _authRepository;
      if (auth == null) return;

      final userId = auth.userId;
      final accessToken = auth.accessToken;

      if (userId == null || accessToken == null) {
        return;
      }

      final token = _cachedToken ?? await _messaging.getToken();
      final effectiveToken = token ?? _persistedToken;
      if (effectiveToken == null || effectiveToken.isEmpty) return;

      // Re-register if token or userId changed
      if (_lastSyncedToken == effectiveToken && _lastSyncedUserId == userId) {
        return;
      }

      final backendBase = _computeBackendBaseUrl(auth);
      final apiService = ApiService(
        accessToken,
        baseUrl: backendBase,
        authService: auth,
      );

      await apiService.registerDeviceToken(
        userId: userId,
        deviceToken: effectiveToken,
      );
      _lastSyncedToken = effectiveToken;
      _lastSyncedUserId = userId;
      if (kDebugMode) {
        debugPrint('Device token registered for user $userId');
      }
    } catch (e) {
      debugPrint('Failed to register device token with backend: $e');
    }
  }

  Future<void> _unregisterFromBackend() async {
    try {
      await initialize();
      final token = _cachedToken ?? _persistedToken ?? await _messaging.getToken();
      final auth = _authRepository;
      if (token == null || token.isEmpty || auth == null) return;

      final backendBase = _computeBackendBaseUrl(auth);
      final apiService = ApiService(
        auth.accessToken ?? '',
        baseUrl: backendBase,
        authService: auth,
      );

      await apiService.unregisterDeviceToken(token);
      if (kDebugMode) {
        debugPrint('Device token unregistered from backend');
      }
    } catch (e) {
      debugPrint('Failed to unregister device token with backend: $e');
    }
  }

  /// Subscribes to tenant-specific FCM topic for general alerts.
  /// Topic name format: {tenant} or {tenant}_dev if dev mode is enabled.
  Future<void> subscribeToTenantTopic({
    required String tenant,
    bool isDev = false,
  }) async {
    try {
      final topicName = isDev ? '${tenant}_dev' : tenant;

      // Unsubscribe from previous topic if different
      if (_currentTopic != null && _currentTopic != topicName) {
        await unsubscribeFromCurrentTopic();
      }

      // Subscribe to new topic
      await _messaging.subscribeToTopic(topicName);
      _currentTopic = topicName;
      debugPrint('Subscribed to FCM topic: $topicName');
    } catch (e) {
      debugPrint('Failed to subscribe to tenant topic: $e');
    }
  }

  /// Unsubscribes from the current tenant topic.
  Future<void> unsubscribeFromCurrentTopic() async {
    if (_currentTopic == null) return;

    try {
      await _messaging.unsubscribeFromTopic(_currentTopic!);
      debugPrint('Unsubscribed from FCM topic: $_currentTopic');
      _currentTopic = null;
    } catch (e) {
      debugPrint('Failed to unsubscribe from topic: $e');
    }
  }

  Future<Map<String, dynamic>> sendTestNotification({
    required String title,
    String? body,
    Map<String, dynamic>? data,
  }) async {
    final auth = _authRepository;
    if (auth == null || auth.userId == null || auth.accessToken == null) {
      throw Exception('Cannot send notification: user not authenticated');
    }
    final backendBase = _computeBackendBaseUrl(auth);
    final apiService = ApiService(
      auth.accessToken!,
      baseUrl: backendBase,
      authService: auth,
    );

    return apiService.sendNotificationToUser(
      userId: auth.userId!,
      title: title,
      body: body,
      data: data,
    );
  }

  Future<void> dispose() async {
    await _notificationsController.close();
    await _navigationController.close();
    await _tokenController.close();
    await _db?.close();
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  // Explicitly initialize Firebase in the background isolate
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // Create a new instance for the background isolate
  final notificationService = NotificationService(
    FirebaseMessaging.instance,
    FlutterLocalNotificationsPlugin(),
  );

  await notificationService.initialize(fromBackground: true);
  await notificationService.handleRemoteMessage(
    message,
    showNotification: true,
  );
}
