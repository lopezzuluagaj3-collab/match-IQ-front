import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../config/router/app_routes.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../domain/entities/company.dart';
import '../../domain/entities/job_offer.dart';
import '../../domain/entities/user.dart';
import '../bloc/company_cubit.dart';
import '../../../config/theme/responsive.dart';
import '../widgets/shared/app_card.dart';
import '../widgets/shared/app_sidebar.dart';

class OfferMatchesPage extends StatefulWidget {
  const OfferMatchesPage({super.key, required this.offerId});
  final int offerId;

  @override
  State<OfferMatchesPage> createState() => _OfferMatchesPageState();
}

class _OfferMatchesPageState extends State<OfferMatchesPage> {
  final Set<int> _selectedMatchIds = {};

  @override
  void initState() {
    super.initState();
    context.read<CompanyCubit>().loadOfferMatches(widget.offerId);
  }

  JobOffer? _findOffer(CompanyState state) {
    try {
      return state.offers.firstWhere(
        (o) => int.tryParse(o.id) == widget.offerId,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithSidebar(
      currentRoute: AppRoutes.companyMatches,
      role: UserRole.company,
      child: BlocBuilder<CompanyCubit, CompanyState>(
        builder: (context, state) {
          final offer = _findOffer(state);

          return SingleChildScrollView(
            padding: Responsive.pagePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
                InkWell(
                  onTap: () => context.pop(),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Symbols.arrow_back_ios_new,
                            size: 14, color: AppColors.secondary),
                        const SizedBox(width: 6),
                        Text('Mis Ofertas',
                            style: AppTextStyles.labelBold
                                .copyWith(color: AppColors.secondary)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Offer header
                if (offer != null) _OfferHeader(offer: offer),
                const SizedBox(height: 24),

                // Matching action buttons
                if (offer != null && offer.isOpen)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _MatchingActions(
                      offerId: widget.offerId,
                      hasMatches: state.matches.isNotEmpty,
                      isSaving: state.isSaving,
                    ),
                  ),

                // Loading
                if (state.isLoadingMatches)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: CircularProgressIndicator(
                          color: AppColors.onTertiaryContainer),
                    ),
                  )
                else if (state.matches.isEmpty)
                  _EmptyMatchesState(offer: offer)
                else ...[
                  // Header row
                  _MatchesHeader(
                    matches: state.matches,
                    selectedMatchIds: _selectedMatchIds,
                    isSaving: state.isSaving,
                    onSendBulk: _selectedMatchIds.isEmpty
                        ? null
                        : () async {
                            final ids = _selectedMatchIds.toList();
                            await context
                                .read<CompanyCubit>()
                                .sendTests(ids);
                            if (!context.mounted) return;
                            final error =
                                context.read<CompanyCubit>().state.error;
                            if (error != null) {
                              _showErrorSnackbar(context, error);
                            } else {
                              setState(() => _selectedMatchIds.clear());
                              _showSuccessSnackbar(
                                  context, 'Tests enviados correctamente.');
                            }
                          },
                  ),
                  const SizedBox(height: 12),

                  // Candidate cards
                  ..._sortedMatches(state.matches)
                      .asMap()
                      .entries
                      .map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _CandidateMatchCard(
                              rank: e.key + 1,
                              match: e.value,
                              isSelected: _selectedMatchIds
                                  .contains(e.value.matchId),
                              actingMatchId: state.isActingOnMatchId,
                              onToggleSelect: (id) => setState(() {
                                _selectedMatchIds.contains(id)
                                    ? _selectedMatchIds.remove(id)
                                    : _selectedMatchIds.add(id);
                              }),
                              onSendTest: (id) async {
                                await context
                                    .read<CompanyCubit>()
                                    .sendTests([id]);
                                if (!context.mounted) return;
                                final error =
                                    context.read<CompanyCubit>().state.error;
                                if (error != null) {
                                  _showErrorSnackbar(context, error);
                                } else {
                                  _showSuccessSnackbar(
                                      context, 'Test enviado correctamente.');
                                }
                              },
                              onSelect: (id) => _handleSelect(id),
                              onReject: (id) => _handleReject(id),
                              onViewResults: (id) => context.push(
                                  AppRoutes.matchTestResultsPath(id)),
                            ),
                          )),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleSelect(int matchId) async {
    final match = context.read<CompanyCubit>().state.matches
        .firstWhere((m) => m.matchId == matchId);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm selection'),
        content: Text(
          'Confirm the selection of ${match.candidateName}?\nThey will be notified by email.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.onTertiaryContainer,
            ),
            child: const Text('Select'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<CompanyCubit>().selectCandidate(matchId);
    if (!mounted) return;
    final error = context.read<CompanyCubit>().state.error;
    if (error != null) {
      _showErrorSnackbar(context, error);
    } else {
      _showSuccessSnackbar(context, 'Candidate selected successfully.');
    }
  }

  Future<void> _handleReject(int matchId) async {
    final match = context.read<CompanyCubit>().state.matches
        .firstWhere((m) => m.matchId == matchId);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm rejection'),
        content: Text(
          'Confirm the rejection of ${match.candidateName}?\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<CompanyCubit>().rejectCandidate(matchId);
    if (!mounted) return;
    final error = context.read<CompanyCubit>().state.error;
    if (error != null) {
      _showErrorSnackbar(context, error);
    } else {
      _showSuccessSnackbar(context, 'Candidate rejected.');
    }
  }

  List<CandidateMatch> _sortedMatches(List<CandidateMatch> matches) {
    return [...matches]..sort((a, b) {
        final sa = a.adjustedScore ?? a.matchScore.toDouble();
        final sb = b.adjustedScore ?? b.matchScore.toDouble();
        return sb.compareTo(sa);
      });
  }

  void _showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: AppColors.onTertiaryContainer,
    ));
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          const Icon(Icons.warning_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: AppColors.error,
      duration: const Duration(seconds: 6),
      action: SnackBarAction(
        label: 'OK',
        textColor: Colors.white,
        onPressed: () =>
            ScaffoldMessenger.of(context).hideCurrentSnackBar(),
      ),
    ));
  }
}

// ─── Offer Header ─────────────────────────────────────────────────────────────

class _OfferHeader extends StatelessWidget {
  const _OfferHeader({required this.offer});
  final JobOffer offer;

  Color get _statusColor => switch (offer.status) {
        'PendingPayment' => const Color(0xFFF59E0B),
        'Open' => AppColors.onTertiaryContainer,
        'TestSent' => AppColors.secondary,
        'Completed' => AppColors.outline,
        'Cancelled' || 'Expired' => AppColors.error,
        _ => AppColors.outline,
      };

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Symbols.work,
                color: AppColors.onTertiaryContainer, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(offer.title,
                          style: AppTextStyles.headlineMd
                              .copyWith(fontSize: 18),
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 10),
                    _StatusBadge(
                        label: offer.statusLabel, color: _statusColor),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 12,
                  children: [
                    _MetaChip(icon: Symbols.payments, label: offer.salary),
                    _MetaChip(
                        icon: Symbols.location_on,
                        label: offer.modeLabel),
                    if (offer.tierName != null)
                      _MetaChip(
                          icon: Symbols.star, label: offer.tierName!),
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

// ─── Matching actions ─────────────────────────────────────────────────────────

class _MatchingActions extends StatelessWidget {
  const _MatchingActions({
    required this.offerId,
    required this.hasMatches,
    required this.isSaving,
  });
  final int offerId;
  final bool hasMatches;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed:
              isSaving ? null : () => context.read<CompanyCubit>().runMatching(offerId),
          icon: const Icon(Symbols.play_arrow, size: 14),
          label: const Text('Run Matching'),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.secondary),
            foregroundColor: AppColors.secondary,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
        if (hasMatches)
          OutlinedButton.icon(
            onPressed: isSaving
                ? null
                : () => context
                    .read<CompanyCubit>()
                    .reevaluateMatching(offerId),
            icon: const Icon(Symbols.refresh, size: 14),
            label: const Text('Reevaluate'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.onTertiaryContainer),
              foregroundColor: AppColors.onTertiaryContainer,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        if (isSaving)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.onTertiaryContainer),
          ),
      ],
    );
  }
}

// ─── Matches header (count + bulk action) ────────────────────────────────────

class _MatchesHeader extends StatelessWidget {
  const _MatchesHeader({
    required this.matches,
    required this.selectedMatchIds,
    required this.isSaving,
    required this.onSendBulk,
  });
  final List<CandidateMatch> matches;
  final Set<int> selectedMatchIds;
  final bool isSaving;
  final VoidCallback? onSendBulk;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '${matches.length} candidate${matches.length == 1 ? '' : 's'}',
          style: AppTextStyles.headlineMd,
        ),
        const Spacer(),
        if (selectedMatchIds.isNotEmpty)
          ElevatedButton.icon(
            onPressed: isSaving ? null : onSendBulk,
            icon: const Icon(Symbols.send, size: 14),
            label: Text('Send Test (${selectedMatchIds.length})'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.onTertiaryContainer,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
            ),
          ),
      ],
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyMatchesState extends StatelessWidget {
  const _EmptyMatchesState({this.offer});
  final JobOffer? offer;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64),
        child: Column(
          children: [
            const Icon(Symbols.group_search,
                size: 52, color: AppColors.outlineVariant),
            const SizedBox(height: 16),
            Text(
              offer?.isOpen == true
                  ? 'No matched candidates yet.'
                  : 'Candidates will appear once the offer is active.',
              style: AppTextStyles.bodyLg
                  .copyWith(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (offer?.isOpen == true) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => context
                    .read<CompanyCubit>()
                    .runMatching(int.parse(offer!.id)),
                icon: const Icon(Symbols.play_arrow, size: 16),
                label: const Text('Run Matching'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.onTertiaryContainer,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Candidate match card ─────────────────────────────────────────────────────

class _CandidateMatchCard extends StatelessWidget {
  const _CandidateMatchCard({
    required this.rank,
    required this.match,
    required this.isSelected,
    required this.actingMatchId,
    required this.onToggleSelect,
    required this.onSendTest,
    required this.onSelect,
    required this.onReject,
    required this.onViewResults,
  });

  final int rank;
  final CandidateMatch match;
  final bool isSelected;
  final int? actingMatchId;
  final ValueChanged<int> onToggleSelect;
  final ValueChanged<int> onSendTest;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onReject;
  final ValueChanged<int> onViewResults;

  @override
  Widget build(BuildContext context) {
    final rankColor = switch (rank) {
      1 => const Color(0xFFFFD700),
      2 => const Color(0xFFC0C0C0),
      3 => const Color(0xFFCD7F32),
      _ => AppColors.outlineVariant,
    };
    final isRejected = match.status == MatchStatus.rejected;
    final isMobile = Responsive.isMobile(context);

    final rankBadge = Container(
      width: 36,
      height: 36,
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        color: rank <= 3
            ? rankColor.withValues(alpha: 0.15)
            : AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text('#$rank',
            style: AppTextStyles.labelSm.copyWith(
                color: rank <= 3 ? rankColor : AppColors.outline,
                fontWeight: FontWeight.w700,
                fontSize: 13)),
      ),
    );

    final avatar = Opacity(
      opacity: isRejected ? 0.4 : 1,
      child: CircleAvatar(
        radius: 22,
        backgroundColor: AppColors.secondaryContainer.withValues(alpha: 0.4),
        child: Text(
          match.candidateName.isNotEmpty ? match.candidateName[0] : '?',
          style: AppTextStyles.labelBold
              .copyWith(color: AppColors.secondary, fontSize: 16),
        ),
      ),
    );

    final infoColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              match.candidateName,
              style: AppTextStyles.labelBold.copyWith(
                  fontSize: 15,
                  color: isRejected ? AppColors.outline : AppColors.onSurface),
            ),
            _StatusPill(status: match.status),
          ],
        ),
        if (match.headline.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(match.headline,
              style: AppTextStyles.labelSm
                  .copyWith(color: AppColors.onSurfaceVariant)),
        ],
        if (match.email != null) ...[
          const SizedBox(height: 2),
          Text(match.email!,
              style: AppTextStyles.labelSm
                  .copyWith(color: AppColors.secondary, fontSize: 11)),
        ],
        if (match.skills.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: match.skills
                .take(4)
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
      ],
    );

    final scoreAndActions = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ScoreBox(match: match),
        const SizedBox(width: 12),
        if (!isRejected)
          _ActionButtons(
            match: match,
            isActing: actingMatchId == match.matchId,
            onSendTest: () => onSendTest(match.matchId),
            onSelect: () => onSelect(match.matchId),
            onReject: () => onReject(match.matchId),
            onViewResults: () => onViewResults(match.matchId),
          )
        else
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Rejected',
                style: TextStyle(
                    color: AppColors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
      ],
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile) ...[
            // Mobile: top row with checkbox + rank + avatar + info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (match.canSendTest)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (_) => onToggleSelect(match.matchId),
                      activeColor: AppColors.onTertiaryContainer,
                      side: const BorderSide(color: AppColors.outlineVariant),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                else
                  const SizedBox(width: 4),
                rankBadge,
                const SizedBox(width: 12),
                avatar,
                const SizedBox(width: 12),
                Expanded(child: infoColumn),
              ],
            ),
            // Mobile: score + actions below
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [scoreAndActions],
            ),
          ] else ...[
            // Desktop: everything in one row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (match.canSendTest)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (_) => onToggleSelect(match.matchId),
                      activeColor: AppColors.onTertiaryContainer,
                      side: const BorderSide(color: AppColors.outlineVariant),
                    ),
                  )
                else
                  const SizedBox(width: 4),
                rankBadge,
                const SizedBox(width: 14),
                avatar,
                const SizedBox(width: 14),
                Expanded(child: infoColumn),
                const SizedBox(width: 16),
                scoreAndActions,
              ],
            ),
          ],

          // AI Insight
          if (match.aiInsight != null) ...[
            const SizedBox(height: 12),
            _AiInsightBox(match: match),
          ],
        ],
      ),
    );
  }
}

// ─── Score box ────────────────────────────────────────────────────────────────

class _ScoreBox extends StatelessWidget {
  const _ScoreBox({required this.match});
  final CandidateMatch match;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.onTertiaryContainer.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (match.adjustedScore != null) ...[
            Text(
              match.adjustedScore!.toStringAsFixed(1),
              style: AppTextStyles.headlineMd.copyWith(
                  color: AppColors.onTertiaryContainer, fontSize: 22),
            ),
            Text('AI Score',
                style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.onTertiaryContainer, fontSize: 10)),
            const SizedBox(height: 4),
            Text('${match.matchScore}% match',
                style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant, fontSize: 10)),
          ] else ...[
            Text('${match.matchScore}%',
                style: AppTextStyles.headlineMd.copyWith(
                    color: AppColors.onTertiaryContainer, fontSize: 22)),
            Text('Match',
                style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.onTertiaryContainer, fontSize: 10)),
          ],
          if (match.testScore != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('Test: ${match.testScore}',
                  style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.secondary, fontSize: 10)),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── AI Insight box ───────────────────────────────────────────────────────────

class _AiInsightBox extends StatelessWidget {
  const _AiInsightBox({required this.match});
  final CandidateMatch match;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.onTertiaryContainer.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.onTertiaryContainer.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Symbols.auto_awesome,
                  size: 13, color: AppColors.onTertiaryContainer),
              const SizedBox(width: 6),
              Text('AI Insight',
                  style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.onTertiaryContainer,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
              if (match.aiRecommendation != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.onTertiaryContainer.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(match.aiRecommendation!,
                      style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.onTertiaryContainer,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(match.aiInsight!,
              style:
                  AppTextStyles.labelSm.copyWith(fontSize: 12, height: 1.4)),
          if (match.aiStrengths.isNotEmpty) ...[
            const SizedBox(height: 8),
            _AiList(
                label: 'Fortalezas',
                items: match.aiStrengths,
                color: AppColors.onTertiaryContainer,
                icon: Symbols.check_circle),
          ],
          if (match.aiOpportunities.isNotEmpty) ...[
            const SizedBox(height: 6),
            _AiList(
                label: 'Oportunidades',
                items: match.aiOpportunities,
                color: const Color(0xFFF59E0B),
                icon: Symbols.lightbulb),
          ],
        ],
      ),
    );
  }
}

class _AiList extends StatelessWidget {
  const _AiList(
      {required this.label,
      required this.items,
      required this.color,
      required this.icon});
  final String label;
  final List<String> items;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: AppTextStyles.labelSm.copyWith(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 3),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(item,
                        style: AppTextStyles.labelSm.copyWith(
                            fontSize: 11,
                            color: AppColors.onSurface,
                            height: 1.4)),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

// ─── Status pill ──────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final MatchStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      MatchStatus.new_ => ('New', AppColors.secondary),
      MatchStatus.testSent => ('Test Sent', const Color(0xFFF59E0B)),
      MatchStatus.testCompleted =>
        ('Test Done', AppColors.onTertiaryContainer),
      MatchStatus.shortlisted =>
        ('Selected', AppColors.onTertiaryContainer),
      MatchStatus.rejected => ('Rejected', AppColors.error),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(label,
          style:
              AppTextStyles.labelSm.copyWith(color: color, fontSize: 10)),
    );
  }
}

// ─── Action buttons ───────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.match,
    required this.isActing,
    required this.onSendTest,
    required this.onSelect,
    required this.onReject,
    required this.onViewResults,
  });
  final CandidateMatch match;
  final bool isActing;
  final VoidCallback onSendTest;
  final VoidCallback onSelect;
  final VoidCallback onReject;
  final VoidCallback onViewResults;

  bool get _hasTestResults =>
      match.status == MatchStatus.testCompleted ||
      match.status == MatchStatus.shortlisted;

  @override
  Widget build(BuildContext context) {
    if (isActing) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.onTertiaryContainer),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (match.canSendTest)
          _PrimaryBtn(
            icon: Symbols.send,
            label: 'Send Test',
            color: AppColors.onTertiaryContainer,
            onTap: onSendTest,
          )
        else if (match.status == MatchStatus.testSent)
          _StatusTag(
              icon: Symbols.schedule_send,
              label: 'Test Sent',
              color: const Color(0xFFF59E0B))
        else if (match.canSelect)
          _PrimaryBtn(
            icon: Symbols.how_to_reg,
            label: 'Select',
            color: AppColors.onTertiaryContainer,
            onTap: onSelect,
          )
        else if (match.status == MatchStatus.shortlisted)
          _StatusTag(
              icon: Symbols.verified,
              label: 'Selected',
              color: AppColors.onTertiaryContainer),

        // View test results
        if (_hasTestResults) ...[
          const SizedBox(height: 6),
          _OutlineBtn(
            icon: Symbols.assignment,
            label: 'Ver Test',
            color: AppColors.secondary,
            onTap: onViewResults,
          ),
        ],

        if (match.canReject) ...[
          const SizedBox(height: 6),
          _OutlineBtn(
            icon: Symbols.person_remove,
            label: 'Reject',
            color: AppColors.error,
            onTap: onReject,
            muted: true,
          ),
        ],
      ],
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  const _PrimaryBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: Colors.white),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  const _OutlineBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap,
      this.muted = false});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final c = muted ? color.withValues(alpha: 0.7) : color;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.06),
          border: Border.all(color: c.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: c),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: c)),
          ],
        ),
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag(
      {required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }
}

// ─── Small helpers ────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: AppTextStyles.labelSm.copyWith(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.outline),
        const SizedBox(width: 4),
        Text(label,
            style: AppTextStyles.labelSm
                .copyWith(color: AppColors.onSurfaceVariant)),
      ],
    );
  }
}
