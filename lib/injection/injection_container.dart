import 'package:get_it/get_it.dart';
import '../core/api/api_client.dart';
import '../core/api/proctoring_api_client.dart';
import '../core/api/token_storage.dart';
import '../features/domain/ports/input/auth_input_port.dart';
import '../features/domain/ports/output/auth_output_port.dart';
import '../features/domain/services/auth_domain_service.dart';
import '../features/infrastructure/adapters/remote_auth_adapter.dart';
import '../features/infrastructure/datasources/app_datasource.dart';
import '../features/infrastructure/datasources/proctor_datasource.dart';
import '../features/infrastructure/datasources/remote_datasource.dart';
import '../features/presentarion/bloc/admin_cubit.dart';
import '../features/presentarion/bloc/analytics_cubit.dart';
import '../features/presentarion/bloc/auth_bloc.dart';
import '../features/presentarion/bloc/candidate_cubit.dart';
import '../features/presentarion/bloc/company_cubit.dart';
import '../features/presentarion/bloc/proctor_cubit.dart';
import '../features/presentarion/bloc/test_cubit.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // Core — API infrastructure
  sl.registerLazySingleton<TokenStorage>(() => TokenStorage());
  sl.registerLazySingleton<ApiClient>(() => ApiClient(sl<TokenStorage>()));

  // Datasource
  sl.registerLazySingleton<AppDatasource>(
    () => RemoteDatasource(sl<ApiClient>(), sl<TokenStorage>()),
  );

  // Auth adapter
  sl.registerLazySingleton<AuthOutputPort>(
    () => RemoteAuthAdapter(sl<ApiClient>(), sl<TokenStorage>()),
  );

  // Domain services
  sl.registerLazySingleton<AuthInputPort>(
    () => AuthDomainService(sl<AuthOutputPort>()),
  );

  // BLoCs / Cubits — factory so each rebuild gets a fresh instance
  sl.registerFactory<AuthBloc>(() => AuthBloc(sl<AuthInputPort>()));
  sl.registerFactory<CandidateCubit>(() => CandidateCubit(sl<AppDatasource>()));
  sl.registerFactory<CompanyCubit>(() => CompanyCubit(sl<AppDatasource>()));
  sl.registerFactory<AdminCubit>(() => AdminCubit(sl<AppDatasource>()));
  sl.registerFactory<TestCubit>(() => TestCubit(sl<AppDatasource>()));
  sl.registerFactory<AnalyticsCubit>(() => AnalyticsCubit(sl<AppDatasource>()));

  // Proctoring — separate AI service at bank-user.coderhivex.com
  sl.registerLazySingleton<ProctoringApiClient>(() => ProctoringApiClient());
  sl.registerLazySingleton<ProctoringDatasource>(
    () => RemoteProctoringDatasource(sl<ProctoringApiClient>()),
  );
  sl.registerFactory<ProctorCubit>(() => ProctorCubit(sl<ProctoringDatasource>()));
}
