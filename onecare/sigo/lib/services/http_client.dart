import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_durations.dart';
import 'auth_interceptor.dart';

/// Creates a Dio client with optional SSL certificate verification bypass.
///
/// - DEBUG mode: SSL certificate verification is bypassed (accepts all certs)
/// - RELEASE/PROFILE mode: Standard SSL verification is enforced
///
/// If [authService] is provided, the client will automatically handle 401
/// errors by clearing the local session and forcing re-authentication.
Dio createDioClient({String? baseUrl, dynamic authService}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl ?? '',
      connectTimeout: AppDurations.apiTimeout,
      receiveTimeout: AppDurations.apiTimeout,
    ),
  );

  // Configure SSL certificate handling
  (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
      (HttpClient client) {
    if (kDebugMode) {
      // In DEBUG mode, bypass SSL certificate verification to allow
      // development/testing with self-signed certificates or internal CAs.
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
    }
    // In RELEASE/PROFILE mode, use standard SSL verification.
    return client;
  };

  // Add auth interceptor if authService is provided
  if (authService != null) {
    dio.interceptors.add(
      AuthInterceptor(
        authService: authService,
      ),
    );
  }

  return dio;
}
