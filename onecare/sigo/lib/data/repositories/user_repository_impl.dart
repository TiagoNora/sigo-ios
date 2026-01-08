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

      final onecareViewId =
          userInfo['config']?['onecarePersonalConfig']?['onecareView'] as int?;
      if (onecareViewId == null) {
        debugPrint('No onecareView configured for user');
        return null;
      }

      final onecareView = await getWorkbenchById(onecareViewId);
      final usedWorkbenchesId = onecareView['usedWorkbenchesId'] as List?;
      if (usedWorkbenchesId == null || usedWorkbenchesId.isEmpty) {
        debugPrint('No workbenches configured in onecareView');
        return null;
      }

      final filterId = usedWorkbenchesId.first as int;
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
