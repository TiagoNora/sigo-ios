import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../../core/di/injection.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../l10n/app_localizations.dart';

class OAuthLogoutScreen extends StatefulWidget {
  const OAuthLogoutScreen({super.key});

  @override
  State<OAuthLogoutScreen> createState() => _OAuthLogoutScreenState();
}

class _OAuthLogoutScreenState extends State<OAuthLogoutScreen> {
  WebViewController? _controller;
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
    final logoutData = authRepository.getLogoutUrl();

    // If no logout URL available (no ID token), just return success
    if (logoutData == null) {
      if (mounted) {
        Navigator.of(context).pop(true);
      }
      return;
    }

    final logoutUrl = logoutData['url']!;
    _expectedState = logoutData['state']!;

    final controller = WebViewController();

    // Enable Android-specific settings for image loading
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController androidController =
          controller.platform as AndroidWebViewController;
      androidController
        ..setMediaPlaybackRequiresUserGesture(false)
        ..setMixedContentMode(MixedContentMode.alwaysAllow);
    }

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            return _handleNavigation(request.url);
          },
          onHttpError: (HttpResponseError error) {
            debugPrint(
              'HTTP error during logout: ${error.response?.statusCode}',
            );
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint(
              'WebResource error during logout: ${error.description} (${error.errorCode})',
            );
            if (error.isForMainFrame ?? false) {
              if (mounted) {
                setState(() {
                  _errorMessage = 'Connection error: ${error.description}';
                  _isLoading = false;
                });
              }
            }
          },
        ),
      );

    await controller.loadRequest(Uri.parse(logoutUrl));

    if (mounted) {
      setState(() {
        _controller = controller;
      });
    }
  }

  NavigationDecision _handleNavigation(String url) {
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
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        // State mismatch - still consider it successful since we tried to logout
        debugPrint('State mismatch during logout, but continuing');
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      }

      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }

  void _retry() {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
      _controller = null;
    });
    _initWebView();
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
          if (_errorMessage == null && _controller != null)
            WebViewWidget(controller: _controller!),
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
