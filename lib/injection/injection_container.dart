import 'package:get_it/get_it.dart';
import '../core/api/api_client.dart';
import '../core/api/token_storage.dart';
import '../features/domain/ports/input/auth_input_port.dart';
import '../features/domain/ports/output/auth_output_port.dart';
import '../features/domain/services/auth_domain_service.dart';
import '../features/infrastructure/adapters/mock_auth_adapter.dart';
import '../features/infrastructure/adapters/remote_auth_adapter.dart';
import '../features/infrastructure/datasources/app_datasource.dart';
import '../features/infrastructure/datasources/mock_datasource.dart';
import '../features/infrastructure/datasources/remote_datasource.dart';
import '../features/presentarion/bloc/admin_cubit.dart';
import '../features/presentarion/bloc/auth_bloc.dart';
import '../features/presentarion/bloc/candidate_cubit.dart';
import '../features/presentarion/bloc/company_cubit.dart';
import '../features/presentarion/bloc/test_cubit.dart';
import '../features/presentarion/bloc/theme_cubit.dart';

final sl = GetIt.instance;

// Cambiar a false cuando el backend esté disponible en localhost:5000
const bool kUseMock = true;

Future<void> initDependencies() async {
  // Core — API infrastructure
  sl.registerLazySingleton<TokenStorage>(() => TokenStorage());
  sl.registerLazySingleton<ApiClient>(() => ApiClient(sl<TokenStorage>()));

  // Datasource
  sl.registerLazySingleton<AppDatasource>(
    () => kUseMock
        ? MockDatasource()
        : RemoteDatasource(sl<ApiClient>(), sl<TokenStorage>()),
  );

  // Auth adapter
  sl.registerLazySingleton<AuthOutputPort>(
    () => kUseMock
        ? MockAuthAdapter(sl<AppDatasource>())
        : RemoteAuthAdapter(sl<ApiClient>(), sl<TokenStorage>()),
  );

  // Domain services
  sl.registerLazySingleton<AuthInputPort>(
    () => AuthDomainService(sl<AuthOutputPort>()),
  );

  // Theme — singleton so the selected mode persists while the app runs
  sl.registerLazySingleton<ThemeCubit>(() => ThemeCubit());

  // BLoCs / Cubits — factory so each rebuild gets a fresh instance
  sl.registerFactory<AuthBloc>(() => AuthBloc(sl<AuthInputPort>()));
  sl.registerFactory<CandidateCubit>(() => CandidateCubit(sl<AppDatasource>()));
  sl.registerFactory<CompanyCubit>(() => CompanyCubit(sl<AppDatasource>()));
  sl.registerFactory<AdminCubit>(() => AdminCubit(sl<AppDatasource>()));
  sl.registerFactory<TestCubit>(() => TestCubit(sl<AppDatasource>()));
}
