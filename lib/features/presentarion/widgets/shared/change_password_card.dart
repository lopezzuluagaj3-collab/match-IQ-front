import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../injection/injection_container.dart';
import '../../../domain/ports/input/auth_input_port.dart';
import 'app_card.dart';
import 'app_text_field.dart';

class ChangePasswordCard extends StatefulWidget {
  const ChangePasswordCard({super.key});

  @override
  State<ChangePasswordCard> createState() => _ChangePasswordCardState();
}

class _ChangePasswordCardState extends State<ChangePasswordCard> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _isLoading = false;
  String? _error;
  bool _success = false;

  static final _passwordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^a-zA-Z\d]).{8,}$',
  );

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _success = false;
    });

    final result = await sl<AuthInputPort>().changePassword(
      currentPassword: _currentCtrl.text,
      newPassword: _newCtrl.text,
      confirmPassword: _confirmCtrl.text,
    );

    if (!mounted) return;

    result.fold(
      (failure) => setState(() {
        _isLoading = false;
        _error = failure.message;
      }),
      (_) {
        _currentCtrl.clear();
        _newCtrl.clear();
        _confirmCtrl.clear();
        setState(() {
          _isLoading = false;
          _success = true;
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _success = false);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Symbols.lock_reset,
                    color: AppColors.secondary, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Cambiar contraseña',
                  style: AppTextStyles.headlineMd.copyWith(fontSize: 18)),
            ],
          ),
          const SizedBox(height: 20),
          if (_success) ...[
            _SuccessBanner(),
            const SizedBox(height: 16),
          ],
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  label: 'Contraseña actual',
                  hint: '••••••••',
                  prefixIcon: Symbols.lock,
                  controller: _currentCtrl,
                  isPassword: true,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Ingresa tu contraseña actual' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Nueva contraseña',
                  hint: '••••••••',
                  prefixIcon: Symbols.lock_open,
                  controller: _newCtrl,
                  isPassword: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingresa la nueva contraseña';
                    if (!_passwordRegex.hasMatch(v)) {
                      return 'Mín. 8 caracteres, mayúscula, minúscula, número y símbolo';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Confirmar nueva contraseña',
                  hint: '••••••••',
                  prefixIcon: Symbols.lock_clock,
                  controller: _confirmCtrl,
                  isPassword: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Confirma la nueva contraseña';
                    if (v != _newCtrl.text) return 'Las contraseñas no coinciden';
                    return null;
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  _ErrorBanner(message: _error!),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 220,
                      child: FilledButton.icon(
                        onPressed: _isLoading ? null : _submit,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Symbols.check_circle, size: 18),
                        label: Text(_isLoading
                            ? 'Guardando...'
                            : 'Actualizar contraseña'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.onTertiaryContainer.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: AppColors.onTertiaryContainer.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Symbols.check_circle,
              color: AppColors.onTertiaryContainer, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Contraseña actualizada correctamente.',
              style: AppTextStyles.labelBold
                  .copyWith(color: AppColors.onTertiaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.errorContainer.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: AppColors.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Symbols.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style:
                    AppTextStyles.labelSm.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
