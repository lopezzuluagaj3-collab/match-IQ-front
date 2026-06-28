import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../config/router/app_routes.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../domain/entities/company.dart';
import '../../domain/entities/company_dashboard_stats.dart';
import '../../domain/entities/user.dart';
import '../bloc/company_cubit.dart';
import '../widgets/shared/app_card.dart';
import '../widgets/shared/app_sidebar.dart';

class CompanyDashboardPage extends StatefulWidget {
  const CompanyDashboardPage({super.key});

  @override
  State<CompanyDashboardPage> createState() => _CompanyDashboardPageState();
}

class _CompanyDashboardPageState extends State<CompanyDashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<CompanyCubit>().loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithSidebar(
      currentRoute: AppRoutes.companyDashboard,
      role: UserRole.company,
      child: BlocBuilder<CompanyCubit, CompanyState>(
        builder: (context, state) {
          if (state.isLoading && state.dashboard == null) {
            return const Center(
                child: CircularProgressIndicator(
                    color: AppColors.onTertiaryContainer));
          }
          final dash = state.dashboard;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(profile: state.profile),
                const SizedBox(height: 32),

                if (dash == null) ...[
                  _EmptyDashboard(
                    onRetry: () =>
                        context.read<CompanyCubit>().loadDashboard(),
                  ),
                ] else ...[
                  // ── Offers section ──────────────────────────────────────
                  _SectionLabel(
                    icon: Symbols.work,
                    title: 'Ofertas',
                    subtitle: '${dash.offers.total} en total',
                  ),
                  const SizedBox(height: 12),
                  _OffersRow(offers: dash.offers),
                  const SizedBox(height: 28),

                  // ── Matches section ──────────────────────────────────────
                  _SectionLabel(
                    icon: Symbols.group,
                    title: 'Candidatos',
                    subtitle: '${dash.matches.total} matches totales',
                  ),
                  const SizedBox(height: 12),
                  _MatchesCard(matches: dash.matches),
                  const SizedBox(height: 28),

                  // ── Tests section ────────────────────────────────────────
                  _SectionLabel(
                    icon: Symbols.assignment,
                    title: 'Tests',
                    subtitle: '${dash.tests.sent} enviados',
                  ),
                  const SizedBox(height: 12),
                  _TestsCard(tests: dash.tests),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.profile});
  final CompanyProfile? profile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bienvenida, ${profile?.name ?? 'Empresa'}',
                style: AppTextStyles.headlineLg,
              ),
              const SizedBox(height: 4),
              Text(
                'Aquí tienes el resumen de tu actividad en la plataforma.',
                style: AppTextStyles.bodyLg
                    .copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () => context.go(AppRoutes.createOffer),
          icon: const Icon(Symbols.add, size: 18),
          label: const Text('Nueva Oferta'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.onTertiaryContainer,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
      ],
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.secondary),
        const SizedBox(width: 8),
        Text(title, style: AppTextStyles.headlineMd),
        const SizedBox(width: 10),
        Text(subtitle,
            style: AppTextStyles.bodyMd
                .copyWith(color: AppColors.onSurfaceVariant)),
      ],
    );
  }
}

// ─── Offers row ───────────────────────────────────────────────────────────────

class _OffersRow extends StatelessWidget {
  const _OffersRow({required this.offers});
  final CompanyDashboardOffers offers;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: '${offers.open}',
            label: 'Activas',
            icon: Symbols.circle,
            color: AppColors.onTertiaryContainer,
            note: 'Acumulando candidatos',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            value: '${offers.testSent}',
            label: 'Test enviado',
            icon: Symbols.send,
            color: AppColors.secondary,
            note: 'En evaluación',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            value: '${offers.completed}',
            label: 'Completadas',
            icon: Symbols.check_circle,
            color: AppColors.primary,
            note: 'Proceso finalizado',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            value: '${offers.pendingPayment}',
            label: 'Sin pagar',
            icon: Symbols.payment,
            color: const Color(0xFFF59E0B),
            note: offers.pendingPayment > 0 ? 'Requieren pago' : 'Todo al día',
          ),
        ),
        if (offers.cancelled > 0 || offers.expired > 0) ...[
          const SizedBox(width: 16),
          Expanded(
            child: _StatCard(
              value: '${offers.cancelled + offers.expired}',
              label: 'Canceladas/Expiradas',
              icon: Symbols.cancel,
              color: AppColors.error,
              note: '${offers.cancelled} canceladas · ${offers.expired} expiradas',
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Matches card ─────────────────────────────────────────────────────────────

class _MatchesCard extends StatelessWidget {
  const _MatchesCard({required this.matches});
  final CompanyDashboardMatches matches;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI row
          Row(
            children: [
              _InlineKpi(
                value: '${matches.total}',
                label: 'Total matches',
                color: AppColors.primary,
              ),
              _Divider(),
              _InlineKpi(
                value: '${matches.testSent}',
                label: 'Test enviado',
                color: AppColors.secondary,
              ),
              _Divider(),
              _InlineKpi(
                value: '${matches.testCompleted}',
                label: 'Test completado',
                color: AppColors.onTertiaryContainer,
              ),
              _Divider(),
              _InlineKpi(
                value: '${matches.selected}',
                label: 'Seleccionados',
                color: AppColors.onTertiaryContainer,
              ),
              _Divider(),
              _InlineKpi(
                value: '${matches.rejected}',
                label: 'Rechazados',
                color: AppColors.error,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Selection rate bar
          _RateBar(
            label: 'Tasa de selección',
            value: matches.selectionRate / 100,
            formatted: '${matches.selectionRate.toStringAsFixed(1)}%',
            color: AppColors.onTertiaryContainer,
            tooltip:
                '${matches.selected} seleccionados de ${matches.testSent} que recibieron el test',
          ),

          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => context.go(AppRoutes.companyMatches),
              icon: const Icon(Symbols.arrow_forward,
                  size: 15, color: AppColors.secondary),
              label: Text('Ver todas las ofertas',
                  style: AppTextStyles.labelBold
                      .copyWith(color: AppColors.secondary)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tests card ───────────────────────────────────────────────────────────────

class _TestsCard extends StatelessWidget {
  const _TestsCard({required this.tests});
  final CompanyDashboardTests tests;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI row
          Row(
            children: [
              _InlineKpi(
                value: '${tests.sent}',
                label: 'Enviados',
                color: AppColors.secondary,
              ),
              _Divider(),
              _InlineKpi(
                value: '${tests.completed}',
                label: 'Completados',
                color: AppColors.onTertiaryContainer,
              ),
              _Divider(),
              _InlineKpi(
                value: '${tests.evaluated}',
                label: 'Evaluados por IA',
                color: AppColors.onTertiaryContainer,
              ),
              _Divider(),
              _InlineKpi(
                value: '${tests.expired}',
                label: 'Expirados',
                color: AppColors.error,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Completion rate
          _RateBar(
            label: 'Tasa de completación',
            value: tests.completionRate / 100,
            formatted: '${tests.completionRate.toStringAsFixed(1)}%',
            color: AppColors.secondary,
            tooltip:
                '${tests.completed} completados de ${tests.sent} enviados',
          ),
          const SizedBox(height: 12),

          // Average score
          if (tests.evaluated > 0 && tests.averageScore != null)
            _AverageScoreBar(score: tests.averageScore!)
          else
            _EmptyScore(),
        ],
      ),
    );
  }
}

class _AverageScoreBar extends StatelessWidget {
  const _AverageScoreBar({required this.score});
  final double score;

  Color get _color {
    if (score >= 80) return AppColors.onTertiaryContainer;
    if (score >= 60) return AppColors.secondary;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Symbols.auto_awesome,
                size: 14, color: AppColors.onTertiaryContainer),
            const SizedBox(width: 6),
            Text('Puntaje promedio IA',
                style: AppTextStyles.labelBold
                    .copyWith(color: AppColors.onSurfaceVariant, fontSize: 12)),
            const Spacer(),
            Text(
              score.toStringAsFixed(1),
              style: AppTextStyles.headlineMd
                  .copyWith(color: _color, fontSize: 20),
            ),
            Text(' / 100',
                style: AppTextStyles.labelSm
                    .copyWith(color: AppColors.outline, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: score / 100,
            backgroundColor:
                AppColors.outlineVariant.withValues(alpha: 0.25),
            valueColor: AlwaysStoppedAnimation(_color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

class _EmptyScore extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Symbols.hourglass_empty,
              size: 16, color: AppColors.outline),
          const SizedBox(width: 10),
          Text(
            'Aún no hay tests evaluados por la IA.',
            style: AppTextStyles.bodyMd
                .copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ─── Rate bar ─────────────────────────────────────────────────────────────────

class _RateBar extends StatelessWidget {
  const _RateBar({
    required this.label,
    required this.value,
    required this.formatted,
    required this.color,
    required this.tooltip,
  });
  final String label;
  final double value;
  final String formatted;
  final Color color;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Tooltip(
              message: tooltip,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style: AppTextStyles.labelBold.copyWith(
                          color: AppColors.onSurfaceVariant, fontSize: 12)),
                  const SizedBox(width: 4),
                  const Icon(Symbols.info,
                      size: 12, color: AppColors.outline),
                ],
              ),
            ),
            const Spacer(),
            Text(formatted,
                style: AppTextStyles.labelBold
                    .copyWith(color: color, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            backgroundColor:
                AppColors.outlineVariant.withValues(alpha: 0.25),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

// ─── Stat card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.note,
  });
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final String note;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 14),
          Text(value,
              style: AppTextStyles.display
                  .copyWith(fontSize: 36, height: 1.1, color: AppColors.onSurface)),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyles.labelBold
                  .copyWith(color: AppColors.onSurface, fontSize: 13)),
          const SizedBox(height: 4),
          Text(note,
              style: AppTextStyles.labelSm
                  .copyWith(color: AppColors.onSurfaceVariant, fontSize: 11)),
        ],
      ),
    );
  }
}

// ─── Inline KPI ───────────────────────────────────────────────────────────────

class _InlineKpi extends StatelessWidget {
  const _InlineKpi(
      {required this.value, required this.label, required this.color});
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: AppTextStyles.headlineMd
                  .copyWith(color: color, fontSize: 26, height: 1.1)),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.onSurfaceVariant, fontSize: 12)),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: AppColors.outlineVariant.withValues(alpha: 0.4),
    );
  }
}

// ─── Empty / error states ─────────────────────────────────────────────────────

class _EmptyDashboard extends StatelessWidget {
  const _EmptyDashboard({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            const Icon(Symbols.bar_chart,
                size: 48, color: AppColors.outlineVariant),
            const SizedBox(height: 12),
            Text('No se pudo cargar el dashboard.',
                style: AppTextStyles.bodyLg
                    .copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Symbols.refresh, size: 16),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.onTertiaryContainer,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
