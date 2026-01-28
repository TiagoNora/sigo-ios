import 'dart:async';
import 'package:flutter/foundation.dart';

/// Global service to handle and broadcast network errors
class GlobalErrorService {
  static final GlobalErrorService _instance = GlobalErrorService._internal();
  static GlobalErrorService get instance => _instance;

  GlobalErrorService._internal();

  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  Stream<String> get errorStream => _errorController.stream;

  /// Notify listeners about a network error
  void notifyError(String errorMessage) {
    debugPrint('GlobalErrorService: Broadcasting error: $errorMessage');
    if (!_errorController.isClosed) {
      _errorController.add(errorMessage);
    }
  }

  void dispose() {
    _errorController.close();
  }
}
