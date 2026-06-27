import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../config/router/app_routes.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../domain/entities/user.dart';
import '../bloc/company_cubit.dart';
import '../widgets/shared/app_card.dart';
import '../widgets/shared/app_sidebar.dart';
import '../widgets/shared/app_text_field.dart';

class CompanyProfileSettingsPage extends StatefulWidget {
  const CompanyProfileSettingsPage({super.key});

  @override
  State<CompanyProfileSettingsPage> createState() => _CompanyProfileSettingsPageState();
}

class _CompanyProfileSettingsPageState extends State<CompanyProfileSettingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    context.read<CompanyCubit>().loadDashboard();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithSidebar(
      currentRoute: AppRoutes.companySettings,
      role: UserRole.company,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Company Settings', style: AppTextStyles.headlineLg),
            Text('Manage your company profile and preferences',
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 24),
            TabBar(
              controller: _tabs,
              labelStyle: AppTextStyles.labelBold,
              unselectedLabelStyle: AppTextStyles.labelBold.copyWith(color: AppColors.outline),
              indicatorColor: AppColors.onTertiaryContainer,
              labelColor: AppColors.onTertiaryContainer,
              unselectedLabelColor: AppColors.outline,
              dividerColor: AppColors.outlineVariant,
              tabs: const [
                Tab(text: 'Company Profile'),
                Tab(text: 'Preferences'),
                Tab(text: 'Billing'),
              ],
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 700,
              child: TabBarView(
                controller: _tabs,
                children: [
                  _ProfileTab(),
                  _PreferencesTab(),
                  _BillingTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTab extends StatefulWidget {
  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  final _nameCtrl = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CompanyCubit, CompanyState>(
      listener: (context, state) {
        if (!_initialized && state.profile != null) {
          _nameCtrl.text = state.profile!.companyName;
          _initialized = true;
        }
        if (!state.isSaving && state.error == null && _initialized) {
          // saved — no-op, snackbar shown below
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
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Symbols.corporate_fare,
                        color: AppColors.onTertiaryContainer, size: 36),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p?.companyName ?? 'Company Name', style: AppTextStyles.headlineMd),
                        Text(p?.email ?? '',
                            style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
                        Text(p?.fullName ?? '',
                            style: AppTextStyles.labelSm.copyWith(color: AppColors.outline)),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Symbols.upload, size: 16),
                    label: const Text('Upload Logo'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.outlineVariant),
                      foregroundColor: AppColors.onSurface,
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
                  Text('Company Details', style: AppTextStyles.headlineMd.copyWith(fontSize: 18)),
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
                        style: AppTextStyles.labelSm.copyWith(color: AppColors.error)),
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
                          context.read<CompanyCubit>().updateProfile(name).then((_) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Changes saved!'),
                                  backgroundColor: AppColors.onTertiaryContainer,
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
          ],
        );
      },
    );
  }
}

class _PreferencesTab extends StatefulWidget {
  @override
  State<_PreferencesTab> createState() => _PreferencesTabState();
}

class _PreferencesTabState extends State<_PreferencesTab> {
  bool _aiAutoMatch = true;
  bool _emailNotifs = true;
  bool _weeklyReport = false;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('AI & Notifications', style: AppTextStyles.headlineMd.copyWith(fontSize: 18)),
          const SizedBox(height: 20),
          _PreferenceSwitch(
            icon: Symbols.auto_awesome,
            title: 'AI Auto-Match',
            subtitle: 'Automatically match candidates to open positions',
            value: _aiAutoMatch,
            onChanged: (v) => setState(() => _aiAutoMatch = v),
          ),
          const Divider(color: AppColors.outlineVariant),
          _PreferenceSwitch(
            icon: Symbols.notifications,
            title: 'Email Notifications',
            subtitle: 'Receive email alerts for new matches',
            value: _emailNotifs,
            onChanged: (v) => setState(() => _emailNotifs = v),
          ),
          const Divider(color: AppColors.outlineVariant),
          _PreferenceSwitch(
            icon: Symbols.analytics,
            title: 'Weekly Reports',
            subtitle: 'Get a weekly summary of your hiring pipeline',
            value: _weeklyReport,
            onChanged: (v) => setState(() => _weeklyReport = v),
          ),
        ],
      ),
    );
  }
}

class _PreferenceSwitch extends StatelessWidget {
  const _PreferenceSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.secondary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelBold),
                Text(subtitle,
                    style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.onTertiaryContainer,
          ),
        ],
      ),
    );
  }
}

class _BillingTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppColors.emeraldGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Symbols.star, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Enterprise Plan', style: AppTextStyles.headlineMd.copyWith(fontSize: 20)),
                  Text('Active · Renews Jan 1, 2025',
                      style: AppTextStyles.labelSm.copyWith(color: AppColors.onTertiaryContainer)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: AppColors.outlineVariant),
          const SizedBox(height: 16),
          _BillingFeature('Unlimited AI Matches'),
          _BillingFeature('Priority candidate ranking'),
          _BillingFeature('Advanced analytics dashboard'),
          _BillingFeature('Dedicated account manager'),
          const SizedBox(height: 24),
          Row(
            children: [
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.outlineVariant),
                  foregroundColor: AppColors.onSurface,
                ),
                child: const Text('Manage Billing'),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () {},
                child: Text('Cancel Subscription',
                    style: AppTextStyles.labelBold.copyWith(color: AppColors.error)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BillingFeature extends StatelessWidget {
  const _BillingFeature(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Symbols.check_circle, size: 18, color: AppColors.onTertiaryContainer),
          const SizedBox(width: 10),
          Text(label, style: AppTextStyles.bodyMd),
        ],
      ),
    );
  }
}
