import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigo/blocs/auth_bloc.dart';
import 'package:sigo/domain/repositories/auth_repository.dart';
import 'package:sigo/models/logout_reason.dart';
import 'package:sigo/models/tenant_config.dart';
import 'package:sigo/models/user.dart';

/// Mock AuthRepository for testing
class _MockAuthRepository implements AuthRepository {
  _MockAuthRepository({
    bool isAuthenticated = false,
    User? currentUser,
    LogoutReason lastLogoutReason = LogoutReason.userRequested,
  })  : _isAuthenticated = isAuthenticated,
        _currentUser = currentUser,
        _lastLogoutReason = lastLogoutReason;

  bool _isAuthenticated;
  User? _currentUser;
  LogoutReason _lastLogoutReason;
  final _userStreamController = StreamController<User?>.broadcast();
  final _readyCompleter = Completer<void>();

  // Tracking method calls
  bool logoutCalled = false;
  bool refreshTokensCalled = false;
  bool fetchUserInfoCalled = false;
  LogoutReason? lastLogoutReasonParam;

  @override
  bool get isAuthenticated => _isAuthenticated;

  @override
  User? get currentUser => _currentUser;

  @override
  LogoutReason get lastLogoutReason => _lastLogoutReason;

  @override
  Stream<User?> get userStream => _userStreamController.stream;

  @override
  Future<void> get ready => _readyCompleter.future;

  @override
  bool get isInitializing => false;

  @override
  bool get isTokenExpired => false;

  @override
  String? get accessToken => _isAuthenticated ? 'mock-access-token' : null;

  @override
  String? get idToken => _isAuthenticated ? 'mock-id-token' : null;

  @override
  String? get userId => _currentUser?.username;

  @override
  String get redirectUri => 'http://localhost/callback';

  @override
  TenantConfig? get tenantConfig => null;

  @override
  dynamic get authService => null;

  @override
  Future<void> logout({LogoutReason reason = LogoutReason.userRequested}) async {
    logoutCalled = true;
    lastLogoutReasonParam = reason;
    _isAuthenticated = false;
    _currentUser = null;
    _lastLogoutReason = reason;
    _userStreamController.add(null);
  }

  @override
  Future<Map<String, String>> buildAuthorizationUrl() async {
    return {
      'url': 'https://auth.example.com/authorize',
      'state': 'mock-state',
    };
  }

  @override
  Future<bool> exchangeCodeForTokens(String code) async {
    if (code == 'valid-code') {
      _isAuthenticated = true;
      _currentUser = User(
        username: 'testuser',
        email: 'test@example.com',
        creationDate: DateTime.now(),
        lastUpdate: DateTime.now(),
      );
      _userStreamController.add(_currentUser);
      return true;
    }
    return false;
  }

  @override
  Future<bool> refreshTokens() async {
    refreshTokensCalled = true;
    return _isAuthenticated;
  }

  @override
  Future<void> fetchUserInfo() async {
    fetchUserInfoCalled = true;
  }

  @override
  Future<Map<String, String>?> getLogoutUrl() async {
    if (_isAuthenticated) {
      return {
        'url': 'https://auth.example.com/logout',
        'state': 'mock-logout-state',
      };
    }
    return null;
  }

  // Helper methods for testing
  void completeReady() {
    if (!_readyCompleter.isCompleted) {
      _readyCompleter.complete();
    }
  }

  void simulateUserLogin(User user) {
    _isAuthenticated = true;
    _currentUser = user;
    _userStreamController.add(user);
  }

  void simulateUserLogout() {
    _isAuthenticated = false;
    _currentUser = null;
    _userStreamController.add(null);
  }

  void dispose() {
    _userStreamController.close();
  }
}

void main() {
  group('AuthBloc', () {
    late _MockAuthRepository authRepository;

    setUp(() {
      authRepository = _MockAuthRepository();
    });

    tearDown(() {
      authRepository.dispose();
    });

    test('initial state is AuthInitial', () {
      final bloc = AuthBloc(authRepository);
      expect(bloc.state, const AuthInitial());
      bloc.close();
    });

    test('AuthStarted emits AuthAuthenticated when user is authenticated', () async {
      authRepository = _MockAuthRepository(
        isAuthenticated: true,
        currentUser: User(
          username: 'testuser',
          email: 'test@example.com',
          creationDate: DateTime.now(),
          lastUpdate: DateTime.now(),
        ),
      );

      final bloc = AuthBloc(authRepository);

      final future = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthAuthenticated>(),
        ]),
      );

      authRepository.completeReady();
      bloc.add(const AuthStarted());

      await future;
      await bloc.close();
    });

    test('AuthStarted emits AuthUnauthenticated when user is not authenticated', () async {
      authRepository = _MockAuthRepository(
        isAuthenticated: false,
        lastLogoutReason: LogoutReason.sessionExpired,
      );

      final bloc = AuthBloc(authRepository);

      final future = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthUnauthenticated>()
              .having((s) => s.reason, 'reason', LogoutReason.sessionExpired),
        ]),
      );

      authRepository.completeReady();
      bloc.add(const AuthStarted());

      await future;
      await bloc.close();
    });

    test('OAuthLoginRequested emits AuthLoading', () async {
      final bloc = AuthBloc(authRepository);

      final future = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
        ]),
      );

      bloc.add(const OAuthLoginRequested());

      await future;
      await bloc.close();
    });

    test('AuthCodeExchanged with success emits AuthAuthenticated', () async {
      authRepository = _MockAuthRepository(isAuthenticated: true);

      final bloc = AuthBloc(authRepository);

      final future = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthAuthenticated>(),
        ]),
      );

      bloc.add(const AuthCodeExchanged(success: true));

      await future;
      await bloc.close();
    });

    test('AuthCodeExchanged with failure emits AuthUnauthenticated', () async {
      authRepository = _MockAuthRepository(isAuthenticated: false);

      final bloc = AuthBloc(authRepository);

      final future = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthUnauthenticated>(),
        ]),
      );

      bloc.add(const AuthCodeExchanged(success: false));

      await future;
      await bloc.close();
    });

    test('LogoutRequested calls logout and emits AuthUnauthenticated', () async {
      authRepository = _MockAuthRepository(isAuthenticated: true);

      final bloc = AuthBloc(authRepository);

      final future = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthUnauthenticated>()
              .having((s) => s.reason, 'reason', LogoutReason.userRequested),
        ]),
      );

      bloc.add(const LogoutRequested(reason: LogoutReason.userRequested));

      await future;
      expect(authRepository.logoutCalled, true);
      expect(authRepository.lastLogoutReasonParam, LogoutReason.userRequested);
      await bloc.close();
    });

    test('LogoutRequested with custom reason emits correct reason', () async {
      authRepository = _MockAuthRepository(isAuthenticated: true);

      final bloc = AuthBloc(authRepository);

      final future = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthUnauthenticated>()
              .having((s) => s.reason, 'reason', LogoutReason.sessionExpired),
        ]),
      );

      bloc.add(const LogoutRequested(reason: LogoutReason.sessionExpired));

      await future;
      expect(authRepository.lastLogoutReasonParam, LogoutReason.sessionExpired);
      await bloc.close();
    });

    test('userStream login emits AuthAuthenticated', () async {
      final bloc = AuthBloc(authRepository);

      final future = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthAuthenticated>(),
        ]),
      );

      // Simulate user login via stream
      authRepository.simulateUserLogin(
        User(
          username: 'streamuser',
          email: 'stream@example.com',
          creationDate: DateTime.now(),
          lastUpdate: DateTime.now(),
        ),
      );

      await future;
      await bloc.close();
    });

    test('userStream logout emits AuthUnauthenticated', () async {
      authRepository = _MockAuthRepository(
        isAuthenticated: true,
        currentUser: User(
          username: 'user1',
          email: 'user1@example.com',
          creationDate: DateTime.now(),
          lastUpdate: DateTime.now(),
        ),
      );

      final bloc = AuthBloc(authRepository);

      final future = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthUnauthenticated>(),
        ]),
      );

      // Simulate user logout via stream
      authRepository.simulateUserLogout();

      await future;
      await bloc.close();
    });

    test('multiple state transitions work correctly', () async {
      final bloc = AuthBloc(authRepository);

      final future = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<AuthAuthenticated>(),
          isA<AuthUnauthenticated>(),
        ]),
      );

      // Start OAuth flow
      bloc.add(const OAuthLoginRequested());

      // Simulate successful login
      await Future.delayed(const Duration(milliseconds: 50));
      authRepository.simulateUserLogin(
        User(
          username: 'multiuser',
          email: 'multi@example.com',
          creationDate: DateTime.now(),
          lastUpdate: DateTime.now(),
        ),
      );

      // Simulate logout
      await Future.delayed(const Duration(milliseconds: 50));
      bloc.add(const LogoutRequested());

      await future;
      await bloc.close();
    });
  });
}
