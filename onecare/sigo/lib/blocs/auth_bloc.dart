import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import '../domain/repositories/auth_repository.dart';
import '../models/logout_reason.dart';

part 'auth_event.dart';
part 'auth_state.dart';
part 'auth_bloc.freezed.dart';

/// Business Logic Component for managing authentication state.
///
/// This BLoC handles all authentication-related operations including:
/// - User session initialization and persistence
/// - OAuth login flow coordination
/// - Authorization code exchange
/// - Logout operations with different reasons
/// - Reactive authentication state changes
///
/// The AuthBloc listens to the [AuthRepository] user stream and automatically
/// updates its state when the authentication status changes.
///
/// ## Events Handled:
/// - [AuthStarted]: Initializes auth state on app startup
/// - [OAuthLoginRequested]: Triggers navigation to OAuth login
/// - [AuthCodeExchanged]: Processes OAuth callback and exchanges code for tokens
/// - [LogoutRequested]: Logs out user with specified reason
///
/// ## States Emitted:
/// - [AuthInitial]: Initial state before initialization
/// - [AuthLoading]: Authentication operation in progress
/// - [AuthAuthenticated]: User is successfully authenticated
/// - [AuthUnauthenticated]: User is not authenticated (with logout reason)
/// - [AuthFailure]: Authentication error occurred
///
/// ## Usage Example:
/// ```dart
/// // Listen to auth state changes
/// BlocListener<AuthBloc, AuthState>(
///   listener: (context, state) {
///     state.when(
///       authenticated: () => Navigator.pushReplacementNamed(context, '/home'),
///       unauthenticated: (reason) => Navigator.pushReplacementNamed(context, '/login'),
///       failure: (message) => ScaffoldMessenger.of(context).showSnackBar(...),
///       initial: () {},
///       loading: () {},
///     );
///   },
/// )
///
/// // Trigger login
/// context.read<AuthBloc>().add(const OAuthLoginRequested());
///
/// // Trigger logout
/// context.read<AuthBloc>().add(const LogoutRequested(LogoutReason.userRequested));
/// ```
@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this.authRepository) : super(const AuthState.initial()) {
    on<AuthStarted>(_onStarted);
    on<OAuthLoginRequested>(_onOAuthLoginRequested);
    on<AuthCodeExchanged>(_onAuthCodeExchanged);
    on<LogoutRequested>(_onLogoutRequested);
    on<_AuthUserChanged>(_onUserChanged);

    // Listen to authentication state changes
    _userSubscription = authRepository.userStream.listen((user) {
      add(_AuthUserChanged(user));
    });
  }

  final AuthRepository authRepository;
  StreamSubscription? _userSubscription;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    try {
      debugPrint('AuthBloc: Processing AuthStarted event');
      await authRepository.ready;
      debugPrint(
        'AuthBloc: AuthRepository ready, isAuthenticated: ${authRepository.isAuthenticated}',
      );
      if (authRepository.isAuthenticated) {
        debugPrint(
          'AuthBloc: User is authenticated on startup, emitting AuthAuthenticated',
        );
        emit(const AuthState.authenticated());
      } else {
        debugPrint(
          'AuthBloc: User is not authenticated on startup, emitting AuthUnauthenticated',
        );
        emit(AuthState.unauthenticated(
          reason: authRepository.lastLogoutReason,
        ));
      }
    } catch (e) {
      debugPrint('AuthBloc: Error during startup: $e');
      emit(AuthState.failure(e.toString()));
    }
  }

  Future<void> _onOAuthLoginRequested(
    OAuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    // This event triggers navigation to the OAuth WebView screen
    // The actual state change happens in AuthCodeExchanged
    emit(const AuthState.loading());
  }

  Future<void> _onAuthCodeExchanged(
    AuthCodeExchanged event,
    Emitter<AuthState> emit,
  ) async {
    try {
      debugPrint(
        'AuthBloc: Processing AuthCodeExchanged (success: ${event.success}, isAuthenticated: ${authRepository.isAuthenticated})',
      );
      if (event.success && authRepository.isAuthenticated) {
        debugPrint('AuthBloc: Emitting AuthAuthenticated state');
        emit(const AuthState.authenticated());
      } else {
        debugPrint('AuthBloc: Emitting AuthUnauthenticated state');
        emit(AuthState.unauthenticated(
          reason: authRepository.lastLogoutReason,
        ));
      }
    } catch (e) {
      debugPrint('AuthBloc: Error during auth code exchange: $e');
      emit(AuthState.failure(e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await authRepository.logout(reason: event.reason);
      emit(AuthState.unauthenticated(reason: event.reason));
    } catch (e) {
      debugPrint('AuthBloc: Error during logout: $e');
      // Even if logout fails, we should still emit unauthenticated
      // to clear the UI state
      emit(AuthState.unauthenticated(reason: event.reason));
    }
  }

  void _onUserChanged(
    _AuthUserChanged event,
    Emitter<AuthState> emit,
  ) {
    debugPrint(
      'AuthBloc: User changed (user is ${event.user == null ? "null" : "not null"})',
    );
    state.maybeWhen(
      unauthenticated: (_) => null,
      orElse: () {
        if (event.user == null) {
          debugPrint('AuthBloc: User is null, emitting AuthUnauthenticated');
          emit(AuthState.unauthenticated(
            reason: authRepository.lastLogoutReason,
          ));
        }
      },
    );

    state.maybeWhen(
      authenticated: () => null,
      orElse: () {
        if (event.user != null) {
          debugPrint('AuthBloc: User is not null, emitting AuthAuthenticated');
          emit(const AuthState.authenticated());
        }
      },
    );
  }

  @override
  Future<void> close() {
    _userSubscription?.cancel();
    return super.close();
  }
}
