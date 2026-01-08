import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/config_repository.dart';
import '../../models/user.dart';
import '../../models/tenant_config.dart';
import '../../models/logout_reason.dart';
import '../../services/api_service.dart';
import '../../services/http_client.dart';

/// Implementation of AuthRepository.
///
/// Handles OAuth/OIDC authentication with PKCE flow, token management,
/// and user information persistence.
@Singleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final ConfigRepository _configRepository;
  final SharedPreferences _prefs;

  // OAuth/OIDC Configuration - dynamic based on tenant config
  static const String _redirectUri = 'com.alticelabs.sigo.onecare://authentication';
  static const List<String> _scopes = ['openid'];

  // Dynamic OAuth endpoints based on tenant config
  String get _issuer => _configRepository.currentConfig?.iamUrl ?? '';
  String get _clientId => _configRepository.currentConfig?.serviceId ?? '';
  String get authorizationEndpoint => '$_issuer/idp/authorize';
  String get _tokenEndpoint => '$_issuer/oauth/token';
  String get _endSessionEndpoint => '$_issuer/idp/logout';

  // Client credentials for Basic auth (generated dynamically)
  String get _basicAuth {
    final config = _configRepository.currentConfig;
    if (config == null) return '';
    final credentials = '${config.serviceId}:${config.servicePassword}';
    final encoded = base64Encode(utf8.encode(credentials));
    return 'Basic $encoded';
  }

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

  AuthRepositoryImpl(this._configRepository, this._prefs) {
    _loadToken();
  }

  Future<void> _loadToken() async {
    try {
      await _configRepository.ready;
      _accessToken = _prefs.getString(_accessTokenKey);
      _idToken = _prefs.getString(_idTokenKey);
      _refreshToken = _prefs.getString(_refreshTokenKey);
      _userId = _prefs.getString(_userIdKey);

      final expiresString = _prefs.getString(_expiresKey);
      if (expiresString != null) {
        _expiresAt = DateTime.parse(expiresString);
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
  Map<String, String> buildAuthorizationUrl() {
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
            'Authorization': _basicAuth,
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
            'Authorization': _basicAuth,
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
        await _clearToken();
        return false;
      }
    } catch (e) {
      debugPrint('Token refresh error: $e');
      await _clearToken();
      return false;
    }
  }

  Future<void> _saveToken() async {
    try {
      if (_accessToken != null) {
        await _prefs.setString(_accessTokenKey, _accessToken!);
      }
      if (_idToken != null) {
        await _prefs.setString(_idTokenKey, _idToken!);
      }
      if (_refreshToken != null) {
        await _prefs.setString(_refreshTokenKey, _refreshToken!);
      }
      if (_userId != null) {
        await _prefs.setString(_userIdKey, _userId!);
      }
      if (_expiresAt != null) {
        await _prefs.setString(_expiresKey, _expiresAt!.toIso8601String());
      }
    } catch (e) {
      debugPrint('Error saving token: $e');
    }
  }

  Future<void> _clearToken() async {
    try {
      await _prefs.remove(_accessTokenKey);
      await _prefs.remove(_idTokenKey);
      await _prefs.remove(_refreshTokenKey);
      await _prefs.remove(_userIdKey);
      await _prefs.remove(_expiresKey);

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
      _userController.add(_currentUser);
      debugPrint('User info fetched successfully: ${_currentUser?.name}');
    } catch (e) {
      debugPrint('Error fetching user info: $e');
    }
  }

  @override
  Map<String, String>? getLogoutUrl() {
    if (_idToken == null) return null;

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
