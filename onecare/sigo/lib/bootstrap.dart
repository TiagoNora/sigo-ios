import 'dart:async';
import 'dart:io';

// TODO: Enable Firebase App Check for production security
// import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_inappwebview_android/flutter_inappwebview_android.dart';

import 'app.dart';
import 'config/app_features.dart';
import 'core/di/injection.dart';
import 'domain/repositories/config_repository.dart';
import 'firebase_options.dart';
import 'services/error_handler.dart';
import 'services/notification_service.dart';
import 'services/offline_cache_service.dart';
import 'services/version_info.dart';
import 'services/home_widget_service.dart';

Future<void> runSigoApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock app to portrait orientation only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  if (Platform.isAndroid) {
    InAppWebViewPlatform.instance = AndroidInAppWebViewPlatform();
  }

  // Check package info to determine flavor
  try {
    final info = await PackageInfo.fromPlatform();
    AppFeatures.isDev = info.packageName.endsWith('.dev');
    debugPrint('App Flavor: ${AppFeatures.isDev ? "DEV" : "PROD"} (Package: ${info.packageName})');
  } catch (e) {
    debugPrint('Failed to determine app flavor: $e');
  }

  // Initialize Firebase with timeout and error handling
  try {
    debugPrint('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        debugPrint('Firebase initialization timed out after 10 seconds');
        throw TimeoutException('Firebase initialization timed out');
      },
    );
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    // Firebase is critical - app cannot continue without it
    // Re-throw to prevent app from starting with broken Firebase
    rethrow;
  }

  // TODO: Enable Firebase App Check for production security
  // This adds an extra layer of protection ensuring only legitimate app
  // instances can access Firestore. See docs/APP_CHECK_SETUP.md for setup.
  // await FirebaseAppCheck.instance.activate(
  //   androidProvider: kDebugMode
  //       ? AndroidProvider.debug
  //       : AndroidProvider.playIntegrity,
  //   appleProvider: kDebugMode
  //       ? AppleProvider.debug
  //       : AppleProvider.appAttest,
  // );

  // Configure dependency injection
  await configureDependencies();

  // Register VersionInfo with version label
  final versionLabel = await _loadVersionLabel();
  getIt.registerSingleton<VersionInfo>(VersionInfo(versionLabel));

  // Pass all uncaught Flutter errors to Crashlytics in non-debug builds
  // Only if Firebase was initialized successfully
  try {
    if (!kDebugMode && Firebase.apps.isNotEmpty) {
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    }
  } catch (e) {
    debugPrint('Failed to configure Crashlytics: $e');
  }

  // Pass all uncaught async errors to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    try {
      if (!kDebugMode && Firebase.apps.isNotEmpty) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
    } catch (e) {
      debugPrint('Failed to record error in Crashlytics: $e');
    }
    return true;
  };

  // Initialize global error handling
  ErrorHandler.initialize();

  runApp(const MyApp());

  // Defer heavier initialization until after first frame
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_initializeAfterFirstFrame());
  });
}

Future<void> _initializeAfterFirstFrame() async {
  // Initialize offline cache
  await OfflineCacheService.initialize();

  // Initialize NotificationService from DI container (only if enabled and Firebase is available)
  if (AppFeatures.enableNotifications && Firebase.apps.isNotEmpty) {
    try {
      await getIt<NotificationService>().initialize();

      // Setup Firebase background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Subscribe to tenant FCM topic if config exists
      await getIt<ConfigRepository>().ensureTopicSubscription();
    } catch (e) {
      debugPrint('Failed to initialize notifications: $e');
    }
  }

  // Initialize Home Widget Service
  try {
    final homeWidgetService = HomeWidgetService();
    await homeWidgetService.initialize(navigatorKey: rootNavigatorKey);
    getIt.registerSingleton<HomeWidgetService>(homeWidgetService);

    // Schedule 15-minute periodic widget updates
    await homeWidgetService.schedulePeriodicUpdates();
  } catch (e) {
    debugPrint('Failed to initialize home widget service: $e');
  }

  // Avoid writing test data on startup; real data is pushed after login.
}

Future<String> _loadVersionLabel() async {
  try {
    final info = await PackageInfo.fromPlatform();
    if ((info.version).isNotEmpty) {
      final build = info.buildNumber.trim();
      if (build.isNotEmpty) {
        return 'v${info.version}.$build';
      }
      return 'v${info.version}';
    }
  } catch (e) {
    debugPrint('Failed to get package info: $e');
  }
  return 'v1.0.1';
}
