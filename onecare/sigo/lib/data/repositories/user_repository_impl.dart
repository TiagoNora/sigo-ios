import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../domain/repositories/user_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../services/api_service.dart';

/// Implementation of UserRepository.
///
/// Handles user-specific operations including user info, teams, and workbenches.
@Singleton(as: UserRepository)
class UserRepositoryImpl implements UserRepository {
  final AuthRepository _authRepository;

  UserRepositoryImpl(this._authRepository);

  ApiService get _apiService {
    if (_authRepository.accessToken == null) {
      throw Exception('Not authenticated');
    }
    final baseUrl = _authRepository.tenantConfig?.baseUrl ?? '';
    return ApiService(
      _authRepository.accessToken!,
      baseUrl: baseUrl,
      authService: _authRepository,
    );
  }

  int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Future<Map<String, dynamic>?> _loadFilterFromView(int viewId) async {
    final view = await getWorkbenchById(viewId);
    final usedWorkbenchesId = view['usedWorkbenchesId'] as List?;
    if (usedWorkbenchesId == null || usedWorkbenchesId.isEmpty) {
      debugPrint('No workbenches configured in view');
      return null;
    }

    final filterId = _asInt(usedWorkbenchesId.first);
    if (filterId == null) {
      debugPrint('Invalid filter workbench id');
      return null;
    }

    final filterWorkbench = await getWorkbenchById(filterId);
    final filterConfig = filterWorkbench['config'] as Map<String, dynamic>?;

    if (filterConfig == null) {
      debugPrint('No filter config found');
      return null;
    }

    final filterName = filterWorkbench['name'] as String?;

    return {
      'filterQuery': filterConfig,
      'filterName': filterName,
      'filterId': filterId,
    };
  }

  @override
  Future<Map<String, dynamic>> getUserInfo() async {
    if (!_authRepository.isAuthenticated) {
      debugPrint(
          'Cannot get user info: user not authenticated - triggering logout');
      await _authRepository.logout();
      throw Exception('Not authenticated');
    }

    try {
      return await _apiService.getUserInfo();
    } catch (e) {
      debugPrint('Error getting user info: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getWorkbenchById(int workbenchId) async {
    if (!_authRepository.isAuthenticated) {
      debugPrint(
          'Cannot get workbench: user not authenticated - triggering logout');
      await _authRepository.logout();
      throw Exception('Not authenticated');
    }

    try {
      return await _apiService.getWorkbenchById(workbenchId);
    } catch (e) {
      debugPrint('Error getting workbench: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> getDefaultFilter() async {
    try {
      if (!_authRepository.isAuthenticated) {
        debugPrint('Cannot get default filter: user not authenticated');
        return null;
      }

      final userInfo = await getUserInfo();

      final config = userInfo['config'] as Map<String, dynamic>?;
      final onecareViewId =
          _asInt(config?['onecarePersonalConfig']?['onecareView']);
      if (onecareViewId != null) {
        return await _loadFilterFromView(onecareViewId);
      }

      final defaultDashboardId = _asInt(config?['defaultDashboard']);
      if (defaultDashboardId != null) {
        return await _loadFilterFromView(defaultDashboardId);
      }

      debugPrint('No onecareView or default dashboard configured for user');
      return null;
    } catch (e) {
      // Default filter is optional, log but don't fail
      debugPrint('Failed to load default filter: $e');
      return null;
    }
  }

  @override
  Future<List<dynamic>> getUserTeams() async {
    if (!_authRepository.isAuthenticated) {
      debugPrint(
          'Cannot get user teams: user not authenticated - triggering logout');
      await _authRepository.logout();
      throw Exception('Not authenticated');
    }

    try {
      return await _apiService.getUserTeams();
    } catch (e) {
      debugPrint('Error getting user teams: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateDefaultTeam(String teamName) async {
    if (!_authRepository.isAuthenticated) {
      debugPrint(
          'Cannot update default team: user not authenticated - triggering logout');
      await _authRepository.logout();
      throw Exception('Not authenticated');
    }

    try {
      await _apiService.updateDefaultTeam(teamName);
    } catch (e) {
      debugPrint('Error updating default team: $e');
      rethrow;
    }
  }
}
