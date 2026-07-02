import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  const LoginRequested({required this.email, required this.password});
  final String email;
  final String password;
  @override
  List<Object?> get props => [email, password];
}

class GoogleLoginRequested extends AuthEvent {
  const GoogleLoginRequested({
    required this.idToken,
    required this.email,
    required this.role,
  });
  final String idToken;
  final String email;
  final UserRole role;
  @override
  List<Object?> get props => [idToken, email, role];
}

class RegisterCandidateRequested extends AuthEvent {
  const RegisterCandidateRequested({
    required this.name,
    required this.email,
    required this.cedula,
    required this.password,
  });
  final String name;
  final String email;
  final String cedula;
  final String password;
  @override
  List<Object?> get props => [name, email, cedula, password];
}

class RegisterCompanyRequested extends AuthEvent {
  const RegisterCompanyRequested({
    required this.companyName,
    required this.email,
    required this.cedula,
    required this.password,
  });
  final String companyName;
  final String email;
  final String cedula;
  final String password;
  @override
  List<Object?> get props => [companyName, email, cedula, password];
}

class ForgotPasswordRequested extends AuthEvent {
  const ForgotPasswordRequested({required this.email});
  final String email;
  @override
  List<Object?> get props => [email];
}

class ResetPasswordRequested extends AuthEvent {
  const ResetPasswordRequested({
    required this.token,
    required this.newPassword,
    required this.confirmPassword,
  });
  final String token;
  final String newPassword;
  final String confirmPassword;
  @override
  List<Object?> get props => [token, newPassword, confirmPassword];
}

class VerifyEmailRequested extends AuthEvent {
  const VerifyEmailRequested({required this.email, required this.code});
  final String email;
  final String code;
  @override
  List<Object?> get props => [email, code];
}

class ResendVerificationRequested extends AuthEvent {
  const ResendVerificationRequested({required this.email});
  final String email;
  @override
  List<Object?> get props => [email];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

class CheckSessionRequested extends AuthEvent {
  const CheckSessionRequested();
}
