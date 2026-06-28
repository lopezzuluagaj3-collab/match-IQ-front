import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/domain/entities/user.dart';
import '../../features/presentarion/bloc/auth_bloc.dart';
import '../../features/presentarion/bloc/auth_state.dart';
import '../../features/presentarion/bloc/proctor_cubit.dart';
import '../../features/presentarion/bloc/test_cubit.dart';
import '../../features/presentarion/pages/active_technical_test_page.dart';
import '../../features/presentarion/pages/admin_dashboard_page.dart';
import '../../features/presentarion/pages/admin_users_page.dart';
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
import '../../features/presentarion/pages/match_test_results_page.dart';
import '../../features/presentarion/pages/offer_matches_page.dart';
import '../../features/presentarion/pages/offer_pending_page.dart';
import '../../features/presentarion/pages/payment_result_page.dart';
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
          final isAuth = authState is AuthAuthenticated;
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

          // Redirect authenticated users away from login/register
          if (isAuth && isPublic) {
            final user = (authState as AuthAuthenticated).user; // isAuth guarantees this cast
            return switch (user.role) {
              UserRole.candidate => AppRoutes.candidateAssessments,
              UserRole.company => AppRoutes.companyDashboard,
              UserRole.admin => AppRoutes.adminDashboard,
            };
          }

          // Redirect unauthenticated users to login
          if (!isAuth && !isPublic) return AppRoutes.login;

          return null;
        },
        routes: [
          GoRoute(path: AppRoutes.landing, builder: (_, __) => const LandingPage()),
          GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginPage()),
          GoRoute(
            path: AppRoutes.forgotPassword,
            builder: (_, __) => const ForgotPasswordPage(),
          ),
          GoRoute(
            path: AppRoutes.authUtility,
            builder: (_, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return AuthUtilityPage(
                mode: extra?['mode'] as String? ?? 'password_reset',
                email: extra?['email'] as String?,
              );
            },
          ),
          GoRoute(
            path: AppRoutes.registerCandidate,
            builder: (_, __) => const CandidateRegistrationPage(),
          ),
          GoRoute(
            path: AppRoutes.registerCompany,
            builder: (_, __) => const CompanyRegistrationPage(),
          ),

          // Candidate
          GoRoute(
            path: AppRoutes.candidateDashboard,
            builder: (_, __) => const CandidateDashboardPage(),
          ),
          GoRoute(
            path: AppRoutes.candidateProfile,
            builder: (_, __) => const CandidateProfilePage(),
          ),
          GoRoute(
            path: AppRoutes.candidateAssessments,
            builder: (_, __) => const JobOffersListPage(mode: JobOffersMode.assessments),
          ),
          GoRoute(
            path: AppRoutes.technicalTest,
            builder: (_, state) => MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => sl<TestCubit>()),
                BlocProvider(create: (_) => sl<ProctorCubit>()),
              ],
              child: ActiveTechnicalTestPage(
                  offerId: state.pathParameters['id'] ?? ''),
            ),
          ),

          // Company
          GoRoute(
            path: AppRoutes.companyDashboard,
            builder: (_, __) => const CompanyDashboardPage(),
          ),
          GoRoute(
            path: AppRoutes.companySettings,
            builder: (_, __) => const CompanyProfileSettingsPage(),
          ),
          GoRoute(
            path: AppRoutes.companyMatches,
            builder: (_, __) => const CompanyMatchesRankingPage(),
          ),
          GoRoute(
            path: AppRoutes.createOffer,
            builder: (_, __) => const CreateNewOfferPage(),
          ),
          GoRoute(
            path: AppRoutes.offerPending,
            builder: (_, state) {
              final id = int.parse(state.pathParameters['id'] ?? '0');
              return OfferPendingPage(offerId: id);
            },
          ),
          GoRoute(
            path: AppRoutes.offerMatches,
            builder: (_, state) {
              final id = int.parse(state.pathParameters['id'] ?? '0');
              return OfferMatchesPage(offerId: id);
            },
          ),
          GoRoute(
            path: AppRoutes.matchTestResults,
            builder: (_, state) {
              final matchId =
                  int.parse(state.pathParameters['matchId'] ?? '0');
              return MatchTestResultsPage(matchId: matchId);
            },
          ),

          // Payment return URLs
          GoRoute(
            path: AppRoutes.paymentSuccess,
            builder: (_, state) {
              final offerId = int.tryParse(state.uri.queryParameters['offerId'] ?? '');
              return PaymentResultPage(success: true, offerId: offerId);
            },
          ),
          GoRoute(
            path: AppRoutes.paymentCancel,
            builder: (_, state) {
              final offerId = int.tryParse(state.uri.queryParameters['offerId'] ?? '');
              return PaymentResultPage(success: false, offerId: offerId);
            },
          ),

          // Admin
          GoRoute(
            path: AppRoutes.adminDashboard,
            builder: (_, __) => const AdminDashboardPage(),
          ),
          GoRoute(
            path: AppRoutes.adminUsers,
            builder: (_, __) => const AdminUsersPage(),
          ),
        ],
      );
}
