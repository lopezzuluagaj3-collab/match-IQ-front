import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../config/router/app_routes.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/admin_stats.dart';
import '../bloc/admin_cubit.dart';
import '../widgets/shared/app_card.dart';
import '../widgets/shared/app_sidebar.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<AdminCubit>().loadStats();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithSidebar(
      currentRoute: AppRoutes.adminDashboard,
      role: UserRole.admin,
      child: BlocBuilder<AdminCubit, AdminState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.onTertiaryContainer));
          }
          final stats = state.stats;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(),
                const SizedBox(height: 32),
                _KpiGrid(stats: stats),
                const SizedBox(height: 32),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _RecentActivityTable()),
                    const SizedBox(width: 24),
                    Expanded(child: _SystemHealthCard(stats: stats)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Admin Overview', style: AppTextStyles.headlineLg),
              const SizedBox(height: 4),
              Text('Platform-wide analytics and management',
                  style: AppTextStyles.bodyLg.copyWith(color: AppColors.onSurfaceVariant)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.onTertiaryContainer.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Symbols.circle, size: 8, color: AppColors.onTertiaryContainer),
              const SizedBox(width: 8),
              Text('System Healthy', style: AppTextStyles.labelBold.copyWith(color: AppColors.onTertiaryContainer)),
            ],
          ),
        ),
      ],
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.stats});
  final AdminStats? stats;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 20,
      crossAxisSpacing: 20,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2,
      children: [
        _StatCard(
          icon: Symbols.person,
          value: '${stats?.totalCandidates ?? 0}',
          label: 'Total Candidates',
          trend: '+${stats?.usersLast30Days ?? 0} last 30 days',
          trendPositive: true,
          iconColor: AppColors.secondary,
          bgColor: AppColors.secondaryContainer.withOpacity(0.2),
        ),
        _StatCard(
          icon: Symbols.corporate_fare,
          value: '${stats?.totalCompanies ?? 0}',
          label: 'Active Companies',
          iconColor: AppColors.primary,
          bgColor: AppColors.primaryContainer.withOpacity(0.1),
        ),
        _StatCard(
          icon: Symbols.work,
          value: '${stats?.totalOffers ?? 0}',
          label: 'Total Offers',
          trend: '+${stats?.offersLast30Days ?? 0} last 30 days',
          trendPositive: true,
          iconColor: AppColors.onTertiaryContainer,
          bgColor: AppColors.onTertiaryContainer.withOpacity(0.1),
        ),
        _StatCard(
          icon: Symbols.auto_awesome,
          value: '${stats?.totalMatches ?? 0}',
          label: 'Total AI Matches',
          iconColor: AppColors.onTertiaryContainer,
          bgColor: AppColors.onTertiaryContainer.withOpacity(0.1),
        ),
        _StatCard(
          icon: Symbols.assignment,
          value: '${stats?.activeTests ?? 0}',
          label: 'Active Tests',
          iconColor: AppColors.outline,
          bgColor: AppColors.surfaceContainer,
        ),
        _StatCard(
          icon: Symbols.pending_actions,
          value: '${stats?.pendingSubmissions ?? 0}',
          label: 'Pending Submissions',
          iconColor: AppColors.secondary,
          bgColor: AppColors.secondaryContainer.withOpacity(0.2),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
    required this.bgColor,
    this.trend,
    this.trendPositive,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;
  final Color bgColor;
  final String? trend;
  final bool? trendPositive;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 18,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: AppTextStyles.headlineMd.copyWith(fontSize: 28, height: 1.1)),
                Text(label, style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
                if (trend != null)
                  Row(
                    children: [
                      Icon(
                        trendPositive == true ? Symbols.trending_up : Symbols.trending_down,
                        size: 12,
                        color: trendPositive == true ? AppColors.onTertiaryContainer : AppColors.error,
                      ),
                      const SizedBox(width: 4),
                      Text(trend!,
                          style: AppTextStyles.labelSm.copyWith(
                              color: trendPositive == true
                                  ? AppColors.onTertiaryContainer
                                  : AppColors.error,
                              fontSize: 11)),
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

class _RecentActivityTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const events = [
      ('María González registered', 'Candidate', '2 min ago'),
      ('Stellar AI posted new offer', 'Company', '15 min ago'),
      ('AI matched 12 candidates', 'System', '1 hour ago'),
      ('Carlos Rueda completed test', 'Candidate', '2 hours ago'),
      ('Nexus FinTech updated profile', 'Company', '3 hours ago'),
      ('System: weekly report generated', 'System', 'Today, 06:00'),
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Platform Activity', style: AppTextStyles.headlineMd),
          const SizedBox(height: 20),
          ...events.map((e) => Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(color: AppColors.outlineVariant.withOpacity(0.3))),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: switch (e.$2) {
                          'Candidate' => AppColors.secondary,
                          'Company' => AppColors.onTertiaryContainer,
                          _ => AppColors.outline,
                        },
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(e.$1, style: AppTextStyles.bodyMd.copyWith(fontSize: 14))),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(e.$2, style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant, fontSize: 11)),
                    ),
                    const SizedBox(width: 12),
                    Text(e.$3, style: AppTextStyles.labelSm.copyWith(color: AppColors.outline)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _SystemHealthCard extends StatelessWidget {
  const _SystemHealthCard({required this.stats});
  final AdminStats? stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Symbols.monitor_heart, color: AppColors.onTertiaryContainer, size: 22),
                  const SizedBox(width: 8),
                  Text('System Health', style: AppTextStyles.headlineMd),
                ],
              ),
              const SizedBox(height: 20),
              _HealthBar(label: 'API Response', value: 0.98, color: AppColors.onTertiaryContainer),
              _HealthBar(label: 'AI Engine', value: 0.95, color: AppColors.onTertiaryContainer),
              _HealthBar(label: 'Database', value: 0.99, color: AppColors.onTertiaryContainer),
              _HealthBar(label: 'Storage', value: 0.72, color: AppColors.secondary),
            ],
          ),
        ),
        const SizedBox(height: 20),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Quick Actions', style: AppTextStyles.headlineMd),
              const SizedBox(height: 16),
              _ActionButton(icon: Symbols.download, label: 'Export Platform Report'),
              _ActionButton(icon: Symbols.person_add, label: 'Invite Admin User'),
              _ActionButton(icon: Symbols.settings, label: 'System Configuration'),
              _ActionButton(icon: Symbols.backup, label: 'Trigger Manual Backup'),
            ],
          ),
        ),
      ],
    );
  }
}

class _HealthBar extends StatelessWidget {
  const _HealthBar({required this.label, required this.value, required this.color});
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: AppColors.surfaceVariant,
                color: color,
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('${(value * 100).toInt()}%',
              style: AppTextStyles.labelBold.copyWith(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.secondary, size: 20),
      title: Text(label, style: AppTextStyles.labelBold.copyWith(color: AppColors.onSurface)),
      trailing: const Icon(Symbols.chevron_right, size: 18, color: AppColors.outline),
      onTap: () {},
    );
  }
}
