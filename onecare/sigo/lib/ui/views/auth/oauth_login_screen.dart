import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../../blocs/auth_bloc.dart';
import '../../../core/constants/route_constants.dart';
import '../../../core/di/injection.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../l10n/app_localizations.dart';

class OAuthLoginScreen extends StatefulWidget {
  const OAuthLoginScreen({super.key});

  @override
  State<OAuthLoginScreen> createState() => _OAuthLoginScreenState();
}

class _OAuthLoginScreenState extends State<OAuthLoginScreen> {
  WebViewController? _controller;
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
    final authData = authRepository.buildAuthorizationUrl();
    final authUrl = authData['url']!;
    _expectedState = authData['state']!;

    final controller = WebViewController();

    // Clear cookies and cache to ensure fresh login
    await WebViewCookieManager().clearCookies();

    // Enable Android-specific settings for image loading
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController androidController =
          controller.platform as AndroidWebViewController;

      // Enable debugging for debug builds
      AndroidWebViewController.enableDebugging(true);

      androidController
        ..setMediaPlaybackRequiresUserGesture(false)
        ..setMixedContentMode(MixedContentMode.alwaysAllow)
        ..setGeolocationPermissionsPromptCallbacks(
          onShowPrompt: (request) async {
            return GeolocationPermissionsResponse(
              allow: true,
              retain: true,
            );
          },
        );
    }

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
      )
      ..setOnConsoleMessage((message) {
        debugPrint('WebView Console: ${message.message}');
      })
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
          onPageFinished: (String url) async {
            if (mounted) {
              setState(() => _isLoading = false);
            }
            // Fix broken images by fetching them via Dart HTTP client
            // which respects user-installed certificates
            await _fixBrokenImages(controller);
          },
          onNavigationRequest: (NavigationRequest request) {
            return _handleNavigation(request.url);
          },
          onHttpError: (HttpResponseError error) {
            debugPrint('HTTP error: ${error.response?.statusCode}');
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint(
              'WebResource error: ${error.description} (${error.errorCode}) - URL: ${error.url}',
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

    await controller.loadRequest(Uri.parse(authUrl));

    if (mounted) {
      setState(() {
        _controller = controller;
      });
    }
  }

  NavigationDecision _handleNavigation(String url) {
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

      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }

  Future<void> _fixBrokenImages(WebViewController controller) async {
    // List of image URLs that need to be fixed (from sigo-onecare domain)
    final authRepository = getIt<AuthRepository>();
    final configBaseUrl = authRepository.tenantConfig?.baseUrl ?? '';
    final baseWithoutApi = configBaseUrl.replaceFirst(
      RegExp(r'/sigo-api/?$'),
      '',
    );
    final normalizedBaseUrl =
        baseWithoutApi.endsWith('/')
            ? baseWithoutApi.substring(0, baseWithoutApi.length - 1)
            : baseWithoutApi;
    final fallbackBaseUrl = 'https://sigo-onecare.10.113.140.101.nip.io';
    final effectiveBaseUrl =
        normalizedBaseUrl.isNotEmpty ? normalizedBaseUrl : fallbackBaseUrl;
    final brokenImageUrls = [
      '$effectiveBaseUrl/nossis/fuxi/fuxi-nossis/img/logo-assurance-vertical.svg',
      '$effectiveBaseUrl/nossis/fuxi/fuxi-nossis/img/Login_NossisOne_sg_vfinal_background-slogan-02.svg',
    ];

    for (final imageUrl in brokenImageUrls) {
      try {
        // Create HTTP client that accepts all certificates
        final httpClient = HttpClient()
          ..badCertificateCallback = (cert, host, port) => true;

        final request = await httpClient.getUrl(Uri.parse(imageUrl));
        final response = await request.close();

        if (response.statusCode == 200) {
          final bytes = await response.fold<List<int>>(
            <int>[],
            (list, chunk) => list..addAll(chunk),
          );
          final base64Image = base64Encode(bytes);

          // Determine mime type
          String mimeType = 'image/svg+xml';
          if (imageUrl.endsWith('.png')) {
            mimeType = 'image/png';
          } else if (imageUrl.endsWith('.jpg') || imageUrl.endsWith('.jpeg')) {
            mimeType = 'image/jpeg';
          }

          final dataUri = 'data:$mimeType;base64,$base64Image';

          // Inject the image into the page
          await controller.runJavaScript('''
            (function() {
              var images = document.querySelectorAll('img[src="${imageUrl.replaceAll("'", "\\'")}"]');
              images.forEach(function(img) {
                img.src = '$dataUri';
                console.log('Fixed broken image: $imageUrl');
              });
              // Also fix background images
              var allElements = document.querySelectorAll('*');
              allElements.forEach(function(el) {
                var bg = window.getComputedStyle(el).backgroundImage;
                if (bg && bg.includes('${imageUrl.replaceAll("'", "\\'")}')) {
                  el.style.backgroundImage = 'url("$dataUri")';
                  console.log('Fixed broken background image: $imageUrl');
                }
              });
            })();
          ''');
        }
        httpClient.close();
      } catch (e) {
        debugPrint('Error fixing image $imageUrl: $e');
      }
    }
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
        // Pop this screen and navigate to home
        Navigator.of(context).pop(success);
        // Give time for navigation to complete, then ensure we're on home screen
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted && authRepository.isAuthenticated) {
          // Double-check we're on the home screen by using named route
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
        }
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
    });
    _initWebView();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.signIn),
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
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
