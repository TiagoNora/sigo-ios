import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_inappwebview_android/flutter_inappwebview_android.dart';

import '../../../blocs/auth_bloc.dart';
import '../../../core/di/injection.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../l10n/app_localizations.dart';

class OAuthLoginScreen extends StatefulWidget {
  const OAuthLoginScreen({super.key});

  @override
  State<OAuthLoginScreen> createState() => _OAuthLoginScreenState();
}

class _OAuthLoginScreenState extends State<OAuthLoginScreen> {
  InAppWebViewController? _controller;
  String? _initialUrl;
  late String _expectedState;
  bool _isLoading = true;
  bool _isExchangingCode = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  Future<void> _initWebView() async {
    final authRepository = getIt<AuthRepository>();
    final authData = await authRepository.buildAuthorizationUrl();
    final authUrl = authData['url']!;
    _expectedState = authData['state']!;

    if (Platform.isAndroid) {
      InAppWebViewPlatform.instance = AndroidInAppWebViewPlatform();
    }
    try {
      await CookieManager().deleteAllCookies();
    } on MissingPluginException catch (e) {
      debugPrint('CookieManager not available: $e');
    }

    if (Platform.isAndroid) {
      try {
        await InAppWebViewController.setWebContentsDebuggingEnabled(kDebugMode);
      } on MissingPluginException catch (e) {
        debugPrint('WebView debugging not available: $e');
      }
    }

    if (mounted) {
      setState(() {
        _initialUrl = authUrl;
        _errorMessage = null;
        _isLoading = true;
      });
    }
  }

  NavigationActionPolicy _handleNavigation(String url) {
    debugPrint('Navigation: $url');
    final uri = Uri.parse(url);
    final authRepository = getIt<AuthRepository>();

    // Check if this is the redirect URI
    if (url.startsWith(authRepository.redirectUri)) {
      final code = uri.queryParameters['code'];
      final state = uri.queryParameters['state'];

      debugPrint(
        'Redirect received - code: ${code != null}, state match: ${state == _expectedState}',
      );

      if (code != null && state == _expectedState) {
        _exchangeCodeForTokens(code);
      } else {
        // State mismatch or missing code - authentication failed
        Navigator.of(context).pop(false);
      }

      return NavigationActionPolicy.CANCEL;
    }

    return NavigationActionPolicy.ALLOW;
  }

  Future<void> _exchangeCodeForTokens(String code) async {
    if (_isExchangingCode) return;

    setState(() {
      _isExchangingCode = true;
      _isLoading = true;
    });

    final authRepository = getIt<AuthRepository>();
    final authBloc = context.read<AuthBloc>();
    final success = await authRepository.exchangeCodeForTokens(code);

    if (!mounted) return;

    // Dispatch the auth event and wait for state to change
    authBloc.add(AuthCodeExchanged(success: success));

    if (success) {
      // Wait for the AuthBloc state to become AuthAuthenticated
      debugPrint('Waiting for AuthBloc to emit AuthAuthenticated state...');
      await authBloc.stream
          .firstWhere(
            (state) => state is AuthAuthenticated,
            orElse: () => authBloc.state,
          )
          .timeout(
            const Duration(seconds: 2),
            onTimeout: () {
              debugPrint('Timeout waiting for AuthAuthenticated state');
              return authBloc.state;
            },
          );
      debugPrint('AuthBloc state is now: ${authBloc.state.runtimeType}');
      debugPrint('Popping OAuth screen and navigating to home');

      if (mounted) {
        // Pop this screen and let AuthWrapper handle navigation.
        Navigator.of(context).pop(success);
      }
      return;
    }

    if (mounted) {
      Navigator.of(context).pop(success);
    }
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(l10n.signIn),
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
                userAgent:
                    'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
                mediaPlaybackRequiresUserGesture: false,
                transparentBackground: false,
                useShouldOverrideUrlLoading: true,
                geolocationEnabled: true,
                mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                allowContentAccess: true,
                allowFileAccess: true,
                allowFileAccessFromFileURLs: true,
                allowUniversalAccessFromFileURLs: true,
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
              onConsoleMessage: (controller, consoleMessage) {
                debugPrint('WebView Console: ${consoleMessage.message}');
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                final url = navigationAction.request.url;
                if (url == null) {
                  return NavigationActionPolicy.ALLOW;
                }
                return _handleNavigation(url.toString());
              },
              onLoadHttpError: (controller, url, statusCode, description) {
                debugPrint('HTTP error: $statusCode $description');
              },
              onReceivedError: (controller, request, error) {
                debugPrint(
                  'WebResource error: ${error.description} (${error.type}) - URL: ${request.url}',
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
              androidOnGeolocationPermissionsShowPrompt:
                  (controller, origin) async {
                return GeolocationPermissionShowPromptResponse(
                  origin: origin,
                  allow: true,
                  retain: true,
                );
              },
              onReceivedServerTrustAuthRequest: (controller, challenge) async {
                // Accept SSL certificates for IAM server (dev/test environment)
                // This is needed because the IAM server uses an internal CA
                return ServerTrustAuthResponse(
                  action: ServerTrustAuthResponseAction.PROCEED,
                );
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
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
