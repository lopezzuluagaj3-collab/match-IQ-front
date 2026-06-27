import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final User user;
  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthFailureState extends AuthState {
  const AuthFailureState(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class AuthPasswordResetSent extends AuthState {
  const AuthPasswordResetSent();
}

// Emitted after successful registration — user must verify email before login
class AuthPendingVerification extends AuthState {
  const AuthPendingVerification(this.email);
  final String email;
  @override
  List<Object?> get props => [email];
}

// Emitted after successful email verification
class AuthEmailVerified extends AuthState {
  const AuthEmailVerified();
}
