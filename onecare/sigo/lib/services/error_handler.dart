import 'dart:async';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../constants/app_durations.dart';
import 'app_exception.dart';
import 'network_exception.dart';
import 'not_found_exception.dart';

/// Global error handler for the application.
///
/// Provides centralized error handling, logging, and user-friendly error messages.
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  /// Initialize global error handling.
  ///
  /// Call this in main() before runApp() to capture all errors.
  static void initialize() {
    // Catch Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      if (kDebugMode) {
        // In debug mode, print to console
        FlutterError.dumpErrorToConsole(details);
      } else {
        // In release mode, log and report
        _instance._logError(
          details.exception,
          details.stack,
          fatal: true,
        );
      }
    };

    // Catch errors outside of Flutter framework
    PlatformDispatcher.instance.onError = (error, stack) {
      _instance._logError(error, stack, fatal: true);
      return true;
    };
  }

  /// Handle an error and convert it to a user-friendly message.
  String handleError(dynamic error, [StackTrace? stackTrace]) {
    _logError(error, stackTrace);
    return getUserFriendlyMessage(error);
  }

  /// Get a user-friendly error message for any exception.
  String getUserFriendlyMessage(dynamic error) {
    if (error is NetworkException) {
      return error.message.isNotEmpty
          ? error.message
          : 'Network connection error. Please check your internet connection.';
    }

    if (error is NotFoundException) {
      return error.message.isNotEmpty
          ? error.message
          : 'The requested resource was not found.';
    }

    if (error is AuthException) {
      return error.message.isNotEmpty
          ? error.message
          : 'Authentication failed. Please login again.';
    }

    if (error is ValidationException) {
      return error.message.isNotEmpty
          ? error.message
          : 'Invalid input. Please check your information.';
    }

    if (error is ServerException) {
      if (error.statusCode == 500) {
        return 'Server error. Please try again later.';
      }
      if (error.statusCode == 503) {
        return 'Service temporarily unavailable. Please try again later.';
      }
      return error.message.isNotEmpty
          ? error.message
          : 'Server error occurred.';
    }

    if (error is TimeoutException) {
      return 'Request timed out. Please try again.';
    }

    // Generic error message for unknown errors
    if (kDebugMode) {
      return 'Error: ${error.toString()}';
    }
    return 'An unexpected error occurred. Please try again.';
  }

  /// Log error for debugging and analytics.
  void _logError(dynamic error, StackTrace? stackTrace, {bool fatal = false}) {
    if (kDebugMode) {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('${fatal ? '🔴 FATAL ERROR' : '⚠️  ERROR'}: ${error.toString()}');
      if (stackTrace != null) {
        debugPrint('Stack trace:\n$stackTrace');
      }
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }

    // Report crashes to Firebase Crashlytics in non-debug builds
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        fatal: fatal,
        reason: fatal ? 'Fatal application error' : 'Non-fatal error',
      );
    }
  }

  /// Show an error dialog to the user.
  static void showErrorDialog(BuildContext context, dynamic error) {
    final message = ErrorHandler().getUserFriendlyMessage(error);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show an error snackbar to the user.
  static void showErrorSnackBar(BuildContext context, dynamic error) {
    final message = ErrorHandler().getUserFriendlyMessage(error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
