part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {
  const AuthStarted();
}

class OAuthLoginRequested extends AuthEvent {
  const OAuthLoginRequested();
}

class AuthCodeExchanged extends AuthEvent {
  const AuthCodeExchanged({required this.success});
  final bool success;

  @override
  List<Object?> get props => [success];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested({this.reason = LogoutReason.userRequested});
  final LogoutReason reason;

  @override
  List<Object?> get props => [reason];
}

/// Internal event triggered when the user authentication state changes
class _AuthUserChanged extends AuthEvent {
  const _AuthUserChanged(this.user);
  final dynamic user;

  @override
  List<Object?> get props => [user];
}
