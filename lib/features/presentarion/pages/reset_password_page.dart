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
    if (v == null || v.isEmpty) return 'La contraseña es requerida';
    if (!_passwordRegex.hasMatch(v)) {
      return 'Mínimo 8 caracteres, una mayúscula, una minúscula,\nun número y un carácter especial';
    }
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v == null || v.isEmpty) return 'Confirma tu contraseña';
    if (v != _newPassCtrl.text) return 'Las contraseñas no coinciden';
    return null;
  }

  void _submit(BuildContext context) {
    if (widget.token.isEmpty) {
      showErrorSnackBar(context, 'El enlace de recuperación es inválido o ya expiró.');
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
          showSuccessSnackBar(context, 'Contraseña actualizada correctamente. Ya puedes iniciar sesión.');
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
                  Text('Nueva contraseña', style: AppTextStyles.headlineLg),
                  const SizedBox(height: 6),
                  Text(
                    'Elige una contraseña segura para tu cuenta.',
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
                        label: 'Volver al inicio de sesión',
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
                              label: 'Nueva contraseña',
                              hint: '••••••••',
                              prefixIcon: Symbols.lock,
                              controller: _newPassCtrl,
                              isPassword: true,
                              validator: _validatePassword,
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              label: 'Confirmar contraseña',
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
                                  label: 'Restablecer contraseña',
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
                              label: Text('Volver al inicio de sesión',
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
                Text('Enlace inválido o expirado',
                    style: AppTextStyles.labelBold
                        .copyWith(color: AppColors.error)),
                const SizedBox(height: 2),
                Text(
                  'Este enlace de recuperación no es válido o ya expiró. Solicita uno nuevo desde la página de inicio de sesión.',
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
          Text('La contraseña debe tener:',
              style: AppTextStyles.labelSm
                  .copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 4),
          ...[
            'Al menos 8 caracteres',
            'Una letra mayúscula (A–Z)',
            'Una letra minúscula (a–z)',
            'Un número (0–9)',
            'Un carácter especial (!@#\$%...)',
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
