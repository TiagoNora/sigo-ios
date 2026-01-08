import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'blocs/auth_bloc.dart';
import 'blocs/locale_cubit.dart';
import 'blocs/ticket_bloc.dart';
import 'constants/app_durations.dart';
import 'core/constants/route_constants.dart';
import 'core/di/injection.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/config_repository.dart';
import 'l10n/app_localizations.dart';
import 'services/connectivity_service.dart';
import 'services/global_error_service.dart';
import 'services/version_info.dart';
import 'services/notification_service.dart';
import 'services/home_widget_service.dart';
import 'styles/app_theme.dart';
import 'ui/views/auth/login_screen.dart';
import 'ui/views/main_navigation_screen.dart';
import 'ui/views/notifications/notifications_screen.dart';
import 'ui/views/qr_scanner/qr_scanner_screen.dart';
import 'models/logout_reason.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void _navigateToLoginGlobal() {
  debugPrint('GlobalAuthListener: Navigating to login');
  final navigator = rootNavigatorKey.currentState;
  if (navigator != null) {
    navigator.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    return;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<NotificationService>.value(
          value: getIt<NotificationService>(),
        ),
        RepositoryProvider<ConnectivityService>.value(
          value: getIt<ConnectivityService>(),
        ),
        RepositoryProvider<VersionInfo>.value(
          value: getIt<VersionInfo>(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => LocaleCubit()),
          BlocProvider(
            create: (_) => getIt<AuthBloc>()..add(const AuthStarted()),
          ),
          BlocProvider(
            create: (_) => getIt<TicketBloc>(),
            // Note: Don't load tickets here - AuthWrapper will trigger this
            // when user is authenticated (see listener below)
          ),
        ],
        child: BlocListener<AuthBloc, AuthState>(
          listenWhen: (prev, curr) =>
              prev is AuthAuthenticated && curr is AuthUnauthenticated,
          listener: (context, state) {
            if (state is AuthUnauthenticated &&
                state.reason == LogoutReason.sessionExpired) {
              final l10nContext = rootNavigatorKey.currentContext;
              final message = l10nContext != null
                  ? AppLocalizations.of(l10nContext).sessionExpired
                  : 'Session invalid. Please sign in again.';
              rootScaffoldMessengerKey.currentState?.showSnackBar(
                SnackBar(
                  content: Text(message),
                  duration: AppDurations.snackBarNormal,
                ),
              );
            }
            // Only auto-navigate to login if it's not a config reset
            // (config reset handles its own navigation to welcome screen)
            if (state is AuthUnauthenticated &&
                state.reason != LogoutReason.configReset) {
              _navigateToLoginGlobal();
            }
          },
          child: BlocBuilder<LocaleCubit, Locale>(
            builder: (context, locale) => MaterialApp(
              title: 'SIGO OneCare',
              debugShowCheckedModeBanner: false,
              navigatorKey: rootNavigatorKey,
              scaffoldMessengerKey: rootScaffoldMessengerKey,
              navigatorObservers: [routeObserver],
              locale: locale,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('en'),
                Locale('pt'),
                Locale('fr'),
                Locale('de'),
              ],
              theme: AppTheme.light(),
              home: const ConfigWrapper(),
              routes: {
                AppRoutes.login: (context) => const LoginScreen(),
                AppRoutes.home: (context) => const MainNavigationScreen(),
                AppRoutes.qrScanner: (context) => const QrScannerScreen(),
              },
              builder: (context, child) => _GlobalErrorListener(
                child: _OfflineGate(
                  child: Stack(
                    children: [
                      if (child != null) child,
                      const _StartupVersionBanner(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ConfigWrapper extends StatelessWidget {
  const ConfigWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final configRepository = getIt<ConfigRepository>();

    return FutureBuilder<void>(
      future: configRepository.ready,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!configRepository.isConfigured) {
          debugPrint(
            'ConfigWrapper: No configuration found, showing QR scanner',
          );
          return const _QrSetupScreen();
        }

        debugPrint('ConfigWrapper: Configuration found, showing AuthWrapper');
        return const AuthWrapper();
      },
    );
  }
}

class _QrSetupScreen extends StatelessWidget {
  const _QrSetupScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.qr_code_scanner, size: 120, color: Colors.blue),
              const SizedBox(height: 32),
              Text(
                l10n.welcomeToSigoOneCare,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.scanConfigurationQrDescription,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (context) => const QrScannerScreen(),
                    ),
                  );

                  if (result == true && context.mounted) {
                    // Configuration saved, trigger rebuild
                    // The ConfigWrapper will automatically rebuild via FutureBuilder
                    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
                  }
                },
                icon: const Icon(Icons.qr_code_scanner, size: 28),
                label: Text(
                  l10n.scanQrCodeButton,
                  style: const TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  StreamSubscription<String>? _navigationSubscription;
  bool _didUpdateWidgetStats = false;

  @override
  void initState() {
    super.initState();
    debugPrint('AuthWrapper: initState called, setting up listener');
    _setupNotificationNavigation();
  }

  void _setupNotificationNavigation() {
    final notificationService = getIt<NotificationService>();
    _navigationSubscription = notificationService.navigationStream.listen(
      (notificationId) {
        debugPrint('AuthWrapper: Navigation event received for notification: $notificationId');
        final navigator = rootNavigatorKey.currentState;
        if (navigator != null) {
          navigator.push(
            MaterialPageRoute(
              builder: (context) => NotificationsScreen(
                openNotificationId: notificationId,
              ),
            ),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _navigationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('AuthWrapper: build() called');
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) {
        final shouldListen =
            (previous is! AuthAuthenticated && current is AuthAuthenticated) ||
            (previous is AuthAuthenticated && current is! AuthAuthenticated);
        debugPrint(
          'AuthWrapper: listenWhen - previous: ${previous.runtimeType}, '
          'current: ${current.runtimeType}, shouldListen: $shouldListen',
        );
        return shouldListen;
      },
      listener: (context, state) {
        debugPrint('AuthWrapper: listener triggered with state: ${state.runtimeType}');
        if (state is AuthAuthenticated) {
          debugPrint(
            'AuthWrapper: User authenticated, loading tickets',
          );
          context.read<TicketBloc>().add(const LoadInitialTickets());
          final authRepository = getIt<AuthRepository>();
          getIt<NotificationService>().bindAuthService(authRepository);
          _didUpdateWidgetStats = false;
        } else if (state is AuthUnauthenticated) {
          debugPrint(
            'AuthWrapper: User logged out, clearing navigation stack',
          );
          getIt<NotificationService>().unbindAuthService();
          _didUpdateWidgetStats = false;
          if (state.reason == LogoutReason.configReset) {
            final navigator = rootNavigatorKey.currentState;
            if (navigator != null) {
              navigator.pushNamedAndRemoveUntil(
                AppRoutes.qrScanner,
                (route) => false,
              );
            }
          } else {
            _navigateToLoginGlobal();
          }
        }
      },
      builder: (context, state) {
        debugPrint('AuthWrapper: builder called with state: ${state.runtimeType}');
        if (state is AuthLoading || state is AuthInitial) {
          debugPrint('AuthWrapper: Showing loading spinner');
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state is AuthAuthenticated) {
          debugPrint('AuthWrapper: Showing MainNavigationScreen');
          if (!_didUpdateWidgetStats) {
            _didUpdateWidgetStats = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              getIt<HomeWidgetService>().updateWidgetWithTicketStats();
            });
          }
          return const MainNavigationScreen();
        }
        debugPrint('AuthWrapper: Showing LoginScreen');
        return const LoginScreen();
      },
    );
  }
}

class _OfflineGate extends StatelessWidget {
  final Widget? child;

  const _OfflineGate({this.child});

  @override
  Widget build(BuildContext context) {
    final connectivity = getIt<ConnectivityService>();

    return StreamBuilder<ConnectionStateStatus>(
      stream: connectivity.statusStream,
      initialData: connectivity.status,
      builder: (context, snapshot) {
        final l10n = AppLocalizations.of(context);
        final status = snapshot.data ?? connectivity.status;

        if (status == ConnectionStateStatus.checking) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (status != ConnectionStateStatus.online) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      l10n.noInternet,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.checkConnectionAndRetry,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => connectivity.recheck(),
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return child ?? const SizedBox.shrink();
      },
    );
  }
}

class _GlobalErrorListener extends StatefulWidget {
  final Widget child;

  const _GlobalErrorListener({required this.child});

  @override
  State<_GlobalErrorListener> createState() => _GlobalErrorListenerState();
}

class _GlobalErrorListenerState extends State<_GlobalErrorListener> {
  StreamSubscription<String>? _errorSubscription;
  String? _activeErrorMessage;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _errorSubscription = GlobalErrorService.instance.errorStream.listen(_handleError);
  }

  @override
  void dispose() {
    _errorSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_activeErrorMessage != null)
          Positioned.fill(
            child: Stack(
              children: [
                const ModalBarrier(
                  color: Colors.black54,
                  dismissible: false,
                ),
                Center(
                  child: _buildErrorOverlay(context, _activeErrorMessage!),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _handleError(String errorMessage) {
    if (!mounted) return;
    setState(() {
      _activeErrorMessage = errorMessage;
      _isRetrying = false;
    });
  }

  Widget _buildErrorOverlay(BuildContext context, String errorMessage) {
    final l10n = AppLocalizations.of(context);
    final translatedMessage = _translateErrorMessage(errorMessage, l10n);
    final shouldShowConnectionHint =
        !errorMessage.contains('Service not reachable');

    return Material(
      type: MaterialType.transparency,
      child: WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red[400], size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.error,
                  style: TextStyle(
                    color: Colors.red[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                translatedMessage,
                style: const TextStyle(fontSize: 16),
              ),
              if (shouldShowConnectionHint) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.checkYourConnection,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
              if (_isRetrying) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(l10n.loading),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: _isRetrying
                  ? null
                  : () async {
                      setState(() {
                        _isRetrying = true;
                      });
                      final rootContext = rootNavigatorKey.currentContext;
                      if (rootContext == null) {
                        if (!mounted) {
                          return;
                        }
                        setState(() {
                          _isRetrying = false;
                        });
                        return;
                      }

                      rootContext.read<ConnectivityService>().recheck();
                      final ticketBloc = rootContext.read<TicketBloc>();
                      ticketBloc.add(const RefreshTickets());

                      final nextState = await _waitForTicketRefreshCompletion(
                        ticketBloc,
                      );

                      if (!mounted) {
                        return;
                      }

                      setState(() {
                        _isRetrying = false;
                        if (nextState != null && nextState.error == null) {
                          _activeErrorMessage = null;
                        }
                      });
                    },
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _translateErrorMessage(String message, AppLocalizations l10n) {
    if (message.contains('Service not reachable')) {
      return l10n.serviceNotReachable;
    }
    if (message.contains('No internet connection')) {
      return l10n.noInternetConnection;
    }
    if (message.contains('Network connection error')) {
      return l10n.checkYourConnection;
    }
    return message;
  }

  Future<TicketState?> _waitForTicketRefreshCompletion(
    TicketBloc ticketBloc,
  ) async {
    final completer = Completer<TicketState?>();
    var sawLoading = ticketBloc.state.isLoading;
    var cancelled = false;

    late StreamSubscription<TicketState> subscription;
    subscription = ticketBloc.stream.listen(
      (state) {
        if (state.isLoading) {
          sawLoading = true;
          return;
        }

        if (sawLoading && !completer.isCompleted) {
          completer.complete(state);
          if (!cancelled) {
            cancelled = true;
            subscription.cancel();
          }
        }
      },
      onError: (_) {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      },
    );

    try {
      return await completer.future.timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          subscription.cancel();
          return ticketBloc.state;
        },
      );
    } finally {
      if (!cancelled) {
        cancelled = true;
        await subscription.cancel();
      }
    }
  }
}

class _StartupVersionBanner extends StatelessWidget {
  const _StartupVersionBanner();

  @override
  Widget build(BuildContext context) {
    final versionLabel = getIt<VersionInfo>().label;
    // Only show on the login screen (initial route) to avoid overlaying other pages
    final modalRoute = ModalRoute.of(context);
    if (modalRoute == null || modalRoute.isCurrent != true) {
      return const SizedBox.shrink();
    }

    return Positioned(
      right: 12,
      bottom: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          versionLabel,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
