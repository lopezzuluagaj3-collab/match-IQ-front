import '../../../core/utils/typedef.dart';
import '../entities/user.dart';
import '../ports/input/auth_input_port.dart';
import '../ports/output/auth_output_port.dart';

class AuthDomainService implements AuthInputPort {
  AuthDomainService(this._outputPort);

  final AuthOutputPort _outputPort;

  @override
  User? get currentUser => _outputPort.currentUser;

  @override
  ResultFuture<User> login({required String email, required String password}) =>
      _outputPort.login(email: email, password: password);

  @override
  ResultFuture<User> loginWithGoogle({
    required String idToken,
    required String email,
    required UserRole role,
  }) =>
      _outputPort.loginWithGoogle(idToken: idToken, email: email, role: role);

  @override
  ResultVoid registerCandidate({
    required String name,
    required String email,
    required String cedula,
    required String password,
  }) =>
      _outputPort.registerCandidate(
          name: name, email: email, cedula: cedula, password: password);

  @override
  ResultVoid registerCompany({
    required String companyName,
    required String email,
    required String cedula,
    required String password,
  }) =>
      _outputPort.registerCompany(
          companyName: companyName,
          email: email,
          cedula: cedula,
          password: password);

  @override
  ResultVoid forgotPassword({required String email}) =>
      _outputPort.forgotPassword(email: email);

  @override
  ResultVoid changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) =>
      _outputPort.changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
          confirmPassword: confirmPassword);

  @override
  ResultVoid resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) =>
      _outputPort.resetPassword(
          token: token, newPassword: newPassword, confirmPassword: confirmPassword);

  @override
  ResultVoid verifyEmail({required String email, required String code}) =>
      _outputPort.verifyEmail(email: email, code: code);

  @override
  ResultVoid resendVerification({required String email}) =>
      _outputPort.resendVerification(email: email);

  @override
  ResultVoid logout() => _outputPort.logout();

  @override
  ResultFuture<User> checkSession() => _outputPort.checkSession();
}
