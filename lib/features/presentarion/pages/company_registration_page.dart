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
import '../widgets/shared/app_card.dart';
import '../widgets/shared/app_text_field.dart';

class CompanyRegistrationPage extends StatefulWidget {
  const CompanyRegistrationPage({super.key});

  @override
  State<CompanyRegistrationPage> createState() =>
      _CompanyRegistrationPageState();
}

class _CompanyRegistrationPageState extends State<CompanyRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _cedulaCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _cedulaCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Ingresa una contraseña';
    if (v.length < 8) return 'Mínimo 8 caracteres';
    if (!v.contains(RegExp(r'[A-Z]'))) return 'Debe tener al menos una mayúscula';
    if (!v.contains(RegExp(r'[a-z]'))) return 'Debe tener al menos una minúscula';
    if (!v.contains(RegExp(r'[0-9]'))) return 'Debe tener al menos un número';
    if (!v.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]'))) {
      return 'Debe tener al menos un carácter especial (!@#\$%...)';
    }
    return null;
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
        body: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      _buildHeader(),
                      const SizedBox(height: 32),
                      _buildForm(),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.login),
                        child: Text(
                          'Already have an account? Sign in',
                          style: AppTextStyles.labelBold
                              .copyWith(color: AppColors.secondary),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
            const Positioned(top: 16, right: 16, child: ThemeToggleButton()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.onTertiaryContainer.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Symbols.corporate_fare,
              color: AppColors.onTertiaryContainer, size: 28),
        ),
        const SizedBox(height: 16),
        Text('Create Company Account', style: AppTextStyles.headlineLg),
        const SizedBox(height: 6),
        Text(
          'Find top talent with AI-powered matching',
          style: AppTextStyles.bodyMd.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withValues(alpha: 0.5)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A0F2537), blurRadius: 24, offset: Offset(0, 8))
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: 'Full Name',
              hint: 'Ana García',
              prefixIcon: Symbols.person,
              controller: _nameCtrl,
              validator: (v) =>
                  v != null && v.length >= 2 ? null : 'Enter your full name',
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Work Email',
              hint: 'hr@company.com',
              prefixIcon: Symbols.mail,
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => v != null && v.contains('@')
                  ? null
                  : 'Enter a valid email',
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Cédula / NIT',
              hint: '900123456',
              prefixIcon: Symbols.badge,
              controller: _cedulaCtrl,
              keyboardType: TextInputType.number,
              validator: (v) =>
                  v != null && v.length >= 5 ? null : 'Enter your cédula or NIT',
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Password',
              hint: '••••••••',
              prefixIcon: Symbols.lock,
              isPassword: true,
              controller: _passwordCtrl,
              validator: _validatePassword,
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Confirm Password',
              hint: '••••••••',
              prefixIcon: Symbols.lock_reset,
              isPassword: true,
              controller: _confirmCtrl,
              validator: (v) =>
                  v == _passwordCtrl.text ? null : 'Las contraseñas no coinciden',
            ),
            const SizedBox(height: 28),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) => SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'Create Company Account',
                  isLoading: state is AuthLoading,
                  isEmerald: true,
                  icon: Symbols.arrow_forward,
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      context.read<AuthBloc>().add(
                            RegisterCompanyRequested(
                              companyName: _nameCtrl.text.trim(),
                              email: _emailCtrl.text.trim(),
                              cedula: _cedulaCtrl.text.trim(),
                              password: _passwordCtrl.text,
                            ),
                          );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
