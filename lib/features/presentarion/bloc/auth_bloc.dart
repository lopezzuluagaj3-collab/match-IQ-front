import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/ports/input/auth_input_port.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._authPort) : super(const AuthInitial()) {
    on<CheckSessionRequested>(_onCheckSession);
    on<LoginRequested>(_onLogin);
    on<RegisterCandidateRequested>(_onRegisterCandidate);
    on<RegisterCompanyRequested>(_onRegisterCompany);
    on<ForgotPasswordRequested>(_onForgotPassword);
    on<VerifyEmailRequested>(_onVerifyEmail);
    on<ResendVerificationRequested>(_onResendVerification);
    on<LogoutRequested>(_onLogout);
  }

  final AuthInputPort _authPort;

  // Stored in memory only to support auto-login after email verification
  String? _pendingEmail;
  String? _pendingPassword;

  Future<void> _onCheckSession(
    CheckSessionRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _authPort.checkSession();
    result.fold(
      (_) => emit(const AuthUnauthenticated()),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onLogin(LoginRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result =
        await _authPort.login(email: event.email, password: event.password);
    result.fold(
      (failure) {
        if (failure.message.contains('verificar tu email')) {
          emit(AuthPendingVerification(event.email));
        } else {
          emit(AuthFailureState(failure.message));
        }
      },
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onRegisterCandidate(
    RegisterCandidateRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    _pendingEmail = event.email;
    _pendingPassword = event.password;
    final result = await _authPort.registerCandidate(
      name: event.name,
      email: event.email,
      cedula: event.cedula,
      password: event.password,
    );
    result.fold(
      (failure) {
        _pendingEmail = null;
        _pendingPassword = null;
        emit(AuthFailureState(failure.message));
      },
      (_) => emit(AuthPendingVerification(event.email)),
    );
  }

  Future<void> _onRegisterCompany(
    RegisterCompanyRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    _pendingEmail = event.email;
    _pendingPassword = event.password;
    final result = await _authPort.registerCompany(
      companyName: event.companyName,
      email: event.email,
      cedula: event.cedula,
      password: event.password,
    );
    result.fold(
      (failure) {
        _pendingEmail = null;
        _pendingPassword = null;
        emit(AuthFailureState(failure.message));
      },
      (_) => emit(AuthPendingVerification(event.email)),
    );
  }

  Future<void> _onForgotPassword(
    ForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _authPort.forgotPassword(email: event.email);
    result.fold(
      (failure) => emit(AuthFailureState(failure.message)),
      (_) => emit(const AuthPasswordResetSent()),
    );
  }

  Future<void> _onVerifyEmail(
    VerifyEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result =
        await _authPort.verifyEmail(email: event.email, code: event.code);
    await result.fold(
      (failure) async => emit(AuthFailureState(failure.message)),
      (_) async {
        if (_pendingEmail != null && _pendingPassword != null) {
          // Auto-login with the credentials stored during registration
          final loginResult = await _authPort.login(
            email: _pendingEmail!,
            password: _pendingPassword!,
          );
          _pendingEmail = null;
          _pendingPassword = null;
          loginResult.fold(
            (f) => emit(AuthFailureState(f.message)),
            (user) => emit(AuthAuthenticated(user)),
          );
        } else {
          emit(const AuthEmailVerified());
        }
      },
    );
  }

  Future<void> _onResendVerification(
    ResendVerificationRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _authPort.resendVerification(email: event.email);
    result.fold(
      (failure) => emit(AuthFailureState(failure.message)),
      (_) => emit(AuthPendingVerification(event.email)),
    );
  }

  Future<void> _onLogout(LogoutRequested event, Emitter<AuthState> emit) async {
    _pendingEmail = null;
    _pendingPassword = null;
    await _authPort.logout();
    emit(const AuthUnauthenticated());
  }
}
