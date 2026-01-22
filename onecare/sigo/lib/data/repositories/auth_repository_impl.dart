import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/config_repository.dart';
import '../../models/user.dart';
import '../../models/tenant_config.dart';
import '../../models/logout_reason.dart';
import '../../services/api_service.dart';
import '../../services/http_client.dart';
import '../../services/offline_cache_service.dart';
import '../../services/home_widget_service.dart';
import '../../services/notification_service.dart';
import '../../core/di/injection.dart';
import '../../domain/repositories/ticket_repository.dart';

/// Implementation of AuthRepository.
///
/// Handles OAuth/OIDC authentication with PKCE flow, token management,
/// and user information persistence.
@Singleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final ConfigRepository _configRepository;
  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;

  // OAuth/OIDC Configuration - dynamic based on tenant config
  static const String _defaultRedirectUri =
      'com.alticelabs.sigo.onecare://authentication';
  static const List<String> _scopes = ['openid'];

  // Dynamic OAuth endpoints based on tenant config
  String get _issuer => _configRepository.currentConfig?.iamUrl ?? '';
  String get _clientId => _configRepository.currentConfig?.serviceId ?? '';
  String get authorizationEndpoint => '$_issuer/idp/authorize';
  String get _tokenEndpoint => '$_issuer/oauth/token';
  String get _endSessionEndpoint => '$_issuer/idp/logout';

  // Storage keys
  static const String _accessTokenKey = 'access_token';
  static const String _idTokenKey = 'id_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _expiresKey = 'token_expires';
  static const String _userIdKey = 'user_id';

  final Completer<void> _initCompleter = Completer<void>();

  final StreamController<User?> _userController = StreamController<User?>.broadcast();

  String? _accessToken;
  String? _idToken;
  String? _refreshToken;
  String? _userId;
  DateTime? _expiresAt;
  User? _currentUser;
  bool _isInitializing = true;
  LogoutReason _lastLogoutReason = LogoutReason.userRequested;

  // PKCE values - stored temporarily during auth flow
  String? _codeVerifier;

  AuthRepositoryImpl(this._configRepository, this._prefs, this._secureStorage) {
    _loadToken();
  }

  String _redirectUri = _defaultRedirectUri;

  Future<void> _ensureRedirectUri() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final packageName = info.packageName.trim();
      if (packageName.isNotEmpty) {
        _redirectUri = '$packageName://authentication';
      }
    } catch (e) {
      debugPrint('Failed to resolve redirect URI: $e');
      _redirectUri = _defaultRedirectUri;
    }
  }

  Future<void> _loadToken() async {
    try {
      await _configRepository.ready;
      final secureAccess = await _secureStorage.read(key: _accessTokenKey);
      final secureId = await _secureStorage.read(key: _idTokenKey);
      final secureRefresh = await _secureStorage.read(key: _refreshTokenKey);
      final secureUserId = await _secureStorage.read(key: _userIdKey);
      final secureExpires = await _secureStorage.read(key: _expiresKey);

      final legacyAccess = _prefs.getString(_accessTokenKey);
      final legacyId = _prefs.getString(_idTokenKey);
      final legacyRefresh = _prefs.getString(_refreshTokenKey);
      final legacyUserId = _prefs.getString(_userIdKey);
      final legacyExpires = _prefs.getString(_expiresKey);

      _accessToken = secureAccess ?? legacyAccess;
      _idToken = secureId ?? legacyId;
      _refreshToken = secureRefresh ?? legacyRefresh;
      _userId = secureUserId ?? legacyUserId;

      final expiresString = secureExpires ?? legacyExpires;
      if (expiresString != null) {
        _expiresAt = DateTime.tryParse(expiresString);
      }

      final hasLegacyData = [
        legacyAccess,
        legacyId,
        legacyRefresh,
        legacyUserId,
        legacyExpires,
      ].any((value) => value != null);
      final hasSecureData = [
        secureAccess,
        secureId,
        secureRefresh,
        secureUserId,
        secureExpires,
      ].any((value) => value != null);

      if (hasLegacyData && !hasSecureData) {
        await _migrateLegacyTokens(
          accessToken: legacyAccess,
          idToken: legacyId,
          refreshToken: legacyRefresh,
          userId: legacyUserId,
          expiresAt: legacyExpires,
        );
      }

      debugPrint(
          'AuthRepository: Loading tokens - hasAccess: ${_accessToken != null}, expired: $isTokenExpired, hasRefresh: ${_refreshToken != null}');

      if (_accessToken != null && !isTokenExpired) {
        debugPrint('AuthRepository: Valid token found, fetching user info');
        await fetchUserInfo();
      } else if (_refreshToken != null) {
        debugPrint(
            'AuthRepository: Token expired but refresh token available, refreshing');
        await refreshTokens();
      } else {
        debugPrint('AuthRepository: No valid tokens, user not authenticated');
        await _clearToken();
        _currentUser = null;
        _userController.add(_currentUser);
      }
    } catch (e) {
      debugPrint('Error loading token: $e');
    } finally {
      _isInitializing = false;
      debugPrint(
          'AuthRepository: Initialization complete, authenticated: $isAuthenticated, user: ${_currentUser?.name ?? "null"}');
      _userController.add(_currentUser);
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
    }
  }

  /// Generates a random string for PKCE code_verifier
  String _generateCodeVerifier() {
    final random = Random.secure();
    final values = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(values)
        .replaceAll('=', '')
        .replaceAll('+', '-')
        .replaceAll('/', '_');
  }

  /// Generates code_challenge from code_verifier using SHA256
  String _generateCodeChallenge(String codeVerifier) {
    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    return base64UrlEncode(digest.bytes)
        .replaceAll('=', '')
        .replaceAll('+', '-')
        .replaceAll('/', '_');
  }

  /// Generates a random state parameter
  String _generateState() {
    final random = Random.secure();
    final values = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(values)
        .replaceAll('=', '')
        .replaceAll('+', '-')
        .replaceAll('/', '_');
  }

  @override
  Future<Map<String, String>> buildAuthorizationUrl() async {
    await _ensureRedirectUri();
    _codeVerifier = _generateCodeVerifier();
    final codeChallenge = _generateCodeChallenge(_codeVerifier!);
    final state = _generateState();

    final uri = Uri.parse(authorizationEndpoint).replace(
      queryParameters: {
        'client_id': _clientId,
        'response_type': 'code',
        'redirect_uri': _redirectUri,
        'state': state,
        'scope': _scopes.join(' '),
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
      },
    );

    debugPrint('Authorization URL: $uri');

    return {
      'url': uri.toString(),
      'state': state,
    };
  }

  @override
  Future<bool> exchangeCodeForTokens(String code) async {
    if (_codeVerifier == null) {
      debugPrint('No code verifier available');
      return false;
    }

    try {
      debugPrint('Exchanging code for tokens');

      final dio = createDioClient();
      final response = await dio.post(
        _tokenEndpoint,
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
        data: {
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': _redirectUri,
          'client_id': _clientId,
          'code_verifier': _codeVerifier,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        _accessToken = data['access_token'];
        _idToken = data['id_token'];
        _refreshToken = data['refresh_token'];

        final expiresIn = data['expires_in'] as int?;
        if (expiresIn != null) {
          _expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
        }

        await _saveToken();
        await fetchUserInfo();

        // Resubscribe to tenant FCM topic on login
        try {
          final config = _configRepository.currentConfig;
          if (config != null) {
            await NotificationService.instance.subscribeToTenantTopic(
              tenant: config.tenant,
              isDev: config.isDev,
            );
          }
        } catch (e) {
          debugPrint('Failed to subscribe to FCM topic on login: $e');
        }

        // Clear code verifier after successful exchange
        _codeVerifier = null;

        debugPrint('Token exchange successful');
        return true;
      } else {
        debugPrint('Token exchange failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Token exchange error: $e');
      return false;
    }
  }

  @override
  Future<bool> refreshTokens() async {
    if (_refreshToken == null) {
      debugPrint('No refresh token available');
      return false;
    }

    try {
      debugPrint('Refreshing access token');

      final dio = createDioClient();
      final response = await dio.post(
        _tokenEndpoint,
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
        data: {
          'grant_type': 'refresh_token',
          'refresh_token': _refreshToken,
          'client_id': _clientId,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        _accessToken = data['access_token'];
        _idToken = data['id_token'];
        _refreshToken = data['refresh_token'] ?? _refreshToken;

        final expiresIn = data['expires_in'] as int?;
        if (expiresIn != null) {
          _expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
        }

        await _saveToken();
        await fetchUserInfo();

        debugPrint('Token refresh successful');
        return true;
      } else {
        debugPrint('Token refresh failed');
        await _handleUnauthenticated(LogoutReason.sessionExpired);
        return false;
      }
    } catch (e) {
      debugPrint('Token refresh error: $e');
      await _handleUnauthenticated(LogoutReason.sessionExpired);
      return false;
    }
  }

  Future<void> _handleUnauthenticated(LogoutReason reason) async {
    _lastLogoutReason = reason;
    await _clearToken();
    _currentUser = null;
    _userController.add(_currentUser);
  }

  Future<void> _saveToken() async {
    try {
      if (_accessToken != null) {
        await _secureStorage.write(
          key: _accessTokenKey,
          value: _accessToken!,
        );
      }
      if (_idToken != null) {
        await _secureStorage.write(
          key: _idTokenKey,
          value: _idToken!,
        );
      }
      if (_refreshToken != null) {
        await _secureStorage.write(
          key: _refreshTokenKey,
          value: _refreshToken!,
        );
      }
      if (_userId != null) {
        await _secureStorage.write(
          key: _userIdKey,
          value: _userId!,
        );
      }
      if (_expiresAt != null) {
        await _secureStorage.write(
          key: _expiresKey,
          value: _expiresAt!.toIso8601String(),
        );
      }
      await _clearLegacyTokens();
    } catch (e) {
      debugPrint('Error saving token: $e');
    }
  }

  Future<void> _clearLegacyTokens() async {
    try {
      await _prefs.remove(_accessTokenKey);
      await _prefs.remove(_idTokenKey);
      await _prefs.remove(_refreshTokenKey);
      await _prefs.remove(_userIdKey);
      await _prefs.remove(_expiresKey);
    } catch (e) {
      debugPrint('Error clearing legacy tokens: $e');
    }
  }

  Future<void> _migrateLegacyTokens({
    required String? accessToken,
    required String? idToken,
    required String? refreshToken,
    required String? userId,
    required String? expiresAt,
  }) async {
    try {
      if (accessToken != null) {
        await _secureStorage.write(key: _accessTokenKey, value: accessToken);
      }
      if (idToken != null) {
        await _secureStorage.write(key: _idTokenKey, value: idToken);
      }
      if (refreshToken != null) {
        await _secureStorage.write(
          key: _refreshTokenKey,
          value: refreshToken,
        );
      }
      if (userId != null) {
        await _secureStorage.write(key: _userIdKey, value: userId);
      }
      if (expiresAt != null) {
        await _secureStorage.write(key: _expiresKey, value: expiresAt);
      }
      await _clearLegacyTokens();
    } catch (e) {
      debugPrint('Error migrating legacy tokens: $e');
    }
  }

  Future<void> _clearToken() async {
    try {
      await _secureStorage.delete(key: _accessTokenKey);
      await _secureStorage.delete(key: _idTokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      await _secureStorage.delete(key: _userIdKey);
      await _secureStorage.delete(key: _expiresKey);
      await _clearLegacyTokens();

      _accessToken = null;
      _idToken = null;
      _refreshToken = null;
      _userId = null;
      _expiresAt = null;
    } catch (e) {
      debugPrint('Error clearing token: $e');
    }
  }

  @override
  Future<void> fetchUserInfo() async {
    await _configRepository.ready;
    final baseUrl = _configRepository.currentConfig?.baseUrl;
    if (baseUrl == null || baseUrl.isEmpty) {
      debugPrint('Cannot fetch user info: no tenant base URL configured');
      return;
    }
    if (_accessToken == null) {
      debugPrint('Cannot fetch user info: not authenticated');
      return;
    }

    try {
      final apiService = ApiService(
        _accessToken!,
        baseUrl: baseUrl,
        authService: this as dynamic, // Temporary cast for compatibility
      );
      final userJson = await apiService.getUserInfo();
      _currentUser = User.fromJson(userJson);
      _userId = _resolveUserId(userJson, _currentUser);
      await _saveToken();
      _userController.add(_currentUser);
      debugPrint('User info fetched successfully: ${_currentUser?.name}');
    } catch (e) {
      debugPrint('Error fetching user info: $e');
    }
  }

  String? _resolveUserId(Map<String, dynamic> userJson, User? user) {
    final raw = userJson['id'] ??
        userJson['userId'] ??
        userJson['user_id'] ??
        userJson['username'] ??
        user?.username;
    if (raw == null) return null;
    return raw.toString();
  }

  @override
  Future<Map<String, String>?> getLogoutUrl() async {
    if (_idToken == null) return null;

    // Ensure redirect URI is resolved before building logout URL.
    await _ensureRedirectUri();

    // Generate state for CSRF protection
    final state = _generateState();

    final uri = Uri.parse(_endSessionEndpoint).replace(
      queryParameters: {
        'id_token_hint': _idToken,
        'post_logout_redirect_uri': _redirectUri,
        'state': state,
      },
    );

    return {
      'url': uri.toString(),
      'state': state,
    };
  }

  @override
  Future<void> logout({LogoutReason reason = LogoutReason.userRequested}) async {
    _lastLogoutReason = reason;
    debugPrint(
      'AuthRepository.logout() called - current user: ${_currentUser?.name ?? "null"}, reason: $reason',
    );
    try {
      await OfflineCacheService.clearCache();
    } catch (e) {
      debugPrint('Failed to clear offline cache on logout: $e');
    }
    try {
      await getIt<TicketRepository>().clearCache();
    } catch (e) {
      debugPrint('Failed to clear ticket repository cache on logout: $e');
    }
    try {
      await HomeWidgetService().clearWidgetData();
    } catch (e) {
      debugPrint('Failed to clear widget cache on logout: $e');
    }
    try {
      await NotificationService.instance.clearLocalCache();
    } catch (e) {
      debugPrint('Failed to clear notification cache on logout: $e');
    }
    try {
      await NotificationService.instance.unsubscribeFromCurrentTopic();
    } catch (e) {
      debugPrint('Failed to unsubscribe from FCM topic on logout: $e');
    }
    await _clearToken();

    try {
      await _prefs.remove('selected_filter_query');
      await _prefs.remove('selected_filter_source_id');
      await _prefs.remove('selected_filter_label');
      await _prefs.remove('selected_filter_label_key');
    } catch (e) {
      debugPrint('Error clearing persisted filter: $e');
    }

    final wasNull = _currentUser == null;
    _currentUser = null;
    debugPrint('AuthRepository: Broadcasting user = null (was already null: $wasNull)');
    _userController.add(_currentUser);
    debugPrint('AuthRepository: Logout complete, user should be redirected to login');
  }

  @override
  bool get isAuthenticated => _accessToken != null && !isTokenExpired;

  @override
  bool get isTokenExpired {
    if (_expiresAt == null) return true;
    return DateTime.now().isAfter(_expiresAt!);
  }

  @override
  String? get accessToken => _accessToken;

  @override
  String? get idToken => _idToken;

  @override
  String? get userId => _userId;

  @override
  User? get currentUser => _currentUser;

  @override
  bool get isInitializing => _isInitializing;

  @override
  String get redirectUri => _redirectUri;

  @override
  TenantConfig? get tenantConfig => _configRepository.currentConfig;

  @override
  Stream<User?> get userStream => _userController.stream;

  @override
  Future<void> get ready => _initCompleter.future;

  @override
  LogoutReason get lastLogoutReason => _lastLogoutReason;

  void dispose() {
    _userController.close();
  }
}
