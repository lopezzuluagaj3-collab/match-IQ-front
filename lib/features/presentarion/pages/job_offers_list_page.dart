import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../config/theme/responsive.dart';
import '../../../config/router/app_routes.dart';
import '../../domain/entities/job_offer.dart';
import '../../domain/entities/technical_test.dart';
import '../../domain/entities/user.dart';
import '../bloc/candidate_cubit.dart';
import '../widgets/shared/app_card.dart';
import '../widgets/shared/app_sidebar.dart';

enum JobOffersMode { jobBoard, matches, assessments }

class JobOffersListPage extends StatefulWidget {
  const JobOffersListPage({super.key, this.mode = JobOffersMode.jobBoard});
  final JobOffersMode mode;

  @override
  State<JobOffersListPage> createState() => _JobOffersListPageState();
}

class _JobOffersListPageState extends State<JobOffersListPage> {
  String _search = '';
  OfferMode? _filterMode;

  bool get _isAssessments => widget.mode == JobOffersMode.assessments;

  String get _currentRoute => AppRoutes.candidateAssessments;

  String get _pageTitle => switch (widget.mode) {
        JobOffersMode.matches => 'My Matches',
        JobOffersMode.assessments => 'Assessments',
        JobOffersMode.jobBoard => 'Job Board',
      };

  String get _pageSubtitle => switch (widget.mode) {
        JobOffersMode.matches => 'Offers matched to your profile by AI',
        JobOffersMode.assessments => 'Your pending technical assessments',
        JobOffersMode.jobBoard => '{count} opportunities matched for you',
      };

  @override
  void initState() {
    super.initState();
    if (_isAssessments) {
      context.read<CandidateCubit>().loadAssessments();
    } else {
      context.read<CandidateCubit>().loadOffers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithSidebar(
      currentRoute: _currentRoute,
      role: UserRole.candidate,
      child: BlocBuilder<CandidateCubit, CandidateState>(
        builder: (context, state) => _isAssessments
            ? _AssessmentsView(
                search: _search,
                onSearchChanged: (v) => setState(() => _search = v),
                state: state,
                pageTitle: _pageTitle,
                pageSubtitle: _pageSubtitle,
              )
            : _OffersView(
                search: _search,
                onSearchChanged: (v) => setState(() => _search = v),
                filterMode: _filterMode,
                onFilterChanged: (m) => setState(() => _filterMode = m),
                state: state,
                pageTitle: _pageTitle,
                pageSubtitle: _pageSubtitle,
              ),
      ),
    );
  }
}

// ─── Offers view (Job Board / Matches) ───────────────────────────────────────

class _OffersView extends StatelessWidget {
  const _OffersView({
    required this.search,
    required this.onSearchChanged,
    required this.filterMode,
    required this.onFilterChanged,
    required this.state,
    required this.pageTitle,
    required this.pageSubtitle,
  });

  final String search;
  final ValueChanged<String> onSearchChanged;
  final OfferMode? filterMode;
  final ValueChanged<OfferMode?> onFilterChanged;
  final CandidateState state;
  final String pageTitle;
  final String pageSubtitle;

  @override
  Widget build(BuildContext context) {
    var offers = state.offers;
    if (search.isNotEmpty) {
      offers = offers
          .where((o) =>
              o.title.toLowerCase().contains(search.toLowerCase()) ||
              o.companyName.toLowerCase().contains(search.toLowerCase()))
          .toList();
    }
    if (filterMode != null) {
      offers = offers.where((o) => o.mode == filterMode).toList();
    }
    offers = [...offers]
      ..sort((a, b) => (b.matchScore ?? 0).compareTo(a.matchScore ?? 0));

    return SingleChildScrollView(
      padding: Responsive.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pageTitle, style: AppTextStyles.headlineLg),
                    Text(
                      pageSubtitle.replaceFirst('{count}', '${offers.length}'),
                      style: AppTextStyles.bodyMd
                          .copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (_, constraints) {
              final searchField = TextField(
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search by role or company...',
                  prefixIcon:
                      const Icon(Symbols.search, color: AppColors.outline, size: 20),
                  filled: true,
                  fillColor: AppColors.surfaceContainerLowest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.outlineVariant),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              );
              final chip1 = _FilterChip(
                label: 'Remote',
                isSelected: filterMode == OfferMode.remote,
                onTap: () => onFilterChanged(
                    filterMode == OfferMode.remote ? null : OfferMode.remote),
              );
              final chip2 = _FilterChip(
                label: 'Hybrid',
                isSelected: filterMode == OfferMode.hybrid,
                onTap: () => onFilterChanged(
                    filterMode == OfferMode.hybrid ? null : OfferMode.hybrid),
              );
              final chip3 = _FilterChip(
                label: 'On-site',
                isSelected: filterMode == OfferMode.onSite,
                onTap: () => onFilterChanged(
                    filterMode == OfferMode.onSite ? null : OfferMode.onSite),
              );
              if (constraints.maxWidth < 500) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    searchField,
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, children: [chip1, chip2, chip3]),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: searchField),
                  const SizedBox(width: 12),
                  chip1,
                  const SizedBox(width: 8),
                  chip2,
                  const SizedBox(width: 8),
                  chip3,
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          if (state.isLoading)
            const Center(
                child: CircularProgressIndicator(
                    color: AppColors.onTertiaryContainer))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: offers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (_, i) => _OfferRow(offer: offers[i]),
            ),
        ],
      ),
    );
  }
}

// ─── Assessments view ─────────────────────────────────────────────────────────

class _AssessmentsView extends StatelessWidget {
  const _AssessmentsView({
    required this.search,
    required this.onSearchChanged,
    required this.state,
    required this.pageTitle,
    required this.pageSubtitle,
  });

  final String search;
  final ValueChanged<String> onSearchChanged;
  final CandidateState state;
  final String pageTitle;
  final String pageSubtitle;

  @override
  Widget build(BuildContext context) {
    var tests = state.pendingTests;
    if (search.isNotEmpty) {
      tests = tests
          .where((t) =>
              t.title.toLowerCase().contains(search.toLowerCase()) ||
              (t.companyName?.toLowerCase().contains(search.toLowerCase()) ??
                  false))
          .toList();
    }

    final pending =
        tests.where((t) => t.status == TestStatus.pending || t.status == TestStatus.inProgress).toList();
    final completed =
        tests.where((t) => t.status == TestStatus.completed).toList();
    final expired =
        tests.where((t) => t.status == TestStatus.expired).toList();

    return SingleChildScrollView(
      padding: Responsive.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pageTitle, style: AppTextStyles.headlineLg),
                    const SizedBox(height: 4),
                    Text(
                      pageSubtitle,
                      style: AppTextStyles.bodyMd
                          .copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (pending.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                    border:
                        Border.all(color: AppColors.error.withOpacity(0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                            color: AppColors.error, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        '${pending.length} pending',
                        style: AppTextStyles.labelBold.copyWith(
                            color: AppColors.error, fontSize: 12),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Search
          TextField(
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search assessments or company...',
              prefixIcon:
                  const Icon(Symbols.search, color: AppColors.outline, size: 20),
              filled: true,
              fillColor: AppColors.surfaceContainerLowest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.outlineVariant),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 28),

          // Content
          if (state.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 60),
                child: CircularProgressIndicator(
                    color: AppColors.onTertiaryContainer),
              ),
            )
          else if (tests.isEmpty && search.isEmpty)
            const _EmptyAssessments()
          else if (tests.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Column(
                  children: [
                    const Icon(Symbols.search_off,
                        size: 52, color: AppColors.outline),
                    const SizedBox(height: 14),
                    Text(
                      'No assessments match your search',
                      style: AppTextStyles.bodyLg
                          .copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            if (pending.isNotEmpty) ...[
              _SectionLabel(
                  label: 'Pending',
                  count: pending.length,
                  color: AppColors.error),
              const SizedBox(height: 14),
              ...pending.map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _AssessmentCard(test: t),
                  )),
              if (completed.isNotEmpty || expired.isNotEmpty)
                const SizedBox(height: 12),
            ],
            if (completed.isNotEmpty) ...[
              _SectionLabel(
                  label: 'Completed',
                  count: completed.length,
                  color: AppColors.onTertiaryContainer),
              const SizedBox(height: 14),
              ...completed.map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _AssessmentCard(test: t),
                  )),
              if (expired.isNotEmpty) const SizedBox(height: 12),
            ],
            if (expired.isNotEmpty) ...[
              _SectionLabel(
                  label: 'Expired',
                  count: expired.length,
                  color: AppColors.outline),
              const SizedBox(height: 14),
              ...expired.map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _AssessmentCard(test: t),
                  )),
            ],
          ],
        ],
      ),
    );
  }
}

// ─── Assessment card ──────────────────────────────────────────────────────────

class _AssessmentCard extends StatelessWidget {
  const _AssessmentCard({required this.test});
  final TechnicalTest test;

  @override
  Widget build(BuildContext context) {
    final isPending = test.status == TestStatus.pending;
    final isInProgress = test.status == TestStatus.inProgress;
    final isCompleted = test.status == TestStatus.completed;
    final isExpired = test.status == TestStatus.expired;

    final (icon, iconBg, iconColor) = switch (test.iconType) {
      'psychology' => (
          Symbols.psychology,
          AppColors.secondaryContainer.withOpacity(0.18),
          AppColors.secondary
        ),
      'design' => (
          Symbols.design_services,
          AppColors.primaryContainer.withOpacity(0.18),
          AppColors.primary
        ),
      _ => (
          Symbols.terminal,
          AppColors.errorContainer.withOpacity(0.14),
          AppColors.error
        ),
    };

    final (statusLabel, statusColor, statusBg) = switch (test.status) {
      TestStatus.pending => ('Pending', AppColors.error, AppColors.errorContainer.withOpacity(0.1)),
      TestStatus.inProgress => ('In Progress', AppColors.secondary, AppColors.secondaryContainer.withOpacity(0.12)),
      TestStatus.completed => ('Completed', AppColors.onTertiaryContainer, AppColors.onTertiaryContainer.withOpacity(0.1)),
      TestStatus.expired => ('Expired', AppColors.outline, AppColors.surfaceVariant),
    };

    return AppCard(
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                    color: iconBg, borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(test.title,
                              style: AppTextStyles.labelBold
                                  .copyWith(fontSize: 15),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            statusLabel,
                            style: AppTextStyles.labelSm.copyWith(
                                color: statusColor, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    if (test.companyName != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        test.companyName!,
                        style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.onSurfaceVariant, fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _MetaChip(
                  icon: Symbols.timer,
                  label: '${test.durationMinutes} min'),
              const SizedBox(width: 8),
              _MetaChip(
                icon: isExpired ? Symbols.event_busy : Symbols.event,
                label: test.daysUntilDue,
                color: isExpired ? AppColors.error : null,
              ),
              if (isCompleted && test.score != null) ...[
                const SizedBox(width: 8),
                _MetaChip(
                  icon: Symbols.emoji_events,
                  label: '${test.score}/100',
                  color: AppColors.onTertiaryContainer,
                ),
              ],
              const Spacer(),
              if (isPending || isInProgress)
                FilledButton(
                  onPressed: () => context.go(
                      '/candidate/test/${test.offerId ?? test.id}'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    elevation: 0,
                  ),
                  child: Text(
                    isInProgress ? 'Continue' : 'Start Test',
                    style: AppTextStyles.labelBold
                        .copyWith(color: Colors.white, fontSize: 13),
                  ),
                )
              else if (isCompleted)
                OutlinedButton(
                  onPressed: () => context.go(AppRoutes.candidateTestResultPath(int.parse(test.id))),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: AppColors.onTertiaryContainer.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                  child: Text(
                    'View Result',
                    style: AppTextStyles.labelBold.copyWith(
                        color: AppColors.onTertiaryContainer, fontSize: 13),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label, this.color});
  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: c),
        const SizedBox(width: 4),
        Text(label,
            style:
                AppTextStyles.labelSm.copyWith(color: c, fontSize: 12)),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(
      {required this.label, required this.count, required this.color});
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(label,
            style: AppTextStyles.labelBold
                .copyWith(color: AppColors.onSurface, fontSize: 13)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999)),
          child: Text('$count',
              style: AppTextStyles.labelSm
                  .copyWith(color: color, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _EmptyAssessments extends StatelessWidget {
  const _EmptyAssessments();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Symbols.assignment,
                  size: 40, color: AppColors.outline),
            ),
            const SizedBox(height: 20),
            Text('No pending assessments',
                style: AppTextStyles.headlineMd
                    .copyWith(color: AppColors.onSurface, fontSize: 20)),
            const SizedBox(height: 8),
            Text(
              "You're all caught up! New tests\nwill appear here when companies invite you.",
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd
                  .copyWith(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Offer row (job board / matches) ──────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip(
      {required this.label, required this.isSelected, required this.onTap});
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.onTertiaryContainer
              : AppColors.surfaceContainerLowest,
          border: Border.all(
              color: isSelected
                  ? AppColors.onTertiaryContainer
                  : AppColors.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelBold.copyWith(
              color:
                  isSelected ? Colors.white : AppColors.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _OfferRow extends StatelessWidget {
  const _OfferRow({required this.offer});
  final JobOffer offer;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 20,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Symbols.business,
                color: AppColors.onSurfaceVariant, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(offer.title, style: AppTextStyles.labelBold),
                    const Spacer(),
                    if (offer.matchScore != null)
                      EmeraldBadge(label: '${offer.matchScore}% Match'),
                  ],
                ),
                const SizedBox(height: 4),
                Text(offer.companyName,
                    style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant, fontSize: 14)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    _Tag(offer.typeLabel),
                    _Tag(offer.modeLabel),
                    _Tag(offer.salary),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Apply',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: AppTextStyles.labelSm.copyWith(
              color: AppColors.onSurfaceVariant, fontSize: 11)),
    );
  }
}
