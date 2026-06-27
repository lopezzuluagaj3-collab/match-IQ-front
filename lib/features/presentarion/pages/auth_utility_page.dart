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
import '../widgets/shared/app_text_field.dart';

class AuthUtilityPage extends StatelessWidget {
  const AuthUtilityPage({
    super.key,
    this.mode = 'password_reset',
    this.email,
  });

  /// 'password_reset' or 'email_verify'
  final String mode;
  final String? email;

  bool get _isVerify => mode == 'email_verify';

  @override
  Widget build(BuildContext context) {
    return _isVerify
        ? _EmailVerifyView(email: email ?? '')
        : const _PasswordResetView();
  }
}

// ─── Password-reset confirmation (no interaction needed) ─────────────────────

class _PasswordResetView extends StatelessWidget {
  const _PasswordResetView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: AppColors.emeraldGradient,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Symbols.mark_email_read,
                      color: Colors.white, size: 40),
                ),
                const SizedBox(height: 24),
                Text('Check your inbox', style: AppTextStyles.headlineLg),
                const SizedBox(height: 10),
                Text(
                  "We've sent a password reset link to your email. Click the link to create a new password.",
                  style: AppTextStyles.bodyMd
                      .copyWith(color: AppColors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: 'Back to Login',
                    onPressed: () => context.go(AppRoutes.login),
                    icon: Symbols.arrow_forward,
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

// ─── Email verification (6-digit code entry) ─────────────────────────────────

class _EmailVerifyView extends StatefulWidget {
  const _EmailVerifyView({required this.email});
  final String email;

  @override
  State<_EmailVerifyView> createState() => _EmailVerifyViewState();
}

class _EmailVerifyViewState extends State<_EmailVerifyView> {
  final _codeCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          showSuccessSnackBar(context, '¡Bienvenido! Email verificado y sesión iniciada.');
          final route = switch (state.user.role) {
            UserRole.candidate => AppRoutes.candidateAssessments,
            UserRole.company => AppRoutes.companyDashboard,
            UserRole.admin => AppRoutes.adminDashboard,
          };
          context.go(route);
        }
        if (state is AuthEmailVerified) {
          showSuccessSnackBar(context, 'Email verificado. Ya puedes iniciar sesión.');
          context.go(AppRoutes.login);
        }
        if (state is AuthFailureState) {
          showErrorSnackBar(context, state.message);
        }
        if (state is AuthPendingVerification) {
          showInfoSnackBar(context, 'Código reenviado. Revisa tu correo.');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: AppColors.emeraldGradient,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Symbols.verified_user,
                        color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 24),
                  Text('Verify your email', style: AppTextStyles.headlineLg),
                  const SizedBox(height: 10),
                  Text(
                    "We sent a 6-digit code to ${widget.email}. Enter it below to activate your account.",
                    style: AppTextStyles.bodyMd
                        .copyWith(color: AppColors.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        AppTextField(
                          label: 'Verification Code',
                          hint: '482910',
                          prefixIcon: Symbols.pin,
                          controller: _codeCtrl,
                          keyboardType: TextInputType.number,
                          validator: (v) => v != null && v.length == 6
                              ? null
                              : 'Enter the 6-digit code',
                        ),
                        const SizedBox(height: 24),
                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) => SizedBox(
                            width: double.infinity,
                            child: AppButton(
                              label: 'Verify Email',
                              isLoading: state is AuthLoading,
                              onPressed: () {
                                if (_formKey.currentState?.validate() ??
                                    false) {
                                  context.read<AuthBloc>().add(
                                        VerifyEmailRequested(
                                          email: widget.email,
                                          code: _codeCtrl.text.trim(),
                                        ),
                                      );
                                }
                              },
                              icon: Symbols.check_circle,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => context.read<AuthBloc>().add(
                                ResendVerificationRequested(
                                    email: widget.email),
                              ),
                          child: Text(
                            "Didn't receive the code? Resend",
                            style: AppTextStyles.labelBold
                                .copyWith(color: AppColors.secondary),
                          ),
                        ),
                      ],
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
