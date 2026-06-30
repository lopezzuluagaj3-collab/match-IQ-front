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

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key, required this.token});
  final String token;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  @override
  void dispose() {
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  static final _passwordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^a-zA-Z\d]).{8,}$',
  );

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (!_passwordRegex.hasMatch(v)) {
      return 'At least 8 chars, one uppercase, one lowercase,\none number and one special character';
    }
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v == null || v.isEmpty) return 'Please confirm your password';
    if (v != _newPassCtrl.text) return 'Passwords do not match';
    return null;
  }

  void _submit(BuildContext context) {
    if (widget.token.isEmpty) {
      showErrorSnackBar(context, 'The recovery link is invalid or has already expired.');
      return;
    }
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(ResetPasswordRequested(
            token: widget.token,
            newPassword: _newPassCtrl.text,
            confirmPassword: _confirmPassCtrl.text,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthPasswordResetSuccess) {
          showSuccessSnackBar(context, 'Password updated successfully. You can now sign in.');
          context.go(AppRoutes.login);
        }
        if (state is AuthFailureState) {
          showErrorSnackBar(context, state.message);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Symbols.lock_reset,
                        color: AppColors.secondary, size: 28),
                  ),
                  const SizedBox(height: 16),
                  Text('New password', style: AppTextStyles.headlineLg),
                  const SizedBox(height: 6),
                  Text(
                    'Choose a strong password for your account.',
                    style: AppTextStyles.bodyMd
                        .copyWith(color: AppColors.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  if (widget.token.isEmpty) ...[
                    _InvalidTokenBanner(),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: AppButton(
                        label: 'Back to sign in',
                        onPressed: () => context.go(AppRoutes.login),
                        icon: Symbols.arrow_forward,
                      ),
                    ),
                  ] else
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x0A0F2537),
                              blurRadius: 24,
                              offset: Offset(0, 8))
                        ],
                      ),
                      padding: const EdgeInsets.all(28),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppTextField(
                              label: 'New password',
                              hint: '••••••••',
                              prefixIcon: Symbols.lock,
                              controller: _newPassCtrl,
                              isPassword: true,
                              validator: _validatePassword,
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              label: 'Confirm password',
                              hint: '••••••••',
                              prefixIcon: Symbols.lock_clock,
                              controller: _confirmPassCtrl,
                              isPassword: true,
                              validator: _validateConfirm,
                            ),
                            const SizedBox(height: 8),
                            _PasswordHints(),
                            const SizedBox(height: 24),
                            BlocBuilder<AuthBloc, AuthState>(
                              builder: (context, state) => SizedBox(
                                width: double.infinity,
                                child: AppButton(
                                  label: 'Reset password',
                                  isLoading: state is AuthLoading,
                                  icon: Symbols.check_circle,
                                  onPressed: () => _submit(context),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: () => context.go(AppRoutes.login),
                              icon: const Icon(Symbols.arrow_back,
                                  size: 18, color: AppColors.secondary),
                              label: Text('Back to sign in',
                                  style: AppTextStyles.labelBold
                                      .copyWith(color: AppColors.secondary)),
                            ),
                          ],
                        ),
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

class _InvalidTokenBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorContainer.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Symbols.error_outline, color: AppColors.error, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Invalid or expired link',
                    style: AppTextStyles.labelBold
                        .copyWith(color: AppColors.error)),
                const SizedBox(height: 2),
                Text(
                  'This recovery link is invalid or has already expired. Request a new one from the sign in page.',
                  style: AppTextStyles.labelSm
                      .copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordHints extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Password must have:',
              style: AppTextStyles.labelSm
                  .copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 4),
          ...[
            'At least 8 characters',
            'One uppercase letter (A–Z)',
            'One lowercase letter (a–z)',
            'One number (0–9)',
            'One special character (!@#\$%...)',
          ].map((hint) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  children: [
                    const Icon(Symbols.circle,
                        size: 6, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(hint,
                        style: AppTextStyles.labelSm
                            .copyWith(color: AppColors.onSurfaceVariant)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
