import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/logout_reason.dart';

/// Interceptor that forces re-authentication when a 401 error occurs.
/// Uses a lock to ensure only one logout runs at a time.
///
/// Accepts either AuthService (legacy) or AuthRepository (new) as authService parameter.
class AuthInterceptor extends QueuedInterceptor {
  final dynamic authService;

  bool _isHandlingUnauthorized = false;
  final List<Completer<void>> _logoutWaiters = [];

  AuthInterceptor({
    required this.authService,
  });

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Always use the latest access token from AuthService
    final token = authService.accessToken;
    if (token != null) {
      options.headers['authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      debugPrint(
        '401 Unauthorized detected. Forcing re-authentication and redirect to login.',
      );
      await _handleUnauthorized();
      handler.next(err);
      return;
    }

    handler.next(err);
  }

  Future<void> _handleUnauthorized() async {
    if (_isHandlingUnauthorized) {
      final completer = Completer<void>();
      _logoutWaiters.add(completer);
      await completer.future;
      return;
    }

    _isHandlingUnauthorized = true;
    try {
      await authService.logout(reason: LogoutReason.sessionExpired);
    } catch (e) {
      debugPrint('Error while clearing session after 401: $e');
    } finally {
      for (final completer in _logoutWaiters) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
      _logoutWaiters.clear();
      _isHandlingUnauthorized = false;
    }
  }
}
