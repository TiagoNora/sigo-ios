import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_durations.dart';
import 'auth_interceptor.dart';

/// Creates a Dio client with optional SSL certificate verification bypass.
///
/// In DEBUG mode only, SSL certificate verification is bypassed to allow
/// development/testing with self-signed certificates.
///
/// In RELEASE/PROFILE mode, standard SSL verification is enforced for security.
///
/// If [authService] is provided (AuthService or AuthRepository), the client
/// will automatically handle 401 errors by clearing the local session and
/// forcing re-authentication.
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
      // development/testing with self-signed certificates
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
    } else {
      // In RELEASE/PROFILE mode, enforce SSL verification
      //
      // TODO: Implement SSL Certificate Pinning for production
      // To add certificate pinning:
      // 1. Add the server's certificate to assets/
      // 2. Load and parse the certificate
      // 3. Compare against the certificate provided in the callback
      // Example:
      // client.badCertificateCallback = (X509Certificate cert, String host, int port) {
      //   // Verify the certificate against pinned certificate
      //   return _verifyCertificate(cert, host, port);
      // };
      //
      // Note: Certificate pinning requires maintenance when certificates are rotated
    }
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
