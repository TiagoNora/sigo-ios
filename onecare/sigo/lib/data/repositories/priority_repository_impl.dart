import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

import '../../domain/repositories/priority_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../models/priority.dart';
import '../../services/api_service.dart';
import '../../services/network_exception.dart';
import '../../services/connectivity_service.dart';

/// Implementation of PriorityRepository.
///
/// Handles loading and caching of ticket priorities with color parsing utilities.
@Singleton(as: PriorityRepository)
class PriorityRepositoryImpl implements PriorityRepository {
  final AuthRepository _authRepository;

  List<Priority> _priorities = [];
  bool _isLoading = false;
  String? _error;

  PriorityRepositoryImpl(this._authRepository);

  @override
  Future<void> loadPriorities() async {
    if (_priorities.isNotEmpty) return; // Already loaded

    // Check authentication before making API calls
    if (!_authRepository.isAuthenticated) {
      debugPrint(
          'Cannot load priorities: user not authenticated - triggering logout');
      await _authRepository.logout();
      return;
    }

    _isLoading = true;
    _error = null;

    try {
      final baseUrl = _authRepository.tenantConfig?.baseUrl;
      final accessToken = _authRepository.accessToken;

      if (baseUrl == null || accessToken == null) {
        throw Exception('Missing baseUrl or accessToken');
      }

      final apiService = ApiService(
        accessToken,
        baseUrl: baseUrl,
        authService: _authRepository,
      );
      final response = await apiService.getPriorities();

      _priorities = response
          .map((json) => Priority.fromJson(json as Map<String, dynamic>))
          .where((priority) => priority.enabled)
          .toList();

      // Sort by level
      _priorities.sort((a, b) => a.level.compareTo(b.level));

      debugPrint('Loaded ${_priorities.length} priorities');
      for (var priority in _priorities) {
        debugPrint(
            '  - ${priority.name}: color=${priority.color}, level=${priority.level}');
      }

      _isLoading = false;
    } on NetworkException {
      ConnectivityService.instance?.markOffline();
      _error = null;
      _isLoading = false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      debugPrint('Error loading priorities: $e');
    }
  }

  @override
  Priority? getPriorityByName(String name) {
    try {
      return _priorities.firstWhere(
        (priority) => priority.name.toUpperCase() == name.toUpperCase(),
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Color parseColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) {
      return Colors.grey;
    }

    try {
      // Remove any whitespace
      colorString = colorString.trim();

      // Handle rgba format: rgba(246,64,25,0.92)
      if (colorString.startsWith('rgba(')) {
        final rgbaMatch = RegExp(r'rgba\((\d+),\s*(\d+),\s*(\d+),\s*([\d.]+)\)')
            .firstMatch(colorString);
        if (rgbaMatch != null) {
          final r = int.parse(rgbaMatch.group(1)!);
          final g = int.parse(rgbaMatch.group(2)!);
          final b = int.parse(rgbaMatch.group(3)!);
          final a = double.parse(rgbaMatch.group(4)!);
          return Color.fromRGBO(r, g, b, a);
        }
      }

      // Handle hex format: #14da1c
      if (colorString.startsWith('#')) {
        colorString = colorString.substring(1);
        if (colorString.length == 6) {
          return Color(int.parse('FF$colorString', radix: 16));
        } else if (colorString.length == 8) {
          return Color(int.parse(colorString, radix: 16));
        }
      }

      return Colors.grey;
    } catch (e) {
      debugPrint('Error parsing color "$colorString": $e');
      return Colors.grey;
    }
  }

  @override
  List<Priority> get priorities => _priorities;

  @override
  bool get isLoading => _isLoading;

  @override
  String? get error => _error;
}
