import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../config/router/app_routes.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../domain/entities/user.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key, required this.currentRoute, required this.role});

  final String currentRoute;
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 256,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.navyGradient,
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(4, 0))],
      ),
      child: Column(
        children: [
          _SidebarHeader(role: role),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: _navItems(context),
            ),
          ),
          _SidebarFooter(role: role),
        ],
      ),
    );
  }

  List<Widget> _navItems(BuildContext context) {
    final items = switch (role) {
      UserRole.candidate => [
          _NavItem(icon: Symbols.assignment, label: 'Assessments', route: AppRoutes.candidateAssessments),
          _NavItem(icon: Symbols.insights, label: 'Market Insights', route: AppRoutes.candidateInsights),
          _NavItem(icon: Symbols.person, label: 'Profile', route: AppRoutes.candidateProfile),
        ],
      UserRole.company => [
          _NavItem(icon: Symbols.dashboard, label: 'Overview', route: AppRoutes.companyDashboard),
          _NavItem(icon: Symbols.work, label: 'Offers', route: AppRoutes.companyMatches),
          _NavItem(icon: Symbols.settings, label: 'Settings', route: AppRoutes.companySettings),
        ],
      UserRole.admin => [
          _NavItem(icon: Symbols.dashboard, label: 'Overview', route: AppRoutes.adminDashboard),
          _NavItem(icon: Symbols.group, label: 'Usuarios', route: AppRoutes.adminUsers),
        ],
    };

    return items.map((item) => _SideNavItem(item: item, isActive: currentRoute == item.route)).toList();
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({required this.role});
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final subtitle = switch (role) {
      UserRole.candidate => 'Candidate Portal',
      UserRole.company => 'Company Console',
      UserRole.admin => 'Admin Console',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
      child: Row(
        children: [
          Image.asset('assets/images/logo.jpeg', height: 36, fit: BoxFit.contain),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subtitle, style: AppTextStyles.labelSm.copyWith(color: AppColors.onPrimaryContainer, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.icon, required this.label, required this.route});
  final IconData icon;
  final String label;
  final String route;
}

class _SideNavItem extends StatelessWidget {
  const _SideNavItem({required this.item, required this.isActive});
  final _NavItem item;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(item.route),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 1),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryContainer.withValues(alpha: 0.5) : Colors.transparent,
          border: isActive
              ? const Border(left: BorderSide(color: AppColors.onTertiaryContainer, width: 4))
              : null,
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(isActive ? 16 : 20, 12, 20, 12),
          child: Row(
            children: [
              Icon(item.icon, color: isActive ? AppColors.onTertiaryContainer : AppColors.onPrimaryContainer, size: 22),
              const SizedBox(width: 12),
              Text(
                item.label,
                style: AppTextStyles.labelBold.copyWith(
                  color: isActive ? AppColors.onTertiaryContainer : AppColors.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarFooter extends StatefulWidget {
  const _SidebarFooter({required this.role});
  final UserRole role;

  @override
  State<_SidebarFooter> createState() => _SidebarFooterState();
}

class _SidebarFooterState extends State<_SidebarFooter> {
  bool _isLoggingOut = false;

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) context.read<AuthBloc>().add(const LogoutRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (widget.role == UserRole.company)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                gradient: AppColors.emeraldGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                onPressed: () => context.go(AppRoutes.createOffer),
                child: Text('+ Post New Offer', style: AppTextStyles.labelBold.copyWith(color: Colors.white)),
              ),
            ),
          GestureDetector(
            onTap: _isLoggingOut ? null : _handleLogout,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: _isLoggingOut
                    ? AppColors.error.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _isLoggingOut
                        ? const SizedBox(
                            key: ValueKey('spinner'),
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.error,
                            ),
                          )
                        : const Icon(
                            key: ValueKey('icon'),
                            Symbols.logout,
                            color: AppColors.onPrimaryContainer,
                            size: 22,
                          ),
                  ),
                  const SizedBox(width: 12),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 250),
                    style: AppTextStyles.labelBold.copyWith(
                      color: _isLoggingOut ? AppColors.error : AppColors.onPrimaryContainer,
                    ),
                    child: const Text('Logout'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Scaffold wrapper with responsive sidebar + drawer on mobile
class ScaffoldWithSidebar extends StatelessWidget {
  const ScaffoldWithSidebar({
    super.key,
    required this.currentRoute,
    required this.role,
    required this.child,
  });

  final String currentRoute;
  final UserRole role;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    final sidebar = AppSidebar(currentRoute: currentRoute, role: role);

    if (isWide) {
      return Scaffold(
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            sidebar,
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      drawer: Drawer(child: sidebar),
      body: child,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        title: const Text('MatchIQ'),
        elevation: 0,
      ),
    );
  }
}
