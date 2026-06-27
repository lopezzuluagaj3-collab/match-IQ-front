import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'config/router/app_router.dart';
import 'config/theme/app_theme.dart';
import 'features/presentarion/bloc/admin_cubit.dart';
import 'features/presentarion/bloc/auth_bloc.dart';
import 'features/presentarion/bloc/auth_event.dart';
import 'features/presentarion/bloc/auth_state.dart';
import 'features/presentarion/bloc/candidate_cubit.dart';
import 'features/presentarion/bloc/company_cubit.dart';
import 'injection/injection_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  runApp(const MatchIQApp());
}

class MatchIQApp extends StatelessWidget {
  const MatchIQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => sl<AuthBloc>()..add(const CheckSessionRequested()),
        ),
        BlocProvider<CandidateCubit>(create: (_) => sl<CandidateCubit>()),
        BlocProvider<CompanyCubit>(create: (_) => sl<CompanyCubit>()),
        BlocProvider<AdminCubit>(create: (_) => sl<AdminCubit>()),
      ],
      child: const _AppRoot(),
    );
  }
}

class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        // Show a neutral splash while the session check runs
        if (state is AuthInitial || state is AuthLoading) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: _SplashScreen(),
          );
        }
        final router = AppRouter.router(context);
        return MaterialApp.router(
          title: 'MatchIQ',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: router,
        );
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0F2537),
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFF4ADE80)),
      ),
    );
  }
}
