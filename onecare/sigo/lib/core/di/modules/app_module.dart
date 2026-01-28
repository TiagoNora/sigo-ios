import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

@module
abstract class AppModule {
  @preResolve
  @singleton
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();

  @lazySingleton
  FirebaseMessaging get firebaseMessaging {
    // Check if Firebase is initialized before accessing FirebaseMessaging
    if (Firebase.apps.isEmpty) {
      debugPrint('AppModule: Firebase not initialized, cannot provide FirebaseMessaging');
      throw StateError('Firebase is not initialized. FirebaseMessaging is unavailable.');
    }
    return FirebaseMessaging.instance;
  }

  @singleton
  FlutterLocalNotificationsPlugin get localNotifications =>
      FlutterLocalNotificationsPlugin();

  @singleton
  FlutterSecureStorage get secureStorage => const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );

  @lazySingleton
  FirebaseFirestore get firestore {
    // Check if Firebase is initialized before accessing FirebaseFirestore
    if (Firebase.apps.isEmpty) {
      debugPrint('AppModule: Firebase not initialized, cannot provide FirebaseFirestore');
      throw StateError('Firebase is not initialized. FirebaseFirestore is unavailable.');
    }
    return FirebaseFirestore.instance;
  }
}
