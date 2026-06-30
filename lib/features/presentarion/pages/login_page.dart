import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../config/router/app_routes.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/shared/app_text_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(LoginRequested(email: _emailCtrl.text.trim(), password: _passwordCtrl.text));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
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
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            Positioned(
              top: -80, right: -80,
              child: Container(
                width: 340, height: 340,
                decoration: BoxDecoration(
                  color: AppColors.onTertiaryContainer.withOpacity(0.06),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -80, left: -80,
              child: Container(
                width: 260, height: 260,
                decoration: BoxDecoration(
                  color: const Color(0xFFCFE5FD).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // ── Botón volver ──────────────────────────────────────────
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: TextButton.icon(
                onPressed: () => context.go(AppRoutes.landing),
                icon: const Icon(Symbols.arrow_back, size: 17),
                label: const Text('Inicio'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.onSurfaceVariant,
                  textStyle: AppTextStyles.labelBold,
                ),
              ),
            ),
          ),
          Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 32),
                      _buildFormCard(),
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

  Widget _buildHeader() {
    return Column(
      children: [
        Image.asset(
          'assets/images/logo.jpeg',
          height: 90,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 20),
        Text('Welcome back', style: AppTextStyles.headlineLg),
        const SizedBox(height: 6),
        Text(
          'Sign in to access your account',
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
        boxShadow: const [BoxShadow(color: Color(0x0A0F2537), blurRadius: 24, offset: Offset(0, 8))],
      ),
      padding: const EdgeInsets.all(28),
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
              validator: (v) => v != null && v.contains('@') ? null : 'Enter a valid email',
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Password',
              hint: '••••••••',
              prefixIcon: Symbols.lock,
              isPassword: true,
              controller: _passwordCtrl,
              validator: (v) => v != null && v.length >= 6 ? null : 'Minimum 6 characters',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  activeColor: AppColors.onTertiaryContainer,
                  onChanged: (v) => setState(() => _rememberMe = v ?? false),
                ),
                Expanded(
                  child: Text('Keep me signed in for 30 days',
                      style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
                ),
                TextButton(
                  onPressed: () => context.go(AppRoutes.forgotPassword),
                  child: Text('Forgot password?',
                      style: AppTextStyles.labelSm.copyWith(color: AppColors.secondary)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            BlocBuilder<AuthBloc, AuthState>(
              buildWhen: (_, curr) =>
                  curr is AuthLoading ||
                  curr is AuthInitial ||
                  curr is AuthFailureState,
              builder: (context, state) => SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'Sign in to MatchIQ',
                  onPressed: _submit,
                  isLoading: state is AuthLoading,
                  icon: Symbols.arrow_forward,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(child: Divider(color: AppColors.outlineVariant)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text('New to the platform?',
                      style: AppTextStyles.labelSm.copyWith(color: AppColors.outline)),
                ),
                const Expanded(child: Divider(color: AppColors.outlineVariant)),
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
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text('© 2024 MatchIQ AI Recruitment. All rights reserved.',
            style: AppTextStyles.labelSm.copyWith(color: AppColors.outline)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {},
              child: Text('Privacy Policy',
                  style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.onSurfaceVariant, decoration: TextDecoration.underline)),
            ),
            TextButton(
              onPressed: () {},
              child: Text('Terms of Service',
                  style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.onSurfaceVariant, decoration: TextDecoration.underline)),
            ),
          ],
        ),
      ],
    );
  }
}

class _RegisterLink extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Text(label, style: AppTextStyles.labelBold),
            const Spacer(),
            const Icon(Icons.chevron_right, color: AppColors.outline),
          ],
        ),
      ),
    );
  }
}
