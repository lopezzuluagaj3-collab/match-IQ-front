import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/admin_stats.dart';
import '../../infrastructure/datasources/app_datasource.dart';

class AdminState extends Equatable {
  const AdminState({this.stats, this.isLoading = false, this.error});
  final AdminStats? stats;
  final bool isLoading;
  final String? error;

  AdminState copyWith({AdminStats? stats, bool? isLoading, String? error}) =>
      AdminState(
        stats: stats ?? this.stats,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );

  @override
  List<Object?> get props => [stats, isLoading, error];
}

class AdminCubit extends Cubit<AdminState> {
  AdminCubit(this._datasource) : super(const AdminState());

  final AppDatasource _datasource;

  Future<void> loadStats() async {
    emit(state.copyWith(isLoading: true));
    final result = await _datasource.getAdminStats();
    result.fold(
      (f) => emit(state.copyWith(isLoading: false, error: f.message)),
      (stats) => emit(state.copyWith(isLoading: false, stats: stats)),
    );
  }
}
