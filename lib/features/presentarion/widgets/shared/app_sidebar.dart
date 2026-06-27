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
import '../../bloc/theme_cubit.dart';

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
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(4, 0)),
        ],
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
      UserRole.candidate => const [
          _NavItem(icon: Symbols.assignment, label: 'Assessments', route: AppRoutes.candidateAssessments),
          _NavItem(icon: Symbols.person, label: 'Profile', route: AppRoutes.candidateProfile),
        ],
      UserRole.company => const [
          _NavItem(icon: Symbols.dashboard, label: 'Overview', route: AppRoutes.companyDashboard),
          _NavItem(icon: Symbols.group, label: 'Talent Pool', route: AppRoutes.companyMatches),
          _NavItem(icon: Symbols.alt_route, label: 'Pipeline', route: AppRoutes.companyMatches),
          _NavItem(icon: Symbols.analytics, label: 'Reports', route: AppRoutes.companyDashboard),
          _NavItem(icon: Symbols.settings, label: 'Settings', route: AppRoutes.companySettings),
        ],
      UserRole.admin => const [
          _NavItem(icon: Symbols.dashboard, label: 'Overview', route: AppRoutes.adminDashboard),
          _NavItem(icon: Symbols.group, label: 'Talent Pool', route: AppRoutes.adminDashboard),
          _NavItem(icon: Symbols.alt_route, label: 'Pipeline', route: AppRoutes.adminDashboard),
          _NavItem(icon: Symbols.analytics, label: 'Reports', route: AppRoutes.adminDashboard),
          _NavItem(icon: Symbols.settings, label: 'Settings', route: AppRoutes.adminDashboard),
        ],
    };

    return items
        .map((item) => _SideNavItem(item: item, isActive: currentRoute == item.route))
        .toList();
  }
}

// ── Header with logo ──────────────────────────────────────────────────────────

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
          // Logo — dark version (sidebar always stays dark navy)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'lib/assets/logo_dark.jpeg',
              width: 40,
              height: 40,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Symbols.auto_awesome,
                  color: AppColors.onTertiaryContainer,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Match',
                        style: AppTextStyles.headlineLgMobile.copyWith(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: 'IQ',
                        style: AppTextStyles.headlineLgMobile.copyWith(
                          color: AppColors.onTertiaryContainer,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.onPrimaryContainer,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Nav item data ─────────────────────────────────────────────────────────────

class _NavItem {
  const _NavItem({required this.icon, required this.label, required this.route});
  final IconData icon;
  final String label;
  final String route;
}

// ── Nav item with hover animation ─────────────────────────────────────────────

class _SideNavItem extends StatefulWidget {
  const _SideNavItem({required this.item, required this.isActive});
  final _NavItem item;
  final bool isActive;

  @override
  State<_SideNavItem> createState() => _SideNavItemState();
}

class _SideNavItemState extends State<_SideNavItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isActive;
    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovered = true);
        _ctrl.forward();
      },
      onExit: (_) {
        setState(() => _hovered = false);
        _ctrl.reverse();
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go(widget.item.route),
        child: ScaleTransition(
          scale: _scale,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 1),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primaryContainer.withValues(alpha: 0.5)
                  : _hovered
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.transparent,
              border: isActive
                  ? const Border(
                      left: BorderSide(color: AppColors.onTertiaryContainer, width: 4),
                    )
                  : null,
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(isActive ? 16 : 20, 12, 20, 12),
              child: Row(
                children: [
                  Icon(
                    widget.item.icon,
                    color: isActive
                        ? AppColors.onTertiaryContainer
                        : AppColors.onPrimaryContainer,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.item.label,
                    style: AppTextStyles.labelBold.copyWith(
                      color: isActive
                          ? AppColors.onTertiaryContainer
                          : AppColors.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Footer with theme toggle + logout ────────────────────────────────────────

class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter({required this.role});
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (role == UserRole.company)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                gradient: AppColors.emeraldGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.onTertiaryContainer.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextButton(
                onPressed: () => context.go(AppRoutes.createOffer),
                child: Text(
                  '+ Post New Offer',
                  style: AppTextStyles.labelBold.copyWith(color: Colors.white),
                ),
              ),
            ),
          Row(
            children: [
              // Day/Night toggle
              BlocBuilder<ThemeCubit, ThemeMode>(
                builder: (context, mode) {
                  final isDark = mode == ThemeMode.dark;
                  return Tooltip(
                    message: isDark ? 'Modo día' : 'Modo noche',
                    child: GestureDetector(
                      onTap: () => context.read<ThemeCubit>().toggle(),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, anim) => RotationTransition(
                            turns: Tween<double>(begin: 0.25, end: 0.0)
                                .animate(anim),
                            child: FadeTransition(opacity: anim, child: child),
                          ),
                          child: Icon(
                            isDark ? Symbols.light_mode : Symbols.dark_mode,
                            key: ValueKey(isDark),
                            color: isDark
                                ? AppColors.onTertiaryContainer
                                : AppColors.onPrimaryContainer,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 4),
              // Logout
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      context.read<AuthBloc>().add(const LogoutRequested()),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Symbols.logout,
                            color: AppColors.onPrimaryContainer, size: 22),
                        const SizedBox(width: 12),
                        Text(
                          'Logout',
                          style: AppTextStyles.labelBold
                              .copyWith(color: AppColors.onPrimaryContainer),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── ScaffoldWithSidebar ───────────────────────────────────────────────────────

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
        title: Row(
          children: [
            Image.asset(
              'lib/assets/logo_dark.jpeg',
              height: 28,
              errorBuilder: (_, __, ___) => const Icon(
                Symbols.auto_awesome,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 8),
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'Match',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text: 'IQ',
                    style: TextStyle(
                        color: AppColors.onTertiaryContainer,
                        fontSize: 18,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
        elevation: 0,
        actions: [
          BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, mode) => IconButton(
              icon: Icon(
                mode == ThemeMode.dark ? Symbols.light_mode : Symbols.dark_mode,
                color: Colors.white,
              ),
              onPressed: () => context.read<ThemeCubit>().toggle(),
            ),
          ),
        ],
      ),
    );
  }
}
