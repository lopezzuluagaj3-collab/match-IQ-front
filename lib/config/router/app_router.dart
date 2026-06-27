import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/domain/entities/user.dart';
import '../../features/presentarion/bloc/auth_bloc.dart';
import '../../features/presentarion/bloc/auth_state.dart';
import '../../features/presentarion/bloc/test_cubit.dart';
import '../../features/presentarion/pages/active_technical_test_page.dart';
import '../../features/presentarion/pages/admin_dashboard_page.dart';
import '../../features/presentarion/pages/auth_utility_page.dart';
import '../../features/presentarion/pages/candidate_dashboard_page.dart';
import '../../features/presentarion/pages/candidate_profile_page.dart';
import '../../features/presentarion/pages/candidate_registration_page.dart';
import '../../features/presentarion/pages/company_dashboard_page.dart';
import '../../features/presentarion/pages/company_matches_ranking_page.dart';
import '../../features/presentarion/pages/company_profile_settings_page.dart';
import '../../features/presentarion/pages/company_registration_page.dart';
import '../../features/presentarion/pages/create_new_offer_page.dart';
import '../../features/presentarion/pages/forgot_password_page.dart';
import '../../features/presentarion/pages/job_offers_list_page.dart';
import '../../features/presentarion/pages/landing_page.dart';
import '../../features/presentarion/pages/login_page.dart';
import '../../injection/injection_container.dart';
import 'app_routes.dart';

class AppRouter {
  static GoRouter router(BuildContext context) => GoRouter(
        initialLocation: AppRoutes.landing,
        debugLogDiagnostics: true,
        redirect: (ctx, state) {
          final authState = ctx.read<AuthBloc>().state;
          final path = state.uri.path;

          const publicRoutes = [
            AppRoutes.landing,
            AppRoutes.login,
            AppRoutes.forgotPassword,
            AppRoutes.authUtility,
            AppRoutes.registerCandidate,
            AppRoutes.registerCompany,
          ];

          final isPublic = publicRoutes.contains(path);

          if (authState is AuthAuthenticated && isPublic) {
            return switch (authState.user.role) {
              UserRole.candidate => AppRoutes.candidateAssessments,
              UserRole.company => AppRoutes.companyDashboard,
              UserRole.admin => AppRoutes.adminDashboard,
            };
          }

          if (authState is! AuthAuthenticated && !isPublic) return AppRoutes.login;

          return null;
        },
        routes: [
          GoRoute(
            path: AppRoutes.landing,
            pageBuilder: (_, __) => _fade(const LandingPage()),
          ),
          GoRoute(
            path: AppRoutes.login,
            pageBuilder: (_, __) => _fade(const LoginPage()),
          ),
          GoRoute(
            path: AppRoutes.forgotPassword,
            pageBuilder: (_, __) => _fade(const ForgotPasswordPage()),
          ),
          GoRoute(
            path: AppRoutes.authUtility,
            pageBuilder: (_, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return _fade(AuthUtilityPage(
                mode: extra?['mode'] as String? ?? 'password_reset',
                email: extra?['email'] as String?,
              ));
            },
          ),
          GoRoute(
            path: AppRoutes.registerCandidate,
            pageBuilder: (_, __) => _fade(const CandidateRegistrationPage()),
          ),
          GoRoute(
            path: AppRoutes.registerCompany,
            pageBuilder: (_, __) => _fade(const CompanyRegistrationPage()),
          ),

          // Candidate
          GoRoute(
            path: AppRoutes.candidateDashboard,
            pageBuilder: (_, __) => _slide(const CandidateDashboardPage()),
          ),
          GoRoute(
            path: AppRoutes.candidateProfile,
            pageBuilder: (_, __) => _slide(const CandidateProfilePage()),
          ),
          GoRoute(
            path: AppRoutes.candidateAssessments,
            pageBuilder: (_, __) => _slide(
              const JobOffersListPage(mode: JobOffersMode.assessments),
            ),
          ),
          GoRoute(
            path: AppRoutes.technicalTest,
            pageBuilder: (_, state) => _slide(
              BlocProvider(
                create: (_) => sl<TestCubit>(),
                child: ActiveTechnicalTestPage(
                  offerId: state.pathParameters['id'] ?? '',
                ),
              ),
            ),
          ),

          // Company
          GoRoute(
            path: AppRoutes.companyDashboard,
            pageBuilder: (_, __) => _slide(const CompanyDashboardPage()),
          ),
          GoRoute(
            path: AppRoutes.companySettings,
            pageBuilder: (_, __) => _slide(const CompanyProfileSettingsPage()),
          ),
          GoRoute(
            path: AppRoutes.companyMatches,
            pageBuilder: (_, __) => _slide(const CompanyMatchesRankingPage()),
          ),
          GoRoute(
            path: AppRoutes.createOffer,
            pageBuilder: (_, __) => _slide(const CreateNewOfferPage()),
          ),

          // Admin
          GoRoute(
            path: AppRoutes.adminDashboard,
            pageBuilder: (_, __) => _slide(const AdminDashboardPage()),
          ),
        ],
      );

  // Fade — for public/auth pages
  static CustomTransitionPage<void> _fade(Widget child) =>
      CustomTransitionPage<void>(
        child: child,
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
          child: child,
        ),
      );

  // Fade + slight upward slide — for authenticated dashboard pages
  static CustomTransitionPage<void> _slide(Widget child) =>
      CustomTransitionPage<void>(
        child: child,
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        transitionsBuilder: (_, animation, __, child) {
          final fade = CurvedAnimation(parent: animation, curve: Curves.easeIn);
          final slide = Tween<Offset>(
            begin: const Offset(0.0, 0.025),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOut),
          );
          return FadeTransition(
            opacity: fade,
            child: SlideTransition(position: slide, child: child),
          );
        },
      );
}
