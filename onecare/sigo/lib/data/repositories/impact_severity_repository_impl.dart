import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

import '../../domain/repositories/impact_severity_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../models/impact.dart';
import '../../models/severity.dart';
import '../../services/api_service.dart';
import '../../services/network_exception.dart';
import '../../services/connectivity_service.dart';

/// Implementation of ImpactSeverityRepository.
///
/// Handles loading and caching of impacts and severities with color parsing utilities.
@Singleton(as: ImpactSeverityRepository)
class ImpactSeverityRepositoryImpl implements ImpactSeverityRepository {
  final AuthRepository _authRepository;

  List<Impact> _impacts = [];
  List<Severity> _severities = [];
  bool _isLoading = false;
  String? _error;

  ImpactSeverityRepositoryImpl(this._authRepository);

  @override
  Future<void> loadImpactsAndSeverities() async {
    if (_impacts.isNotEmpty && _severities.isNotEmpty) return; // Already loaded

    // Check authentication before making API calls
    if (!_authRepository.isAuthenticated) {
      debugPrint(
          'Cannot load impacts/severities: user not authenticated - triggering logout');
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

      // Load impacts and severities in parallel
      final results = await Future.wait<List<dynamic>>([
        apiService.getImpacts(),
        apiService.getSeveritiesFromCatalog(),
      ]);

      _impacts = (results[0] as List<dynamic>)
          .map((json) => Impact.fromJson(json as Map<String, dynamic>))
          .where((impact) => impact.enabled)
          .toList();

      _severities = (results[1] as List<dynamic>)
          .map((json) => Severity.fromJson(json as Map<String, dynamic>))
          .where((severity) => severity.enabled)
          .toList();

      // Sort by level
      _impacts.sort((a, b) => a.level.compareTo(b.level));
      _severities.sort((a, b) => a.level.compareTo(b.level));

      debugPrint(
          'Loaded ${_impacts.length} impacts and ${_severities.length} severities');

      _isLoading = false;
    } on NetworkException {
      ConnectivityService.instance?.markOffline();
      _error = null;
      _isLoading = false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      debugPrint('Error loading impacts and severities: $e');
    }
  }

  @override
  Impact? getImpactByName(String name) {
    try {
      return _impacts.firstWhere(
        (impact) => impact.name.toUpperCase() == name.toUpperCase(),
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Severity? getSeverityByName(String name) {
    try {
      return _severities.firstWhere(
        (severity) => severity.name.toUpperCase() == name.toUpperCase(),
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
  List<Impact> get impacts => _impacts;

  @override
  List<Severity> get severities => _severities;

  @override
  bool get isLoading => _isLoading;

  @override
  String? get error => _error;
}
