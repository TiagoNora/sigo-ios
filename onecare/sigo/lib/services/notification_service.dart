import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';

import '../models/app_notification.dart';
import '../domain/repositories/auth_repository.dart';
import '../core/constants/notification_constants.dart';
import 'api_service.dart';

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
  List<AppNotification> _cache = <AppNotification>[];
  AuthRepository? _authRepository;
  String? _lastSyncedToken;
  String? _lastSyncedUserId;
  String? _persistedToken;

  Stream<List<AppNotification>> get notificationsStream =>
      _notificationsController.stream;

  /// Stream that emits ticket IDs when a notification is tapped.
  Stream<String> get navigationStream => _navigationController.stream;

  List<AppNotification> get notifications => List.unmodifiable(_cache);

  String? get fcmToken => _cachedToken;

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
      await Firebase.initializeApp();
    }
  }

  Future<void> _initDatabase() async {
    if (_db != null) return;

    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      '$dbPath/notifications.db',
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE notifications (
            id TEXT PRIMARY KEY,
            title TEXT,
            body TEXT,
            data TEXT,
            received_at INTEGER,
            read INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE tokens (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
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

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return;
    }

    try {
      _cachedToken = await _messaging.getToken();
      if (_cachedToken != null) {
        await _persistToken(_cachedToken!, _authRepository?.userId);
        if (kDebugMode) {
          debugPrint('FCM token: $_cachedToken');
        }
      }
    } catch (e) {
      debugPrint('Failed to obtain FCM token (will retry later): $e');
      _cachedToken = null;
    }

    _messaging.onTokenRefresh.listen((token) {
      _cachedToken = token;
      _persistToken(token, _authRepository?.userId);
      if (kDebugMode) {
        debugPrint('FCM token refreshed: $token');
      }
      _registerWithBackend();
    });
  }

  Future<void> _persistToken(String token, String? userId) async {
    try {
      await _initDatabase();
      _persistedToken = token;
      await _db?.insert(
        'tokens',
        {
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

    final notification =
        AppNotification.fromRemoteMessage(message, read: markRead);

    final hasTitle = notification.title?.trim().isNotEmpty ?? false;
    final hasBody = notification.body?.trim().isNotEmpty ?? false;
    final hasData = notification.data.isNotEmpty;
    if (!hasTitle && !hasBody && !hasData) {
      return;
    }

    await _saveNotification(notification);

    if (showNotification) {
      final hasContent = (notification.title?.isNotEmpty ?? false) ||
          (notification.body?.isNotEmpty ?? false);
      final shouldShowLocal = message.notification == null && hasContent;
      if (shouldShowLocal) {
        await _showLocalNotification(notification);
      }
    }

    // If markRead is true, it means the user tapped the notification to open the app
    // Navigate to notifications screen and open this notification's modal
    if (markRead) {
      _navigationController.add(notification.id);
    }
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
    const iOSDetails = DarwinNotificationDetails();

    final details =
        const NotificationDetails(android: androidDetails, iOS: iOSDetails);

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

  void _emitCache() {
    _notificationsController.add(List.unmodifiable(_cache));
  }

  void bindAuthService(AuthRepository authRepository) {
    _authRepository = authRepository;
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
    await _db?.close();
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  // Explicitly initialize Firebase in the background isolate
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
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
