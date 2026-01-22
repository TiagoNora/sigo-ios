import '../../models/user.dart';
import '../../models/tenant_config.dart';
import '../../models/logout_reason.dart';

/// Abstract repository for authentication operations.
/// Defines the contract for OAuth authentication and user management.
abstract class AuthRepository {
  /// Build the OAuth authorization URL with PKCE.
  ///
  /// Returns a map containing:
  /// - 'url': The authorization URL to load in WebView
  /// - 'state': The state parameter for CSRF protection
  Future<Map<String, String>> buildAuthorizationUrl();

  /// Exchange authorization code for access tokens.
  ///
  /// [code] - The authorization code from OAuth callback
  ///
  /// Returns true if token exchange was successful, false otherwise.
  Future<bool> exchangeCodeForTokens(String code);

  /// Refresh the access token using the refresh token.
  ///
  /// Returns true if refresh was successful, false otherwise.
  Future<bool> refreshTokens();

  /// Fetch and cache user information from the API.
  Future<void> fetchUserInfo();

  /// Get the OAuth logout URL.
  ///
  /// Returns a map containing:
  /// - 'url': The logout URL to load in WebView
  /// - 'state': The state parameter for CSRF protection
  ///
  /// Returns null if not authenticated.
  Future<Map<String, String>?> getLogoutUrl();

  /// Log out the current user and clear tokens.
  Future<void> logout({LogoutReason reason = LogoutReason.userRequested});

  /// Check if the user is currently authenticated.
  bool get isAuthenticated;

  /// Check if authentication is still initializing.
  bool get isInitializing;

  /// Check if the access token has expired.
  bool get isTokenExpired;

  /// Get the current access token.
  String? get accessToken;

  /// Get the current ID token.
  String? get idToken;

  /// Get the current user ID.
  String? get userId;

  /// Get the current user information.
  User? get currentUser;

  /// Get the OAuth redirect URI.
  String get redirectUri;

  /// Get the current tenant configuration.
  TenantConfig? get tenantConfig;

  /// Watch for user authentication changes.
  ///
  /// Returns a stream that emits the current user when authentication state changes.
  Stream<User?> get userStream;

  /// Wait for authentication initialization to complete.
  Future<void> get ready;

  /// Get the last logout reason.
  LogoutReason get lastLogoutReason;
}
