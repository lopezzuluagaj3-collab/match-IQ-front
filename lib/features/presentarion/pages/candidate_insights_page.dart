import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../config/router/app_routes.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../config/theme/responsive.dart';
import '../../domain/entities/market_analytics.dart';
import '../../domain/entities/user.dart';
import '../bloc/analytics_cubit.dart';
import '../widgets/shared/app_card.dart';
import '../widgets/shared/app_sidebar.dart';

class CandidateInsightsPage extends StatefulWidget {
  const CandidateInsightsPage({super.key});

  @override
  State<CandidateInsightsPage> createState() => _CandidateInsightsPageState();
}

class _CandidateInsightsPageState extends State<CandidateInsightsPage> {
  @override
  void initState() {
    super.initState();
    context.read<AnalyticsCubit>().loadInsights();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithSidebar(
      currentRoute: AppRoutes.candidateInsights,
      role: UserRole.candidate,
      child: BlocBuilder<AnalyticsCubit, AnalyticsState>(
        builder: (context, state) {
          if (state.isLoadingInsights && state.insights == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.onTertiaryContainer),
            );
          }

          if (state.error != null && state.insights == null) {
            return _ErrorView(
              message: state.error!,
              onRetry: () => context.read<AnalyticsCubit>().loadInsights(),
            );
          }

          final data = state.insights;
          if (data == null) return const SizedBox.shrink();

          return SingleChildScrollView(
            padding: Responsive.pagePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PageHeader(),
                const SizedBox(height: 28),
                if (data.skillsInDemand.isNotEmpty || data.skillGaps.isNotEmpty) ...[
                  _SummaryRow(
                    strengths: data.skillsInDemand,
                    gaps: data.skillGaps,
                  ),
                  const SizedBox(height: 28),
                ],
                LayoutBuilder(
                  builder: (_, constraints) {
                    if (constraints.maxWidth < 700) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DemandSection(items: data.topDemand),
                          const SizedBox(height: 28),
                          _CombinationsSection(items: data.topCombinations),
                          const SizedBox(height: 28),
                          _SupplySection(items: data.topSupply),
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _DemandSection(items: data.topDemand),
                              const SizedBox(height: 28),
                              _CombinationsSection(items: data.topCombinations),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        SizedBox(
                          width: 280,
                          child: _SupplySection(items: data.topSupply),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Market Insights', style: AppTextStyles.headlineLg),
        const SizedBox(height: 4),
        Text(
          'How your profile compares to what the market demands right now.',
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }
}

// ─── Summary row (strengths + gaps) ──────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.strengths, required this.gaps});
  final List<String> strengths;
  final List<String> gaps;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            children: [
              if (strengths.isNotEmpty) _SummaryCard(
                icon: Symbols.check_circle,
                iconColor: const Color(0xFF059669),
                bgColor: const Color(0xFFD1FAE5),
                title: 'Your strengths',
                subtitle: 'Skills the market is looking for that you already have',
                chips: strengths,
                chipColor: const Color(0xFF059669),
                chipBg: const Color(0xFFD1FAE5),
              ),
              if (strengths.isNotEmpty && gaps.isNotEmpty) const SizedBox(height: 16),
              if (gaps.isNotEmpty) _SummaryCard(
                icon: Symbols.trending_up,
                iconColor: const Color(0xFFD97706),
                bgColor: const Color(0xFFFEF3C7),
                title: 'Market gaps',
                subtitle: 'Top demanded skills you could add',
                chips: gaps,
                chipColor: const Color(0xFFD97706),
                chipBg: const Color(0xFFFEF3C7),
              ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (strengths.isNotEmpty)
              Expanded(
                child: _SummaryCard(
                  icon: Symbols.check_circle,
                  iconColor: const Color(0xFF059669),
                  bgColor: const Color(0xFFD1FAE5),
                  title: 'Tus fortalezas',
                  subtitle: 'Skills que el mercado busca y ya tienes',
                  chips: strengths,
                  chipColor: const Color(0xFF059669),
                  chipBg: const Color(0xFFD1FAE5),
                ),
              ),
            if (strengths.isNotEmpty && gaps.isNotEmpty) const SizedBox(width: 16),
            if (gaps.isNotEmpty)
              Expanded(
                child: _SummaryCard(
                  icon: Symbols.trending_up,
                  iconColor: const Color(0xFFD97706),
                  bgColor: const Color(0xFFFEF3C7),
                  title: 'Market gaps',
                  subtitle: 'Top demanded skills you could add',
                  chips: gaps,
                  chipColor: const Color(0xFFD97706),
                  chipBg: const Color(0xFFFEF3C7),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.subtitle,
    required this.chips,
    required this.chipColor,
    required this.chipBg,
  });

  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String subtitle;
  final List<String> chips;
  final Color chipColor;
  final Color chipBg;

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
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.labelBold),
                    Text(subtitle,
                        style: AppTextStyles.labelSm
                            .copyWith(color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips
                .map((s) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: chipBg,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: chipColor.withOpacity(0.3)),
                      ),
                      child: Text(s,
                          style: AppTextStyles.labelSm
                              .copyWith(color: chipColor, fontWeight: FontWeight.w600)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Top Demand ──────────────────────────────────────────────────────────────

class _DemandSection extends StatelessWidget {
  const _DemandSection({required this.items});
  final List<MarketSkillDemand> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Top demanded skills', style: AppTextStyles.headlineMd),
        const SizedBox(height: 4),
        Text('Based on active and completed offers on the platform',
            style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 16),
        ...items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _DemandItem(item: item, rank: i + 1, maxCount: items.first.offerCount),
          );
        }),
      ],
    );
  }
}

class _DemandItem extends StatelessWidget {
  const _DemandItem({required this.item, required this.rank, required this.maxCount});
  final MarketSkillDemand item;
  final int rank;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    final hasSkill = item.candidateHasSkill;
    final level = item.candidateLevel;
    final progress = maxCount > 0 ? item.offerCount / maxCount : 0.0;

    final Color rankColor;
    if (rank == 1) {
      rankColor = const Color(0xFFD97706);
    } else if (rank == 2) {
      rankColor = const Color(0xFF9CA3AF);
    } else if (rank == 3) {
      rankColor = const Color(0xFFB45309);
    } else {
      rankColor = AppColors.outline;
    }

    return AppCard(
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '#$rank',
              style: AppTextStyles.labelBold.copyWith(color: rankColor),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.skillName, style: AppTextStyles.labelBold),
                          Text(item.categoryName,
                              style: AppTextStyles.labelSm
                                  .copyWith(color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (hasSkill == true) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Symbols.check_circle,
                                size: 13, color: Color(0xFF059669)),
                            const SizedBox(width: 4),
                            Text(
                              level != null ? 'Level $level/5' : 'You have it',
                              style: AppTextStyles.labelSm.copyWith(
                                  color: const Color(0xFF059669),
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ] else if (hasSkill == false) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Symbols.warning,
                                size: 13, color: Color(0xFFD97706)),
                            const SizedBox(width: 4),
                            Text(
                              'Missing',
                              style: AppTextStyles.labelSm.copyWith(
                                  color: const Color(0xFFD97706),
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Text(
                      '${item.offerCount} offers',
                      style: AppTextStyles.labelSm
                          .copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: AppColors.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      hasSkill == true
                          ? const Color(0xFF059669)
                          : AppColors.onTertiaryContainer,
                    ),
                    minHeight: 5,
                  ),
                ),
                if (hasSkill == true && level != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('Your level: ',
                          style: AppTextStyles.labelSm
                              .copyWith(color: AppColors.onSurfaceVariant)),
                      ...List.generate(
                        5,
                        (i) => Padding(
                          padding: const EdgeInsets.only(right: 3),
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: i < level
                                  ? const Color(0xFF059669)
                                  : AppColors.surfaceVariant,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Combinations ─────────────────────────────────────────────────────────────

class _CombinationsSection extends StatelessWidget {
  const _CombinationsSection({required this.items});
  final List<MarketSkillCombination> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Most requested skill combinations', style: AppTextStyles.headlineMd),
        const SizedBox(height: 4),
        Text('Skill pairs that companies usually require together',
            style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 16),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CombinationItem(item: item),
            )),
      ],
    );
  }
}

class _CombinationItem extends StatelessWidget {
  const _CombinationItem({required this.item});
  final MarketSkillCombination item;

  @override
  Widget build(BuildContext context) {
    final hasBoth = item.candidateHasBoth;
    final hasA = item.candidateHasA;
    final hasB = item.candidateHasB;

    final IconData statusIcon;
    final Color statusColor;
    final Color statusBg;
    final String statusLabel;

    if (hasBoth == true) {
      statusIcon = Symbols.check_circle;
      statusColor = const Color(0xFF059669);
      statusBg = const Color(0xFFD1FAE5);
      statusLabel = 'Complete';
    } else if (hasA == true || hasB == true) {
      statusIcon = Symbols.warning;
      statusColor = const Color(0xFFD97706);
      statusBg = const Color(0xFFFEF3C7);
      final missing = hasA == true ? item.skillB : item.skillA;
      statusLabel = 'Missing $missing';
    } else if (hasBoth != null) {
      statusIcon = Symbols.cancel;
      statusColor = AppColors.error;
      statusBg = AppColors.errorContainer.withOpacity(0.3);
      statusLabel = 'You have neither';
    } else {
      statusIcon = Symbols.info;
      statusColor = AppColors.outline;
      statusBg = AppColors.surfaceVariant;
      statusLabel = '${item.offerCount} offers';
    }

    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(statusIcon, color: statusColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _SkillPill(label: item.skillA, has: hasA),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Symbols.add, size: 14, color: AppColors.outline),
                    ),
                    _SkillPill(label: item.skillB, has: hasB),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  statusLabel,
                  style: AppTextStyles.labelSm.copyWith(color: statusColor, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${item.offerCount}',
            style: AppTextStyles.headlineMd.copyWith(
                color: AppColors.onSurfaceVariant, fontSize: 18),
          ),
          const SizedBox(width: 2),
          Text('offers',
              style: AppTextStyles.labelSm.copyWith(color: AppColors.outline)),
        ],
      ),
    );
  }
}

class _SkillPill extends StatelessWidget {
  const _SkillPill({required this.label, required this.has});
  final String label;
  final bool? has;

  @override
  Widget build(BuildContext context) {
    final color = has == true
        ? const Color(0xFF059669)
        : has == false
            ? const Color(0xFFD97706)
            : AppColors.onSurfaceVariant;
    final bg = has == true
        ? const Color(0xFFD1FAE5)
        : has == false
            ? const Color(0xFFFEF3C7)
            : AppColors.surfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: AppTextStyles.labelSm.copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

// ─── Top Supply ───────────────────────────────────────────────────────────────

class _SupplySection extends StatelessWidget {
  const _SupplySection({required this.items});
  final List<MarketSkillSupply> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final maxCount = items.isEmpty ? 1 : items.first.candidateCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Candidate supply', style: AppTextStyles.headlineMd),
        const SizedBox(height: 4),
        Text('Most common skills among registered candidates',
            style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final progress = maxCount > 0 ? item.candidateCount / maxCount : 0.0;
              return Padding(
                padding: EdgeInsets.only(bottom: i < items.length - 1 ? 14 : 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(item.skillName, style: AppTextStyles.labelBold),
                        ),
                        Text('${item.candidateCount} candidates',
                            style: AppTextStyles.labelSm
                                .copyWith(color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        backgroundColor: AppColors.surfaceVariant,
                        color: AppColors.secondary,
                        minHeight: 5,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ─── Error view ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.errorContainer.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Symbols.error, size: 48, color: AppColors.error),
            ),
            const SizedBox(height: 20),
            Text('Could not load insights', style: AppTextStyles.headlineMd),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Symbols.refresh, size: 18),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.onTertiaryContainer,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
