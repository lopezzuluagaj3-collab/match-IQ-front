import 'package:dartz/dartz.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/api/token_storage.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utils/typedef.dart';
import '../../domain/entities/user.dart';
import '../../domain/ports/output/auth_output_port.dart';

class RemoteAuthAdapter implements AuthOutputPort {
  RemoteAuthAdapter(this._client, this._storage);

  final ApiClient _client;
  final TokenStorage _storage;
  User? _currentUser;

  @override
  User? get currentUser => _currentUser;

  @override
  ResultFuture<User> login({
    required String email,
    required String password,
  }) async {
    final result = await _client.post(
      ApiConstants.login,
      body: {'email': email, 'password': password},
      skipAuth: true,
    );

    if (result.isLeft()) {
      return result.fold((f) => Left(f), (_) => throw StateError('unreachable'));
    }

    final data = result.getOrElse(() => null);
    if (data == null) {
      return const Left(ServerFailure(message: 'Respuesta vacía del servidor'));
    }

    final map = data as Map<String, dynamic>;
    final user = User(
      id: map['userId'].toString(),
      email: email,
      name: map['fullName'] as String,
      role: _parseRole(map['role'] as String),
    );

    // Tokens stored in memory immediately; persistent storage is best-effort
    await _storage.saveTokens(
      access: map['accessToken'] as String,
      refresh: map['refreshToken'] as String,
    );
    // Persist user info so we can restore the session on next launch
    await _storage.saveUser({
      'id': user.id,
      'email': user.email,
      'name': user.name,
      'role': user.role.name,
    });
    _currentUser = user;
    return Right(user);
  }

  /// Restores an existing session from storage without any network call.
  /// Returns Left if no valid token exists or the token is expired.
  @override
  ResultFuture<User> checkSession() async {
    final token = await _storage.getAccessToken();
    if (token == null || _storage.isTokenExpired(token)) {
      // Try to refresh
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) {
        return const Left(AuthFailure(message: 'Sin sesión activa'));
      }
      final refreshResult = await _client.post(
        ApiConstants.refresh,
        body: {'refreshToken': refreshToken},
        skipAuth: true,
      );
      if (refreshResult.isLeft()) {
        await _storage.clear();
        return const Left(AuthFailure(message: 'Sesión expirada'));
      }
      final refreshData = refreshResult.getOrElse(() => null) as Map<String, dynamic>?;
      if (refreshData == null) {
        await _storage.clear();
        return const Left(AuthFailure(message: 'Sesión expirada'));
      }
      await _storage.saveTokens(
        access: refreshData['accessToken'] as String,
        refresh: refreshData['refreshToken'] as String,
      );
    }

    final userMap = await _storage.getUser();
    if (userMap == null) {
      return const Left(AuthFailure(message: 'Sin datos de sesión'));
    }

    final user = User(
      id: userMap['id'] as String,
      email: userMap['email'] as String,
      name: userMap['name'] as String,
      role: _parseRole(userMap['role'] as String),
    );
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
    final result = await _client.post(
      ApiConstants.register,
      body: {
        'fullName': name,
        'email': email,
        'cedula': cedula,
        'password': password,
        'confirmPassword': password,
        'role': 'Candidate',
      },
      skipAuth: true,
    );
    return result.fold((f) => Left(f), (_) => const Right(null));
  }

  @override
  ResultVoid registerCompany({
    required String companyName,
    required String email,
    required String cedula,
    required String password,
  }) async {
    final result = await _client.post(
      ApiConstants.register,
      body: {
        'fullName': companyName,
        'email': email,
        'cedula': cedula,
        'password': password,
        'confirmPassword': password,
        'role': 'Company',
      },
      skipAuth: true,
    );
    return result.fold((f) => Left(f), (_) => const Right(null));
  }

  @override
  ResultVoid forgotPassword({required String email}) async {
    final result = await _client.post(
      ApiConstants.forgotPassword,
      body: {'email': email},
      skipAuth: true,
    );
    return result.fold((f) => Left(f), (_) => const Right(null));
  }

  @override
  ResultVoid resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final result = await _client.post(
      ApiConstants.resetPassword,
      body: {
        'token': token,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
      skipAuth: true,
    );
    return result.fold((f) => Left(f), (_) => const Right(null));
  }

  @override
  ResultVoid verifyEmail({required String email, required String code}) async {
    final result = await _client.post(
      ApiConstants.verifyEmail,
      body: {'email': email, 'code': code},
      skipAuth: true,
    );
    return result.fold((f) => Left(f), (_) => const Right(null));
  }

  @override
  ResultVoid resendVerification({required String email}) async {
    final result = await _client.post(
      ApiConstants.resendVerification,
      body: {'email': email},
      skipAuth: true,
    );
    return result.fold((f) => Left(f), (_) => const Right(null));
  }

  @override
  ResultVoid logout() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken != null) {
      await _client.post(
        ApiConstants.logout,
        body: {'refreshToken': refreshToken},
      );
    }
    await _storage.clear();
    _currentUser = null;
    return const Right(null);
  }

  UserRole _parseRole(String role) => switch (role.toLowerCase()) {
        'candidate' => UserRole.candidate,
        'company' => UserRole.company,
        'admin' => UserRole.admin,
        _ => UserRole.candidate,
      };
}
