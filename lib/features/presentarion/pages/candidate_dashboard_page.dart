import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../config/router/app_routes.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../config/theme/responsive.dart';
import '../../domain/entities/candidate.dart';
import '../../domain/entities/technical_test.dart';
import '../../domain/entities/user.dart';
import '../bloc/candidate_cubit.dart';
import '../widgets/shared/app_card.dart';
import '../widgets/shared/app_sidebar.dart';

class CandidateDashboardPage extends StatefulWidget {
  const CandidateDashboardPage({super.key});

  @override
  State<CandidateDashboardPage> createState() => _CandidateDashboardPageState();
}

class _CandidateDashboardPageState extends State<CandidateDashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<CandidateCubit>().loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithSidebar(
      currentRoute: AppRoutes.candidateDashboard,
      role: UserRole.candidate,
      child: _DashboardContent(),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CandidateCubit, CandidateState>(
      builder: (context, state) {
        if (state.isLoading && state.profile == null) {
          return const Center(child: CircularProgressIndicator(color: AppColors.onTertiaryContainer));
        }

        final profile = state.profile;
        final userName = profile?.name ?? 'there';

        return SingleChildScrollView(
          padding: Responsive.pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(name: userName.split(' ').first, profile: profile),
              const SizedBox(height: 32),
              _KpiGrid(profile: profile),
              const SizedBox(height: 32),
              LayoutBuilder(
                builder: (_, constraints) {
                  if (constraints.maxWidth < 600) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (profile != null)
                          _ProfileStrengthCard(profile: profile),
                        if (profile != null) const SizedBox(height: 20),
                        _TestsSection(tests: state.pendingTests),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: _TestsSection(tests: state.pendingTests),
                      ),
                      const SizedBox(width: 32),
                      SizedBox(
                        width: 300,
                        child: profile != null
                            ? _ProfileStrengthCard(profile: profile)
                            : const SizedBox.shrink(),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.profile});
  final String name;
  final CandidateProfile? profile;

  String get _subtitle {
    if (profile == null) return 'Loading your profile...';
    if (profile!.skills.isEmpty) {
      return 'Complete your profile to start receiving AI-matched opportunities.';
    }
    final skillCount = profile!.skills.length;
    final headline = profile!.headline.isNotEmpty ? ' · ${profile!.headline}' : '';
    return 'You have $skillCount skill${skillCount == 1 ? '' : 's'}$headline.';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hello, $name 👋', style: AppTextStyles.headlineLg),
              const SizedBox(height: 4),
              Text(
                _subtitle,
                style: AppTextStyles.bodyLg.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Row(
          children: [
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Symbols.notifications, color: AppColors.outline),
                  onPressed: () {},
                ),
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.background, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primaryContainer,
              child: Text(name.isNotEmpty ? name[0] : 'U',
                  style: AppTextStyles.headlineMd.copyWith(color: AppColors.onPrimary, fontSize: 18)),
            ),
          ],
        ),
      ],
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.profile});
  final CandidateProfile? profile;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _ProfileStrengthCircle(strength: profile?.profileStrength ?? 0),
      _KpiCard(
        icon: Symbols.assignment,
        value: '${profile?.pendingTests ?? 0}',
        label: 'Pending Tests',
        iconBgColor: AppColors.secondaryContainer.withValues(alpha: 0.2),
        iconColor: AppColors.secondary,
        progress: ((profile?.pendingTests ?? 0) / 10).clamp(0.0, 1.0),
      ),
      _KpiCard(
        icon: Symbols.send,
        value: '${profile?.activeApplications ?? 0}',
        label: 'Active Applications',
        iconBgColor: AppColors.primaryContainer.withValues(alpha: 0.1),
        iconColor: AppColors.primary,
        progress: ((profile?.activeApplications ?? 0) / 10).clamp(0.0, 1.0),
      ),
    ];
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
              if (i > 0) const SizedBox(width: 20),
              Expanded(child: cards[i]),
            ],
          ],
        );
      },
    );
  }
}

class _ProfileStrengthCircle extends StatelessWidget {
  const _ProfileStrengthCircle({required this.strength});
  final int strength;

  @override
  Widget build(BuildContext context) {
    final percent = strength / 100.0;
    final label = strength == 100 ? 'Profile Complete' : 'Profile Strength';
    return AppCard(
      child: Column(
        children: [
          Text(label,
              style: AppTextStyles.labelBold.copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 16),
          SizedBox(
            width: 120, height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(120, 120),
                  painter: _CircleProgressPainter(progress: percent),
                ),
                Text('$strength%', style: AppTextStyles.display.copyWith(fontSize: 28)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.onTertiaryContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              strength == 100 ? '✓ All fields filled' : 'Fill profile to match',
              style: AppTextStyles.labelSm.copyWith(color: AppColors.onTertiaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleProgressPainter extends CustomPainter {
  const _CircleProgressPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const strokeWidth = 8.0;

    final trackPaint = Paint()
      ..color = AppColors.surfaceVariant
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    final progressPaint = Paint()
      ..color = AppColors.onTertiaryContainer
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CircleProgressPainter oldDelegate) => oldDelegate.progress != progress;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconBgColor,
    required this.iconColor,
    required this.progress,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color iconBgColor;
  final Color iconColor;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: iconBgColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 16),
          Text(value,
              style: AppTextStyles.display.copyWith(fontSize: 48, height: 1.1)),
          const SizedBox(height: 4),
          Text(label,
              style: AppTextStyles.labelBold
                  .copyWith(color: AppColors.onSurfaceVariant, letterSpacing: 0.5)),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.surfaceVariant,
            color: iconColor,
            minHeight: 4,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}

class _TestsSection extends StatelessWidget {
  const _TestsSection({required this.tests});
  final List<TechnicalTest> tests;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Required Assessments', style: AppTextStyles.headlineMd),
        const SizedBox(height: 16),
        ...tests.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TestCard(test: t),
            )),
      ],
    );
  }
}

class _TestCard extends StatelessWidget {
  const _TestCard({required this.test});
  final TechnicalTest test;

  @override
  Widget build(BuildContext context) {
    final (icon, bgColor, iconColor) = switch (test.iconType) {
      'terminal' => (Symbols.terminal, AppColors.errorContainer.withOpacity(0.2), AppColors.error),
      'psychology' => (Symbols.psychology, AppColors.secondaryContainer.withOpacity(0.2), AppColors.secondary),
      _ => (Symbols.design_services, AppColors.primaryContainer.withOpacity(0.2), AppColors.primary),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(test.title, style: AppTextStyles.labelBold),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Symbols.timer, size: 14, color: AppColors.outline),
                    const SizedBox(width: 4),
                    Text('${test.durationMinutes} mins · ${test.daysUntilDue}',
                        style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: test.offerId != null
                ? () => context.go('/candidate/test/${test.offerId}')
                : null,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.secondary),
              foregroundColor: AppColors.secondary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text('Start Test', style: AppTextStyles.labelBold.copyWith(color: AppColors.secondary)),
          ),
        ],
      ),
    );
  }
}

class _ProfileStrengthCard extends StatelessWidget {
  const _ProfileStrengthCard({required this.profile});
  final CandidateProfile profile;

  @override
  Widget build(BuildContext context) {
    final strength = profile.profileStrength;
    final hasSkills = profile.skills.isNotEmpty;
    final isComplete = strength == 100;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Profile Strength', style: AppTextStyles.labelBold),
              const Spacer(),
              Text('$strength%',
                  style: AppTextStyles.labelBold.copyWith(color: AppColors.onTertiaryContainer)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: strength / 100,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.onTertiaryContainer),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),
          _StrengthItem(label: 'Personal Information', done: true),
          _StrengthItem(label: 'Skills Added', done: hasSkills),
          _StrengthItem(
            label: isComplete ? 'Experience & English' : 'Experience & English (pending)',
            done: isComplete,
          ),
        ],
      ),
    );
  }
}

class _StrengthItem extends StatelessWidget {
  const _StrengthItem({required this.label, required this.done});
  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            done ? Symbols.check_circle : Symbols.radio_button_unchecked,
            size: 16,
            color: done ? AppColors.onTertiaryContainer : AppColors.outline,
          ),
          const SizedBox(width: 8),
          Text(label, style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}
