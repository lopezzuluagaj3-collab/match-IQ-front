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
          if (state.isLoading && state.profile == null) {
            return const Center(child: CircularProgressIndicator(color: AppColors.onTertiaryContainer));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(profile: state.profile),
                const SizedBox(height: 32),
                _KpiRow(profile: state.profile),
                const SizedBox(height: 32),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _RecentMatchesTable(matches: state.matches.take(4).toList())),
                    const SizedBox(width: 24),
                    Expanded(child: _ActiveOffersPanel(offers: state.offers.take(3).toList())),
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
              Text('Welcome back, ${profile?.name ?? 'Company'} 🎯',
                  style: AppTextStyles.headlineLg),
              const SizedBox(height: 4),
              Text('You have ${profile?.pendingMatches ?? 0} new candidate matches to review today.',
                  style: AppTextStyles.bodyLg.copyWith(color: AppColors.onSurfaceVariant)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () => context.go(AppRoutes.createOffer),
          icon: const Icon(Symbols.add, size: 18),
          label: const Text('Post New Offer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.onTertiaryContainer,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
      ],
    );
  }
}

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.profile});
  final CompanyProfile? profile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _KpiCard(
          icon: Symbols.group,
          value: '${profile?.totalCandidates ?? 0}',
          label: 'Total Candidates',
          color: AppColors.secondary,
          bgColor: AppColors.secondaryContainer.withOpacity(0.2),
        )),
        const SizedBox(width: 20),
        Expanded(child: _KpiCard(
          icon: Symbols.auto_awesome,
          value: '${profile?.pendingMatches ?? 0}',
          label: 'Pending Matches',
          color: AppColors.onTertiaryContainer,
          bgColor: AppColors.onTertiaryContainer.withOpacity(0.1),
        )),
        const SizedBox(width: 20),
        Expanded(child: _KpiCard(
          icon: Symbols.work,
          value: '${profile?.activeOffers ?? 0}',
          label: 'Active Offers',
          color: AppColors.primary,
          bgColor: AppColors.primaryContainer.withOpacity(0.1),
        )),
        const SizedBox(width: 20),
        Expanded(child: _KpiCard(
          icon: Symbols.schedule,
          value: '48h',
          label: 'Avg. Response Time',
          color: AppColors.outline,
          bgColor: AppColors.surfaceContainer,
        )),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.bgColor,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 16),
          Text(value, style: AppTextStyles.display.copyWith(fontSize: 40, height: 1.1)),
          const SizedBox(height: 4),
          Text(label,
              style: AppTextStyles.labelBold.copyWith(color: AppColors.onSurfaceVariant, letterSpacing: 0.3)),
        ],
      ),
    );
  }
}

class _RecentMatchesTable extends StatelessWidget {
  const _RecentMatchesTable({required this.matches});
  final List<CandidateMatch> matches;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Recent AI Matches', style: AppTextStyles.headlineMd),
              const Spacer(),
              TextButton(
                onPressed: () => context.go(AppRoutes.companyMatches),
                child: Text('View All', style: AppTextStyles.labelBold.copyWith(color: AppColors.secondary)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1.2),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.outlineVariant.withOpacity(0.5))),
                ),
                children: [
                  _TableHeader('Candidate'),
                  _TableHeader('Position'),
                  _TableHeader('Match'),
                  _TableHeader('Status'),
                ],
              ),
              ...matches.map((m) => TableRow(
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.outlineVariant.withOpacity(0.2))),
                    ),
                    children: [
                      _TableCell(child: Row(children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.secondaryContainer.withOpacity(0.4),
                          child: Text(m.candidateName[0],
                              style: AppTextStyles.labelSm.copyWith(color: AppColors.secondary)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.candidateName, style: AppTextStyles.labelBold, overflow: TextOverflow.ellipsis),
                              Text(m.headline, style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant), overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ])),
                      _TableCell(child: Text(m.offerTitle, style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant))),
                      _TableCell(child: EmeraldBadge(label: '${m.matchScore}%')),
                      _TableCell(child: _StatusBadge(status: m.status)),
                    ],
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _TableHeader(String label) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(label, style: AppTextStyles.labelSm.copyWith(color: AppColors.outline)),
    );

Widget _TableCell({required Widget child}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: child,
    );

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final MatchStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      MatchStatus.new_ => ('New', AppColors.secondary),
      MatchStatus.reviewed => ('Reviewed', AppColors.outline),
      MatchStatus.shortlisted => ('Shortlisted', AppColors.onTertiaryContainer),
      MatchStatus.rejected => ('Rejected', AppColors.error),
    };
    return StatusBadge(label: label, color: color);
  }
}

class _ActiveOffersPanel extends StatelessWidget {
  const _ActiveOffersPanel({required this.offers});
  final List<JobOffer> offers;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Active Offers', style: AppTextStyles.headlineMd),
              const Spacer(),
              TextButton(
                onPressed: () => context.go(AppRoutes.createOffer),
                child: Text('+ New', style: AppTextStyles.labelBold.copyWith(color: AppColors.secondary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...offers.map((o) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(o.title, style: AppTextStyles.labelBold, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Symbols.group, size: 13, color: AppColors.outline),
                          const SizedBox(width: 4),
                          Text('${(3 + offers.indexOf(o) * 2)} applicants',
                              style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
                          const Spacer(),
                          StatusBadge(label: 'Active', color: AppColors.onTertiaryContainer),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
