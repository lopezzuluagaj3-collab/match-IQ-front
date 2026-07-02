import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utils/typedef.dart';
import '../../domain/entities/user.dart';
import '../../domain/ports/output/auth_output_port.dart';
import '../datasources/app_datasource.dart';

class MockAuthAdapter implements AuthOutputPort {
  MockAuthAdapter(this._datasource);

  // ignore: unused_field
  final AppDatasource _datasource;
  User? _currentUser;

  @override
  User? get currentUser => _currentUser;

  @override
  ResultFuture<User> login({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    const mockUsers = {
      'candidate@test.com': User(
        id: 'candidate-001',
        email: 'candidate@test.com',
        name: 'Alex Reyes',
        role: UserRole.candidate,
      ),
      'company@test.com': User(
        id: 'company-001',
        email: 'company@test.com',
        name: 'Stellar AI',
        role: UserRole.company,
      ),
      'admin@test.com': User(
        id: 'admin-001',
        email: 'admin@test.com',
        name: 'Admin User',
        role: UserRole.admin,
      ),
    };

    final user = mockUsers[email];
    if (user != null && password == '123456') {
      _currentUser = user;
      return Right(user);
    }
    return const Left(AuthFailure(message: 'Invalid credentials', statusCode: 401));
  }

  @override
  ResultFuture<User> loginWithGoogle({
    required String idToken,
    required String email,
    required UserRole role,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final user = User(id: 'google-mock-001', email: email, name: email.split('@').first, role: role);
    _currentUser = user;
    return Right(user);
  }

  @override
  ResultVoid registerCandidate({
    required String name,
    required String email,
    required String cedula,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return const Right(null);
  }

  @override
  ResultVoid registerCompany({
    required String companyName,
    required String email,
    required String cedula,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return const Right(null);
  }

  @override
  ResultVoid changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return const Right(null);
  }

  @override
  ResultVoid forgotPassword({required String email}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return const Right(null);
  }

  @override
  ResultVoid resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return const Right(null);
  }

  @override
  ResultVoid verifyEmail({required String email, required String code}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return const Right(null);
  }

  @override
  ResultVoid resendVerification({required String email}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return const Right(null);
  }

  @override
  ResultVoid logout() async {
    _currentUser = null;
    return const Right(null);
  }

  @override
  ResultFuture<User> checkSession() async =>
      const Left(AuthFailure(message: 'No active session'));
}
