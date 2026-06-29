import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../config/router/app_routes.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../config/theme/responsive.dart';
import '../../domain/entities/admin_stats.dart';
import '../../domain/entities/user.dart';
import '../bloc/admin_cubit.dart';
import '../widgets/shared/app_card.dart';
import '../widgets/shared/app_sidebar.dart';
import '../widgets/shared/change_password_card.dart';

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
            return const Center(
                child: CircularProgressIndicator(
                    color: AppColors.onTertiaryContainer));
          }
          final s = state.stats;
          return SingleChildScrollView(
            padding: Responsive.pagePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(onViewUsers: () => context.go(AppRoutes.adminUsers)),
                const SizedBox(height: 32),

                // ── Usuarios ─────────────────────────────────────────────
                _SectionTitle(icon: Symbols.person, label: 'Usuarios'),
                const SizedBox(height: 12),
                _ResponsiveStatRow(cards: [
                  _StatCard(
                    icon: Symbols.person,
                    value: '${s?.totalCandidates ?? 0}',
                    label: 'Candidatos',
                    sub: '+${s?.usersRegisteredLast30Days ?? 0} últimos 30 días',
                    iconColor: AppColors.secondary,
                    bgColor: AppColors.secondaryContainer.withValues(alpha: 0.2),
                  ),
                  _StatCard(
                    icon: Symbols.corporate_fare,
                    value: '${s?.totalCompanies ?? 0}',
                    label: 'Empresas',
                    iconColor: AppColors.primary,
                    bgColor: AppColors.primaryContainer.withValues(alpha: 0.15),
                  ),
                  _StatCard(
                    icon: Symbols.group_add,
                    value: '${s?.usersRegisteredLast30Days ?? 0}',
                    label: 'Nuevos / 30 días',
                    iconColor: AppColors.onTertiaryContainer,
                    bgColor: AppColors.onTertiaryContainer.withValues(alpha: 0.1),
                  ),
                ]),
                const SizedBox(height: 28),

                // ── Ofertas ───────────────────────────────────────────────
                _SectionTitle(icon: Symbols.work, label: 'Ofertas'),
                const SizedBox(height: 12),
                _ResponsiveStatRow(cards: [
                  _StatCard(
                    icon: Symbols.work,
                    value: '${s?.totalOffers ?? 0}',
                    label: 'Total ofertas',
                    sub: '+${s?.offersCreatedLast30Days ?? 0} últimos 30 días',
                    iconColor: AppColors.secondary,
                    bgColor: AppColors.secondaryContainer.withValues(alpha: 0.2),
                  ),
                  _StatCard(
                    icon: Symbols.check_circle,
                    value: '${s?.offersActive ?? 0}',
                    label: 'Activas',
                    iconColor: AppColors.onTertiaryContainer,
                    bgColor: AppColors.onTertiaryContainer.withValues(alpha: 0.1),
                  ),
                  _StatCard(
                    icon: Symbols.pending_actions,
                    value: '${s?.offersPendingPayment ?? 0}',
                    label: 'Pendiente pago',
                    iconColor: const Color(0xFFF59E0B),
                    bgColor: const Color(0xFFF59E0B0D),
                  ),
                  _StatCard(
                    icon: Symbols.cancel,
                    value: '${(s?.offersCancelled ?? 0) + (s?.offersExpired ?? 0)}',
                    label: 'Canceladas / Expiradas',
                    iconColor: AppColors.error,
                    bgColor: AppColors.error.withValues(alpha: 0.08),
                  ),
                ]),
                const SizedBox(height: 28),

                // ── Matching + Tests ──────────────────────────────────────
                LayoutBuilder(
                  builder: (_, c) => c.maxWidth < 600
                      ? Column(children: [_MatchingCard(s: s), const SizedBox(height: 20), _TestsCard(s: s)])
                      : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(child: _MatchingCard(s: s)),
                          const SizedBox(width: 20),
                          Expanded(child: _TestsCard(s: s)),
                        ]),
                ),
                const SizedBox(height: 28),

                // ── Ingresos + Tasas ──────────────────────────────────────
                LayoutBuilder(
                  builder: (_, c) => c.maxWidth < 600
                      ? Column(children: [_RevenueCard(s: s), const SizedBox(height: 20), _RatesCard(s: s)])
                      : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(child: _RevenueCard(s: s)),
                          const SizedBox(width: 20),
                          Expanded(child: _RatesCard(s: s)),
                        ]),
                ),
                const SizedBox(height: 28),

                // ── Cuenta ────────────────────────────────────────────────
                _SectionTitle(icon: Symbols.manage_accounts, label: 'Cuenta'),
                const SizedBox(height: 12),
                const ChangePasswordCard(),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Responsive stat row ─────────────────────────────────────────────────────

class _ResponsiveStatRow extends StatelessWidget {
  const _ResponsiveStatRow({required this.cards});
  final List<Widget> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        if (constraints.maxWidth < 520) {
          final w = (constraints.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: cards.map((c) => SizedBox(width: w, child: c)).toList(),
          );
        }
        return Row(
          children: [
            for (int i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(width: 16),
              Expanded(child: cards[i]),
            ],
          ],
        );
      },
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.onViewUsers});
  final VoidCallback onViewUsers;

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    final titleCol = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Admin Overview', style: AppTextStyles.headlineLg),
        const SizedBox(height: 4),
        Text('Estadísticas de la plataforma en tiempo real',
            style: AppTextStyles.bodyLg
                .copyWith(color: AppColors.onSurfaceVariant)),
      ],
    );

    final downloadBtn = BlocBuilder<AdminCubit, AdminState>(
      buildWhen: (p, c) => p.isDownloadingReport != c.isDownloadingReport,
      builder: (context, state) => OutlinedButton.icon(
        onPressed: state.isDownloadingReport
            ? null
            : () => context.read<AdminCubit>().downloadReport(),
        icon: state.isDownloadingReport
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Symbols.download, size: 18),
        label: const Text('Reporte'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.secondary,
          side: const BorderSide(color: AppColors.secondary),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );

    final usersBtn = ElevatedButton.icon(
      onPressed: onViewUsers,
      icon: const Icon(Symbols.group, size: 18),
      label: const Text('Gestionar Usuarios'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.onTertiaryContainer,
        foregroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleCol,
          const SizedBox(height: 16),
          Row(
            children: [
              downloadBtn,
              const SizedBox(width: 10),
              Expanded(child: usersBtn),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: titleCol),
        const SizedBox(width: 12),
        downloadBtn,
        const SizedBox(width: 10),
        usersBtn,
      ],
    );
  }
}

// ─── Section title ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.secondary),
        const SizedBox(width: 8),
        Text(label,
            style: AppTextStyles.headlineMd.copyWith(fontSize: 17)),
      ],
    );
  }
}

// ─── Stat card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
    required this.bgColor,
    this.sub,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;
  final Color bgColor;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: bgColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value,
                    style: AppTextStyles.headlineMd
                        .copyWith(fontSize: 26, height: 1.1)),
                Text(label,
                    style: AppTextStyles.labelSm
                        .copyWith(color: AppColors.onSurfaceVariant)),
                if (sub != null) ...[
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Symbols.trending_up,
                        size: 11, color: AppColors.onTertiaryContainer),
                    const SizedBox(width: 3),
                    Text(sub!,
                        style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.onTertiaryContainer,
                            fontSize: 10)),
                  ]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Matching card ────────────────────────────────────────────────────────────

class _MatchingCard extends StatelessWidget {
  const _MatchingCard({required this.s});
  final AdminStats? s;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(icon: Symbols.auto_awesome, label: 'Matching IA'),
          const SizedBox(height: 16),
          _RowStat('Total matches', '${s?.totalMatches ?? 0}'),
          _RowStat('Test enviados', '${s?.matchesTestSent ?? 0}'),
          _RowStat('Test completados', '${s?.matchesTestCompleted ?? 0}',
              color: AppColors.onTertiaryContainer),
          _RowStat('Seleccionados', '${s?.matchesSelected ?? 0}',
              color: AppColors.onTertiaryContainer),
          _RowStat('Rechazados', '${s?.matchesRejected ?? 0}',
              color: AppColors.error),
        ],
      ),
    );
  }
}

// ─── Tests card ───────────────────────────────────────────────────────────────

class _TestsCard extends StatelessWidget {
  const _TestsCard({required this.s});
  final AdminStats? s;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(icon: Symbols.assignment, label: 'Tests Técnicos'),
          const SizedBox(height: 16),
          _RowStat('Tests activos', '${s?.activeTests ?? 0}'),
          _RowStat('Pendientes evaluación', '${s?.pendingSubmissions ?? 0}',
              color: const Color(0xFFF59E0B)),
          _RowStat('Evaluados', '${s?.submissionsEvaluated ?? 0}',
              color: AppColors.onTertiaryContainer),
          _RowStat('Expirados', '${s?.submissionsExpired ?? 0}',
              color: AppColors.error),
          const SizedBox(height: 8),
          _ScoreBar(score: s?.averageTestScore ?? 0),
        ],
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.score});
  final double score;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Score promedio',
                style: AppTextStyles.labelSm
                    .copyWith(color: AppColors.onSurfaceVariant)),
            Text('${score.toStringAsFixed(1)}%',
                style: AppTextStyles.labelBold
                    .copyWith(color: AppColors.secondary)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score / 100,
            backgroundColor: AppColors.surfaceVariant,
            color: AppColors.secondary,
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

// ─── Revenue card ─────────────────────────────────────────────────────────────

class _RevenueCard extends StatelessWidget {
  const _RevenueCard({required this.s});
  final AdminStats? s;

  String _formatCop(double v) {
    if (v >= 1000000) return '\$${(v / 1000000).toStringAsFixed(2)}M COP';
    if (v >= 1000) return '\$${(v / 1000).toStringAsFixed(0)}K COP';
    return '\$${v.toStringAsFixed(0)} COP';
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(icon: Symbols.payments, label: 'Ingresos'),
          const SizedBox(height: 16),
          Text(
            _formatCop(s?.totalRevenueCop ?? 0),
            style: AppTextStyles.headlineLg
                .copyWith(color: AppColors.onTertiaryContainer, fontSize: 28),
          ),
          Text('ingresos totales',
              style: AppTextStyles.labelSm
                  .copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 12),
          _RowStat('Pagos completados', '${s?.paymentsCompleted ?? 0}',
              color: AppColors.onTertiaryContainer),
          _RowStat('Pagos pendientes', '${s?.paymentsPending ?? 0}',
              color: const Color(0xFFF59E0B)),
        ],
      ),
    );
  }
}

// ─── Rates card ───────────────────────────────────────────────────────────────

class _RatesCard extends StatelessWidget {
  const _RatesCard({required this.s});
  final AdminStats? s;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(icon: Symbols.analytics, label: 'Tasas de Rendimiento'),
          const SizedBox(height: 16),
          _RateBar(
            label: 'Tasa completitud de tests',
            tooltip:
                'Submissions evaluadas vs (evaluadas + expiradas)',
            value: (s?.testCompletionRate ?? 0) / 100,
            percent: s?.testCompletionRate ?? 0,
            color: AppColors.onTertiaryContainer,
          ),
          const SizedBox(height: 16),
          _RateBar(
            label: 'Tasa de selección',
            tooltip:
                'Seleccionados vs (testCompleted + selected + rejected)',
            value: (s?.selectionRate ?? 0) / 100,
            percent: s?.selectionRate ?? 0,
            color: AppColors.secondary,
          ),
        ],
      ),
    );
  }
}

class _RateBar extends StatelessWidget {
  const _RateBar({
    required this.label,
    required this.tooltip,
    required this.value,
    required this.percent,
    required this.color,
  });
  final String label;
  final String tooltip;
  final double value;
  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label,
                  style: AppTextStyles.labelBold.copyWith(fontSize: 13)),
            ),
            Tooltip(
              message: tooltip,
              child: const Icon(Symbols.info,
                  size: 14, color: AppColors.outline),
            ),
            const SizedBox(width: 8),
            Text('${percent.toStringAsFixed(1)}%',
                style: AppTextStyles.labelBold.copyWith(color: color)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            backgroundColor: AppColors.surfaceVariant,
            color: color,
            minHeight: 10,
          ),
        ),
      ],
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.secondary),
        const SizedBox(width: 8),
        Text(label, style: AppTextStyles.headlineMd.copyWith(fontSize: 16)),
      ],
    );
  }
}

class _RowStat extends StatelessWidget {
  const _RowStat(this.label, this.value, {this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyles.bodyMd
                  .copyWith(color: AppColors.onSurfaceVariant, fontSize: 13)),
          Text(value,
              style: AppTextStyles.labelBold.copyWith(
                  fontSize: 14,
                  color: color ?? AppColors.onSurface)),
        ],
      ),
    );
  }
}
