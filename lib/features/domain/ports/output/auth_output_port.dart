import '../../../../core/utils/typedef.dart';
import '../../entities/user.dart';

abstract class AuthOutputPort {
  ResultFuture<User> login({required String email, required String password});
  ResultVoid registerCandidate({
    required String name,
    required String email,
    required String cedula,
    required String password,
  });
  ResultVoid registerCompany({
    required String companyName,
    required String email,
    required String cedula,
    required String password,
  });
  ResultVoid forgotPassword({required String email});
  ResultVoid changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  });
  ResultVoid resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  });
  ResultVoid verifyEmail({required String email, required String code});
  ResultVoid resendVerification({required String email});
  ResultVoid logout();
  ResultFuture<User> checkSession();
  User? get currentUser;
}
