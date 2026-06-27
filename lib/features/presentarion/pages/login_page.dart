import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../config/router/app_routes.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../domain/entities/user.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../bloc/theme_cubit.dart';
import '../widgets/shared/app_card.dart';
import '../widgets/shared/app_text_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _rememberMe = false;

  late final AnimationController _entrance;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _formOpacity;
  late final Animation<Offset> _formSlide;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoScale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );
    _formOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.3, 0.85, curve: Curves.easeOut),
      ),
    );
    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.3, 0.85, curve: Curves.easeOut),
      ),
    );
    _entrance.forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            LoginRequested(
              email: _emailCtrl.text.trim(),
              password: _passwordCtrl.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          switch (state.user.role) {
            case UserRole.candidate:
              context.go(AppRoutes.candidateAssessments);
            case UserRole.company:
              context.go(AppRoutes.companyDashboard);
            case UserRole.admin:
              context.go(AppRoutes.adminDashboard);
          }
        }
        if (state is AuthPendingVerification) {
          context.go(
            AppRoutes.authUtility,
            extra: {'mode': 'email_verify', 'email': state.email},
          );
        }
        if (state is AuthFailureState) {
          showErrorSnackBar(context, state.message);
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Background decoration circles
            Positioned(
              top: -100, right: -100,
              child: _GlowCircle(
                size: 380,
                color: isDark
                    ? AppColors.onTertiaryContainer.withValues(alpha: 0.06)
                    : AppColors.onTertiaryContainer.withValues(alpha: 0.05),
              ),
            ),
            Positioned(
              bottom: -80, left: -80,
              child: _GlowCircle(
                size: 280,
                color: isDark
                    ? AppColors.secondary.withValues(alpha: 0.08)
                    : const Color(0xFFCFE5FD).withValues(alpha: 0.2),
              ),
            ),

            // Theme toggle — top right
            Positioned(
              top: 20, right: 20,
              child: BlocBuilder<ThemeCubit, ThemeMode>(
                builder: (context, mode) {
                  final dark = mode == ThemeMode.dark;
                  return Tooltip(
                    message: dark ? 'Modo día' : 'Modo noche',
                    child: GestureDetector(
                      onTap: () => context.read<ThemeCubit>().toggle(),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: dark
                              ? Colors.white.withValues(alpha: 0.08)
                              : AppColors.primaryContainer.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: dark
                                ? Colors.white.withValues(alpha: 0.1)
                                : AppColors.outlineVariant,
                          ),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          transitionBuilder: (child, anim) => RotationTransition(
                            turns: Tween<double>(begin: 0.25, end: 0.0)
                                .animate(anim),
                            child: FadeTransition(opacity: anim, child: child),
                          ),
                          child: Icon(
                            dark ? Symbols.light_mode : Symbols.dark_mode,
                            key: ValueKey(dark),
                            color: dark
                                ? AppColors.onTertiaryContainer
                                : AppColors.primary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Main content
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    children: [
                      _buildLogo(),
                      const SizedBox(height: 32),
                      _buildFormCard(isDark),
                      const SizedBox(height: 24),
                      _buildFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoAsset = isDark ? 'lib/assets/logo_dark.jpeg' : 'lib/assets/logo_light.jpeg';
    return FadeTransition(
      opacity: _logoOpacity,
      child: ScaleTransition(
        scale: _logoScale,
        child: Column(
          children: [
            Image.asset(
              logoAsset,
              height: 80,
              errorBuilder: (_, __, ___) => Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Symbols.auto_awesome,
                  color: AppColors.onTertiaryContainer,
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Platform Access', style: AppTextStyles.headlineLg),
            const SizedBox(height: 6),
            Text(
              'Welcome back, please login to your account',
              style: AppTextStyles.bodyMd
                  .copyWith(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard(bool isDark) {
    return FadeTransition(
      opacity: _formOpacity,
      child: SlideTransition(
        position: _formSlide,
        child: AppCard(
          radius: 20,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  label: 'Email Address',
                  hint: 'name@company.com',
                  prefixIcon: Symbols.mail,
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      v != null && v.contains('@') ? null : 'Enter a valid email',
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: 'Password',
                  hint: '••••••••',
                  prefixIcon: Symbols.lock,
                  isPassword: true,
                  controller: _passwordCtrl,
                  validator: (v) =>
                      v != null && v.length >= 6 ? null : 'Minimum 6 characters',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      activeColor: AppColors.onTertiaryContainer,
                      onChanged: (v) =>
                          setState(() => _rememberMe = v ?? false),
                    ),
                    Expanded(
                      child: Text(
                        'Keep me signed in for 30 days',
                        style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.onSurfaceVariant),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.forgotPassword),
                      child: Text(
                        'Forgot password?',
                        style: AppTextStyles.labelSm
                            .copyWith(color: AppColors.secondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) => AppButton(
                    label: 'Sign in to MatchIQ',
                    onPressed: _submit,
                    isLoading: state is AuthLoading,
                    icon: Symbols.arrow_forward,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        'New to the platform?',
                        style: AppTextStyles.labelSm
                            .copyWith(color: AppColors.outline),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 20),
                _RegisterLink(
                  icon: Symbols.person,
                  label: 'Register as Candidate',
                  iconColor: AppColors.secondary,
                  onTap: () => context.go(AppRoutes.registerCandidate),
                ),
                const SizedBox(height: 10),
                _RegisterLink(
                  icon: Symbols.corporate_fare,
                  label: 'Register as Company',
                  iconColor: AppColors.onTertiaryContainer,
                  onTap: () => context.go(AppRoutes.registerCompany),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return FadeTransition(
      opacity: _formOpacity,
      child: Column(
        children: [
          Text(
            '© 2024 MatchIQ AI Recruitment. All rights reserved.',
            style: AppTextStyles.labelSm.copyWith(color: AppColors.outline),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {},
                child: Text(
                  'Privacy Policy',
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Terms of Service',
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    decoration: TextDecoration.underline,
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

// ── Decorative glow circle ────────────────────────────────────────────────────

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// ── Register link row ─────────────────────────────────────────────────────────

class _RegisterLink extends StatefulWidget {
  const _RegisterLink({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.iconColor,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  State<_RegisterLink> createState() => _RegisterLinkState();
}

class _RegisterLinkState extends State<_RegisterLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = _hovered
        ? widget.iconColor.withValues(alpha: 0.5)
        : Theme.of(context).colorScheme.outlineVariant;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(12),
            color: _hovered
                ? widget.iconColor.withValues(alpha: 0.04)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: widget.iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Text(widget.label, style: AppTextStyles.labelBold),
              const Spacer(),
              Icon(Icons.chevron_right,
                  color: Theme.of(context).colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
