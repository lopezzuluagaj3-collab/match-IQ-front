import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../config/router/app_routes.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../domain/entities/user.dart';
import '../bloc/company_cubit.dart';
import '../../../config/theme/responsive.dart';
import '../widgets/shared/app_card.dart';
import '../widgets/shared/app_sidebar.dart';
import '../widgets/shared/app_text_field.dart';
import '../widgets/shared/change_password_card.dart';

class CompanyProfileSettingsPage extends StatefulWidget {
  const CompanyProfileSettingsPage({super.key});

  @override
  State<CompanyProfileSettingsPage> createState() => _CompanyProfileSettingsPageState();
}

class _CompanyProfileSettingsPageState extends State<CompanyProfileSettingsPage> {
  final _nameCtrl = TextEditingController();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    context.read<CompanyCubit>().loadDashboard();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithSidebar(
      currentRoute: AppRoutes.companySettings,
      role: UserRole.company,
      child: SingleChildScrollView(
        padding: Responsive.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Company Settings', style: AppTextStyles.headlineLg),
            Text('Manage your company profile',
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 32),
            BlocConsumer<CompanyCubit, CompanyState>(
              listener: (context, state) {
                if (!_initialized && state.profile != null) {
                  _nameCtrl.text = state.profile!.companyName;
                  _initialized = true;
                }
              },
              builder: (context, state) {
                final p = state.profile;
                return Column(
                  children: [
                    AppCard(
                      child: Row(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Symbols.corporate_fare,
                                color: AppColors.onTertiaryContainer, size: 36),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p?.companyName ?? 'Company Name',
                                    style: AppTextStyles.headlineMd),
                                Text(p?.email ?? '',
                                    style: AppTextStyles.bodyMd
                                        .copyWith(color: AppColors.onSurfaceVariant)),
                                Text(p?.fullName ?? '',
                                    style: AppTextStyles.labelSm
                                        .copyWith(color: AppColors.outline)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Company Details',
                              style: AppTextStyles.headlineMd.copyWith(fontSize: 18)),
                          const SizedBox(height: 20),
                          AppTextField(
                            label: 'Company Name',
                            hint: 'Company Name',
                            prefixIcon: Symbols.business,
                            controller: _nameCtrl,
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            label: 'Contact Email',
                            hint: p?.email ?? '',
                            prefixIcon: Symbols.email,
                            enabled: false,
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            label: 'Contact Name',
                            hint: p?.fullName ?? '',
                            prefixIcon: Symbols.person,
                            enabled: false,
                          ),
                          if (state.error != null) ...[
                            const SizedBox(height: 12),
                            Text(state.error!,
                                style: AppTextStyles.labelSm
                                    .copyWith(color: AppColors.error)),
                          ],
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              AppButton(
                                label: 'Save Changes',
                                isEmerald: true,
                                icon: Symbols.save,
                                isLoading: state.isSaving,
                                onPressed: () {
                                  final name = _nameCtrl.text.trim();
                                  if (name.isEmpty) return;
                                  context
                                      .read<CompanyCubit>()
                                      .updateProfile(name)
                                      .then((_) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Changes saved!'),
                                          backgroundColor:
                                              AppColors.onTertiaryContainer,
                                        ),
                                      );
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const ChangePasswordCard(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
