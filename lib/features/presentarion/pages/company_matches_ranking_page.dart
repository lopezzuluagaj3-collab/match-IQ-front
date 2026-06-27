import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../config/router/app_routes.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../domain/entities/company.dart';
import '../../domain/entities/job_offer.dart';
import '../../domain/entities/user.dart';
import '../bloc/company_cubit.dart';
import '../widgets/shared/app_card.dart';
import '../widgets/shared/app_sidebar.dart';

class CompanyMatchesRankingPage extends StatefulWidget {
  const CompanyMatchesRankingPage({super.key});

  @override
  State<CompanyMatchesRankingPage> createState() =>
      _CompanyMatchesRankingPageState();
}

class _CompanyMatchesRankingPageState extends State<CompanyMatchesRankingPage> {
  final Set<int> _selectedMatchIds = {};

  @override
  void initState() {
    super.initState();
    context.read<CompanyCubit>().loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithSidebar(
      currentRoute: AppRoutes.companyMatches,
      role: UserRole.company,
      child: BlocBuilder<CompanyCubit, CompanyState>(
        builder: (context, state) {
          final sorted = [...state.matches]
            ..sort((a, b) => b.matchScore.compareTo(a.matchScore));
          final newMatches = sorted
              .where((m) => m.status == MatchStatus.new_)
              .toList();
          final canSendBulk = _selectedMatchIds.isNotEmpty &&
              _selectedMatchIds
                  .every((id) => newMatches.any((m) => m.matchId == id));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AI Talent Ranking', style: AppTextStyles.headlineLg),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Symbols.auto_awesome,
                                  size: 16, color: AppColors.onTertiaryContainer),
                              const SizedBox(width: 6),
                              Text(
                                  'Candidates ranked by AI match score for your open positions',
                                  style: AppTextStyles.bodyMd
                                      .copyWith(color: AppColors.onSurfaceVariant)),
                            ],
                          ),
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
                          const Icon(Symbols.auto_awesome,
                              size: 16, color: AppColors.onTertiaryContainer),
                          const SizedBox(width: 6),
                          Text('AI Powered',
                              style: AppTextStyles.labelBold
                                  .copyWith(color: AppColors.onTertiaryContainer)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Offer selector + bulk actions
                Row(
                  children: [
                    // Offer dropdown
                    if (state.offers.isNotEmpty)
                      _OfferSelector(
                        offers: state.offers,
                        selectedId: state.selectedOfferId,
                        onSelected: (id) {
                          setState(() => _selectedMatchIds.clear());
                          context.read<CompanyCubit>().loadOfferMatches(id);
                        },
                      ),
                    const Spacer(),
                    if (canSendBulk)
                      ElevatedButton.icon(
                        onPressed: state.isSaving
                            ? null
                            : () {
                                context
                                    .read<CompanyCubit>()
                                    .sendTests(_selectedMatchIds.toList())
                                    .then((_) {
                                  setState(() => _selectedMatchIds.clear());
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Tests sent!'),
                                        backgroundColor: AppColors.onTertiaryContainer),
                                  );
                                });
                              },
                        icon: const Icon(Symbols.send, size: 16),
                        label: Text('Send Test (${_selectedMatchIds.length})'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.onTertiaryContainer,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                if (state.isLoading)
                  const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.onTertiaryContainer))
                else if (sorted.isEmpty)
                  _EmptyState(hasOffer: state.selectedOfferId != null)
                else
                  ...sorted.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _CandidateMatchCard(
                          rank: e.key + 1,
                          match: e.value,
                          isSelected: _selectedMatchIds.contains(e.value.matchId),
                          onToggleSelect: (id) => setState(() {
                            if (_selectedMatchIds.contains(id)) {
                              _selectedMatchIds.remove(id);
                            } else {
                              _selectedMatchIds.add(id);
                            }
                          }),
                          onSendTest: (id) {
                            context.read<CompanyCubit>().sendTests([id]).then((_) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Test sent!'),
                                    backgroundColor: AppColors.onTertiaryContainer),
                              );
                            });
                          },
                          onSelect: (id) => context.read<CompanyCubit>().selectCandidate(id),
                          onReject: (id) => context.read<CompanyCubit>().rejectCandidate(id),
                        ),
                      )),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OfferSelector extends StatelessWidget {
  const _OfferSelector({
    required this.offers,
    required this.selectedId,
    required this.onSelected,
  });
  final List<JobOffer> offers;
  final int? selectedId;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: DropdownButtonFormField<int>(
        value: selectedId,
        decoration: InputDecoration(
          hintText: 'Filter by offer',
          prefixIcon: const Icon(Symbols.work, size: 18),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.outlineVariant),
          ),
        ),
        items: offers
            .map((o) => DropdownMenuItem(
                  value: int.tryParse(o.id),
                  child: Text(o.title,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelSm),
                ))
            .toList(),
        onChanged: (v) {
          if (v != null) onSelected(v);
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasOffer});
  final bool hasOffer;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64),
        child: Column(
          children: [
            const Icon(Symbols.group_search, size: 56, color: AppColors.outlineVariant),
            const SizedBox(height: 16),
            Text(
              hasOffer ? 'No candidates for this offer yet.' : 'Select an offer to view matches.',
              style: AppTextStyles.bodyLg.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _CandidateMatchCard extends StatelessWidget {
  const _CandidateMatchCard({
    required this.rank,
    required this.match,
    required this.isSelected,
    required this.onToggleSelect,
    required this.onSendTest,
    required this.onSelect,
    required this.onReject,
  });

  final int rank;
  final CandidateMatch match;
  final bool isSelected;
  final ValueChanged<int> onToggleSelect;
  final ValueChanged<int> onSendTest;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onReject;

  @override
  Widget build(BuildContext context) {
    final rankColor = switch (rank) {
      1 => const Color(0xFFFFD700),
      2 => const Color(0xFFC0C0C0),
      3 => const Color(0xFFCD7F32),
      _ => AppColors.outlineVariant,
    };

    final isRejected = match.status == MatchStatus.rejected;

    return AppCard(
      borderColor: isSelected
          ? AppColors.onTertiaryContainer.withOpacity(0.4)
          : (rank <= 3 ? rankColor.withOpacity(0.3) : null),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main row
          Row(
            children: [
              // Select checkbox (only for new_ candidates)
              if (match.canSendTest)
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => onToggleSelect(match.matchId),
                  activeColor: AppColors.onTertiaryContainer,
                  side: const BorderSide(color: AppColors.outlineVariant),
                ),
              if (!match.canSendTest) const SizedBox(width: 8),
              // Rank badge
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: rank <= 3
                      ? rankColor.withOpacity(0.15)
                      : AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text('#$rank',
                      style: AppTextStyles.labelBold.copyWith(
                          color: rank <= 3 ? rankColor : AppColors.outline)),
                ),
              ),
              const SizedBox(width: 14),
              // Avatar
              Opacity(
                opacity: isRejected ? 0.4 : 1.0,
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.secondaryContainer.withOpacity(0.4),
                  child: Text(match.candidateName[0],
                      style: AppTextStyles.headlineMd
                          .copyWith(color: AppColors.secondary, fontSize: 18)),
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(match.candidateName,
                            style: AppTextStyles.labelBold.copyWith(
                                color: isRejected ? AppColors.outline : AppColors.onSurface)),
                        const SizedBox(width: 8),
                        _StatusPill(status: match.status),
                      ],
                    ),
                    Text(match.headline,
                        style: AppTextStyles.labelSm
                            .copyWith(color: AppColors.onSurfaceVariant)),
                    if (match.email != null) ...[
                      const SizedBox(height: 2),
                      Text(match.email!,
                          style: AppTextStyles.labelSm
                              .copyWith(color: AppColors.secondary, fontSize: 11)),
                    ],
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: match.skills
                          .take(3)
                          .map((s) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(s,
                                    style: AppTextStyles.labelSm.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                        fontSize: 11)),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Scores
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.onTertiaryContainer.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text('${match.matchScore}%',
                            style: AppTextStyles.headlineMd.copyWith(
                                color: AppColors.onTertiaryContainer, fontSize: 22)),
                        Text('Match',
                            style: AppTextStyles.labelSm
                                .copyWith(color: AppColors.onTertiaryContainer)),
                      ],
                    ),
                  ),
                  if (match.testScore != null) ...[
                    const SizedBox(height: 6),
                    Text('Test: ${match.testScore}/100',
                        style: AppTextStyles.labelSm
                            .copyWith(color: AppColors.outline)),
                  ],
                  if (match.testFeedback != null) ...[
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 110,
                      child: Text(
                        match.testFeedback!,
                        style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.onSurfaceVariant, fontSize: 10),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 16),
              // Actions
              if (!isRejected)
                _ActionButtons(
                  match: match,
                  onSendTest: () => onSendTest(match.matchId),
                  onSelect: () => onSelect(match.matchId),
                  onReject: () => onReject(match.matchId),
                )
              else
                const SizedBox(
                  width: 100,
                  child: Center(
                    child: Text('Rejected',
                        style: TextStyle(color: AppColors.error, fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
            ],
          ),
          // AI Insight section
          if (match.aiInsight != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.onTertiaryContainer.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Symbols.auto_awesome,
                          size: 14, color: AppColors.onTertiaryContainer),
                      const SizedBox(width: 6),
                      Text('AI Insight',
                          style: AppTextStyles.labelSm
                              .copyWith(color: AppColors.onTertiaryContainer,
                                  fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(match.aiInsight!,
                      style: AppTextStyles.labelSm
                          .copyWith(color: AppColors.onSurface)),
                  if (match.aiStrengths.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6, runSpacing: 4,
                      children: [
                        ...match.aiStrengths.map((s) => _AiTag(label: s, positive: true)),
                        ...match.aiOpportunities.map((s) => _AiTag(label: s, positive: false)),
                      ],
                    ),
                  ],
                  if (match.aiRecommendation != null) ...[
                    const SizedBox(height: 8),
                    Text(match.aiRecommendation!,
                        style: AppTextStyles.labelSm
                            .copyWith(color: AppColors.onSurfaceVariant,
                                fontStyle: FontStyle.italic)),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.match,
    required this.onSendTest,
    required this.onSelect,
    required this.onReject,
  });
  final CandidateMatch match;
  final VoidCallback onSendTest;
  final VoidCallback onSelect;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (match.canSendTest)
          ElevatedButton(
            onPressed: onSendTest,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.onTertiaryContainer,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: const Text('Send Test', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        if (match.canSelect) ...[
          ElevatedButton(
            onPressed: onSelect,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.onTertiaryContainer,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: const Text('Select', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 6),
        ],
        if (match.canReject)
          OutlinedButton(
            onPressed: onReject,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.error),
              foregroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: const Text('Reject', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        if (match.status == MatchStatus.shortlisted)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.onTertiaryContainer.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('Selected',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onTertiaryContainer)),
          ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final MatchStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      MatchStatus.new_ => ('New', AppColors.secondary),
      MatchStatus.reviewed => ('Reviewed', AppColors.outline),
      MatchStatus.shortlisted => ('Selected', AppColors.onTertiaryContainer),
      MatchStatus.rejected => ('Rejected', AppColors.error),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(label,
          style: AppTextStyles.labelSm.copyWith(color: color, fontSize: 10)),
    );
  }
}

class _AiTag extends StatelessWidget {
  const _AiTag({required this.label, required this.positive});
  final String label;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final color = positive ? AppColors.onTertiaryContainer : AppColors.outline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(positive ? Symbols.check : Symbols.arrow_upward,
              size: 10, color: color),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.labelSm.copyWith(color: color, fontSize: 10)),
        ],
      ),
    );
  }
}
