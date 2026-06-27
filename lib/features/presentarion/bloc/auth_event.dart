import 'package:equatable/equatable.dart';

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
