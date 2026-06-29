import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/web/download_helper.dart';
import '../../domain/entities/admin_stats.dart';
import '../../domain/entities/admin_user.dart';
import '../../infrastructure/datasources/app_datasource.dart';

class AdminState extends Equatable {
  const AdminState({
    this.stats,
    this.users = const [],
    this.roleFilter,
    this.activeFilter,
    this.isLoading = false,
    this.isLoadingUsers = false,
    this.isSaving = false,
    this.isDownloadingReport = false,
    this.error,
    this.successMessage,
  });

  final AdminStats? stats;
  final List<AdminUser> users;
  final String? roleFilter;
  final bool? activeFilter;
  final bool isLoading;
  final bool isLoadingUsers;
  final bool isSaving;
  final bool isDownloadingReport;
  final String? error;
  final String? successMessage;

  AdminState copyWith({
    AdminStats? stats,
    List<AdminUser>? users,
    String? roleFilter,
    bool clearRoleFilter = false,
    bool? activeFilter,
    bool clearActiveFilter = false,
    bool? isLoading,
    bool? isLoadingUsers,
    bool? isSaving,
    bool? isDownloadingReport,
    String? error,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
  }) =>
      AdminState(
        stats: stats ?? this.stats,
        users: users ?? this.users,
        roleFilter: clearRoleFilter ? null : (roleFilter ?? this.roleFilter),
        activeFilter:
            clearActiveFilter ? null : (activeFilter ?? this.activeFilter),
        isLoading: isLoading ?? this.isLoading,
        isLoadingUsers: isLoadingUsers ?? this.isLoadingUsers,
        isSaving: isSaving ?? this.isSaving,
        isDownloadingReport: isDownloadingReport ?? this.isDownloadingReport,
        error: clearError ? null : (error ?? this.error),
        successMessage:
            clearSuccess ? null : (successMessage ?? this.successMessage),
      );

  @override
  List<Object?> get props => [
        stats, users, roleFilter, activeFilter,
        isLoading, isLoadingUsers, isSaving, isDownloadingReport,
        error, successMessage,
      ];
}

class AdminCubit extends Cubit<AdminState> {
  AdminCubit(this._datasource) : super(const AdminState());

  final AppDatasource _datasource;

  Future<void> loadStats() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    final result = await _datasource.getAdminStats();
    result.fold(
      (f) => emit(state.copyWith(isLoading: false, error: f.message)),
      (stats) => emit(state.copyWith(isLoading: false, stats: stats)),
    );
  }

  Future<void> loadUsers({String? role, bool? isActive}) async {
    emit(state.copyWith(
      isLoadingUsers: true,
      clearError: true,
      clearSuccess: true,
      roleFilter: role,
      clearRoleFilter: role == null,
      activeFilter: isActive,
      clearActiveFilter: isActive == null,
    ));
    final result =
        await _datasource.getAdminUsers(role: role, isActive: isActive);
    result.fold(
      (f) => emit(state.copyWith(isLoadingUsers: false, error: f.message)),
      (users) => emit(state.copyWith(isLoadingUsers: false, users: users)),
    );
  }

  Future<void> toggleUserStatus(int userId) async {
    emit(state.copyWith(isSaving: true, clearError: true, clearSuccess: true));
    final result = await _datasource.toggleUserStatus(userId);
    result.fold(
      (f) => emit(state.copyWith(isSaving: false, error: f.message)),
      (updated) {
        final newUsers = state.users
            .map((u) => u.id == userId ? updated : u)
            .toList();
        final msg = updated.isActive ? 'Cuenta activada.' : 'Cuenta desactivada.';
        emit(state.copyWith(
            isSaving: false, users: newUsers, successMessage: msg));
      },
    );
  }

  Future<void> deleteUser(int userId) async {
    emit(state.copyWith(isSaving: true, clearError: true, clearSuccess: true));
    final result = await _datasource.deleteUser(userId);
    result.fold(
      (f) => emit(state.copyWith(isSaving: false, error: f.message)),
      (_) {
        final newUsers = state.users.where((u) => u.id != userId).toList();
        emit(state.copyWith(
            isSaving: false,
            users: newUsers,
            successMessage: 'Usuario eliminado.'));
      },
    );
  }

  Future<void> downloadReport() async {
    emit(state.copyWith(isDownloadingReport: true, clearError: true));
    final result = await _datasource.downloadAdminReport();
    result.fold(
      (f) => emit(state.copyWith(isDownloadingReport: false, error: f.message)),
      (bytes) {
        if (bytes.isNotEmpty) {
          triggerFileDownload(bytes, 'reporte-admin.xlsx');
        }
        emit(state.copyWith(isDownloadingReport: false));
      },
    );
  }

  Future<bool> createAdminUser({
    required String fullName,
    required String email,
    required String cedula,
    required String password,
    required String confirmPassword,
  }) async {
    emit(state.copyWith(isSaving: true, clearError: true, clearSuccess: true));
    final result = await _datasource.createAdminUser(
      fullName: fullName,
      email: email,
      cedula: cedula,
      password: password,
      confirmPassword: confirmPassword,
    );
    return result.fold(
      (f) {
        emit(state.copyWith(isSaving: false, error: f.message));
        return false;
      },
      (_) {
        emit(state.copyWith(
            isSaving: false,
            successMessage: 'Administrador creado correctamente.'));
        loadUsers(
            role: state.roleFilter, isActive: state.activeFilter);
        return true;
      },
    );
  }
}
