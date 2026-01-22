import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_inappwebview_android/flutter_inappwebview_android.dart';

import '../../../core/di/injection.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../l10n/app_localizations.dart';

class OAuthLogoutScreen extends StatefulWidget {
  const OAuthLogoutScreen({super.key});

  @override
  State<OAuthLogoutScreen> createState() => _OAuthLogoutScreenState();
}

class _OAuthLogoutScreenState extends State<OAuthLogoutScreen> {
  InAppWebViewController? _controller;
  String? _initialUrl;
  late String _expectedState;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  Future<void> _initWebView() async {
    final authRepository = getIt<AuthRepository>();
    final logoutData = await authRepository.getLogoutUrl();

    // If no logout URL available (no ID token), just return success
    if (logoutData == null) {
      if (mounted) {
        Navigator.of(context).pop(true);
      }
      return;
    }

    final logoutUrl = logoutData['url']!;
    _expectedState = logoutData['state']!;

    if (Platform.isAndroid) {
      InAppWebViewPlatform.instance = AndroidInAppWebViewPlatform();
    }
    if (Platform.isAndroid) {
      await InAppWebViewController.setWebContentsDebuggingEnabled(kDebugMode);
    }

    if (mounted) {
      setState(() {
        _initialUrl = logoutUrl;
        _errorMessage = null;
        _isLoading = true;
      });
    }
  }

  NavigationActionPolicy _handleNavigation(String url) {
    debugPrint('Logout navigation: $url');
    final uri = Uri.parse(url);
    final authRepository = getIt<AuthRepository>();

    // Check if this is the post-logout redirect URI
    if (url.startsWith(authRepository.redirectUri)) {
      final state = uri.queryParameters['state'];

      debugPrint(
        'Post-logout redirect received - state match: ${state == _expectedState}',
      );

      // Validate state parameter
      if (state == _expectedState) {
        // Logout successful, pop with success
        _clearWebViewCookies();
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        // State mismatch - still consider it successful since we tried to logout
        debugPrint('State mismatch during logout, but continuing');
        _clearWebViewCookies();
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      }

      return NavigationActionPolicy.CANCEL;
    }

    return NavigationActionPolicy.ALLOW;
  }

  void _retry() {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
      _controller = null;
      _initialUrl = null;
    });
    _initWebView();
  }

  void _clearWebViewCookies() {
    try {
      CookieManager().deleteAllCookies();
    } on MissingPluginException catch (e) {
      debugPrint('CookieManager not available: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.logout),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: Stack(
        children: [
          if (_errorMessage == null && _initialUrl != null)
            InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(_initialUrl!)),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                mediaPlaybackRequiresUserGesture: false,
                transparentBackground: false,
                useShouldOverrideUrlLoading: true,
              ),
              onWebViewCreated: (controller) {
                _controller = controller;
              },
              onLoadStart: (controller, url) {
                if (mounted) {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                }
              },
              onLoadStop: (controller, url) {
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                final url = navigationAction.request.url;
                if (url == null) {
                  return NavigationActionPolicy.ALLOW;
                }
                return _handleNavigation(url.toString());
              },
              onLoadHttpError: (controller, url, statusCode, description) {
                debugPrint('HTTP error during logout: $statusCode $description');
              },
              onReceivedError: (controller, request, error) {
                debugPrint(
                  'WebResource error during logout: ${error.description} (${error.type})',
                );
                if (request.isForMainFrame == true) {
                  if (mounted) {
                    setState(() {
                      _errorMessage = 'Connection error: ${error.description}';
                      _isLoading = false;
                    });
                  }
                }
              },
            ),
          if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            ),
          if (_isLoading)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    '${l10n.logout}...',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
