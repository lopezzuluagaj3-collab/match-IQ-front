import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
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
  usePathUrlStrategy();
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

class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  final _authNotifier = _AuthNotifier();
  GoRouter? _router;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _router ??= AppRouter.router(context, refreshListenable: _authNotifier);
  }

  @override
  void dispose() {
    _authNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (_, __) => _authNotifier.notify(),
      child: MaterialApp.router(
        title: 'MatchIQ',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router!,
      ),
    );
  }
}

class _AuthNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}
