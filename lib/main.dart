import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'config/router/app_router.dart';
import 'config/theme/app_theme.dart';
import 'features/presentarion/bloc/admin_cubit.dart';
import 'features/presentarion/bloc/auth_bloc.dart';
import 'features/presentarion/bloc/auth_event.dart';
import 'features/presentarion/bloc/auth_state.dart';
import 'features/presentarion/bloc/candidate_cubit.dart';
import 'features/presentarion/bloc/company_cubit.dart';
import 'features/presentarion/bloc/theme_cubit.dart';
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
        BlocProvider<ThemeCubit>(
          create: (_) => sl<ThemeCubit>(),
        ),
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

class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  GoRouter? _router;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            if (authState is AuthInitial || authState is AuthLoading) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                themeMode: themeMode,
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                home: const _SplashScreen(),
              );
            }
            _router ??= AppRouter.router(context);
            return MaterialApp.router(
              title: 'MatchIQ',
              debugShowCheckedModeBanner: false,
              themeMode: themeMode,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              routerConfig: _router!,
            );
          },
        );
      },
    );
  }
}

class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.6)),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2537),
      body: Center(
        child: FadeTransition(
          opacity: _opacity,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('lib/assets/logo_dark.jpeg', height: 90),
                const SizedBox(height: 32),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    color: Color(0xFF00C785),
                    strokeWidth: 2.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
