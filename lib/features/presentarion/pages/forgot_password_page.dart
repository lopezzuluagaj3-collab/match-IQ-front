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

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthPasswordResetSent) {
          context.go(AppRoutes.authUtility);
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
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Symbols.lock_reset, color: AppColors.secondary, size: 28),
                  ),
                  const SizedBox(height: 16),
                  Text('Reset Password', style: AppTextStyles.headlineLg),
                  const SizedBox(height: 6),
                  Text(
                    "Enter your email and we'll send you a link to reset your password.",
                    style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Container(
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
                          const SizedBox(height: 24),
                          BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) => SizedBox(
                              width: double.infinity,
                              child: AppButton(
                                label: 'Send Reset Link',
                                isLoading: state is AuthLoading,
                                icon: Symbols.send,
                                onPressed: () {
                                  if (_formKey.currentState?.validate() ?? false) {
                                    context.read<AuthBloc>().add(
                                      ForgotPasswordRequested(email: _emailCtrl.text.trim()),
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: () => context.go(AppRoutes.login),
                            icon: const Icon(Symbols.arrow_back, size: 18, color: AppColors.secondary),
                            label: Text('Back to Login',
                                style: AppTextStyles.labelBold.copyWith(color: AppColors.secondary)),
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
