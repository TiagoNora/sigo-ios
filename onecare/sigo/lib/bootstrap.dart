import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app.dart';
import 'core/di/injection.dart';
import 'services/error_handler.dart';
import 'services/notification_service.dart';
import 'services/offline_cache_service.dart';
import 'services/version_info.dart';
import 'services/home_widget_service.dart';

Future<void> runSigoApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Configure dependency injection
  await configureDependencies();

  // Register VersionInfo with version label
  final versionLabel = await _loadVersionLabel();
  getIt.registerSingleton<VersionInfo>(VersionInfo(versionLabel));

  // Initialize offline cache
  await OfflineCacheService.initialize();

  // Initialize NotificationService from DI container
  await getIt<NotificationService>().initialize();

  // Initialize Home Widget Service
  final homeWidgetService = HomeWidgetService();
  await homeWidgetService.initialize(navigatorKey: rootNavigatorKey);
  getIt.registerSingleton<HomeWidgetService>(homeWidgetService);

  // Schedule 15-minute periodic widget updates
  await homeWidgetService.schedulePeriodicUpdates();

  // Avoid writing test data on startup; real data is pushed after login.

  // Setup Firebase background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Pass all uncaught Flutter errors to Crashlytics in non-debug builds
  if (!kDebugMode) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  }

  // Pass all uncaught async errors to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
    return true;
  };

  // Initialize global error handling
  ErrorHandler.initialize();

  runApp(const MyApp());
}

Future<String> _loadVersionLabel() async {
  try {
    final info = await PackageInfo.fromPlatform();
    if ((info.version).isNotEmpty) {
      return 'v${info.version}';
    }
  } catch (e) {
    debugPrint('Failed to get package info: $e');
  }
  return 'v1.0.1';
}
