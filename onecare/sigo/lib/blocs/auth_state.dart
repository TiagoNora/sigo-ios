part of 'auth_bloc.dart';

@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = AuthInitial;
  const factory AuthState.loading() = AuthLoading;
  const factory AuthState.authenticated() = AuthAuthenticated;
  const factory AuthState.unauthenticated({
    @Default(LogoutReason.userRequested) LogoutReason reason,
  }) = AuthUnauthenticated;
  const factory AuthState.failure(String message) = AuthFailure;
}
