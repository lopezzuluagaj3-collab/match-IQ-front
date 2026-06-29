import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../config/router/app_routes.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../widgets/shared/app_text_field.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Navbar ────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.primary,
            toolbarHeight: 64,
            title: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.onTertiaryContainer.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Symbols.auto_awesome,
                      color: AppColors.onTertiaryContainer, size: 18),
                ),
                const SizedBox(width: 10),
                Text('MatchIQ',
                    style: AppTextStyles.headlineMd
                        .copyWith(color: Colors.white, fontSize: 20)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => context.go(AppRoutes.login),
                child: Text('Sign In',
                    style: AppTextStyles.labelBold
                        .copyWith(color: Colors.white70)),
              ),
              const SizedBox(width: 8),
              Container(
                margin: const EdgeInsets.only(right: 16),
                child: ElevatedButton(
                  onPressed: () => context.go(AppRoutes.registerCandidate),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.onTertiaryContainer,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                  ),
                  child: const Text('Get Started'),
                ),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                _HeroSection(),
                _StatsSection(),
                _FeaturesSection(),
                _HowItWorksSection(),
                _RolesSection(),
                _CtaSection(),
                _Footer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero ─────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF000F1D), Color(0xFF0F2537), Color(0xFF163347)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          // Main hero content
          Padding(
            padding: MediaQuery.sizeOf(context).width < 600
                ? const EdgeInsets.fromLTRB(20, 48, 20, 40)
                : const EdgeInsets.fromLTRB(40, 80, 40, 64),
            child: Column(
              children: [
                // Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.onTertiaryContainer.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: AppColors.onTertiaryContainer
                            .withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Symbols.auto_awesome,
                          size: 15, color: AppColors.onTertiaryContainer),
                      const SizedBox(width: 8),
                      Text('AI-Powered Recruitment Platform',
                          style: AppTextStyles.labelBold.copyWith(
                              color: AppColors.onTertiaryContainer,
                              fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // Headline
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Text(
                    'Find Your Perfect\nMatch with AI',
                    style: AppTextStyles.display.copyWith(
                      color: Colors.white,
                      fontSize: MediaQuery.sizeOf(context).width < 600 ? 36 : 58,
                      height: 1.05,
                      letterSpacing: -1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),

                // Subtitle
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 580),
                  child: Text(
                    'MatchIQ connects candidates and companies using advanced AI — generating precise compatibility scores, smart assessments, and real-time insights.',
                    style: AppTextStyles.bodyLg.copyWith(
                      color: Colors.white60,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 44),

                // CTA row
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    _HeroButton(
                      label: 'Find a Job',
                      icon: Symbols.search,
                      primary: true,
                      onPressed: () =>
                          context.go(AppRoutes.registerCandidate),
                    ),
                    _HeroButton(
                      label: 'Hire Talent',
                      icon: Symbols.corporate_fare,
                      primary: false,
                      onPressed: () =>
                          context.go(AppRoutes.registerCompany),
                    ),
                  ],
                ),
                const SizedBox(height: 72),

                // Three quick features
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: MediaQuery.sizeOf(context).width < 600
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _MiniFeature(Symbols.psychology, 'AI Match Score', 'Precise compatibility analysis'),
                            const SizedBox(height: 12),
                            _MiniFeature(Symbols.assignment, 'Smart Tests', 'Role-specific assessments'),
                            const SizedBox(height: 12),
                            _MiniFeature(Symbols.analytics, 'Live Pipeline', 'Real-time hiring dashboard'),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(child: _MiniFeature(Symbols.psychology, 'AI Match Score', 'Precise compatibility analysis')),
                            _MiniDivider(),
                            Expanded(child: _MiniFeature(Symbols.assignment, 'Smart Tests', 'Role-specific assessments')),
                            _MiniDivider(),
                            Expanded(child: _MiniFeature(Symbols.analytics, 'Live Pipeline', 'Real-time hiring dashboard')),
                          ],
                        ),
                ),
              ],
            ),
          ),

          // Subtle bottom wave / fade
          Container(
            height: 40,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF163347), AppColors.background],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroButton extends StatelessWidget {
  const _HeroButton({
    required this.label,
    required this.icon,
    required this.primary,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final bool primary;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (primary) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.onTertiaryContainer,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle: AppTextStyles.labelBold.copyWith(color: Colors.white),
          elevation: 0,
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        textStyle: AppTextStyles.labelBold.copyWith(color: Colors.white),
      ),
    );
  }
}

class _MiniFeature extends StatelessWidget {
  const _MiniFeature(this.icon, this.title, this.subtitle);
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.onTertiaryContainer.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 18, color: AppColors.onTertiaryContainer),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AppTextStyles.labelBold
                      .copyWith(color: Colors.white, fontSize: 13)),
              Text(subtitle,
                  style: AppTextStyles.labelSm
                      .copyWith(color: Colors.white38, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        width: 1, height: 40, color: Colors.white12,
        margin: const EdgeInsets.symmetric(horizontal: 16));
  }
}

// ─── Stats ────────────────────────────────────────────────────────────────────

class _StatsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const stats = [
      (Symbols.group, '10,000+', 'Candidates'),
      (Symbols.business, '500+', 'Companies'),
      (Symbols.auto_awesome, '94%', 'Match Accuracy'),
      (Symbols.schedule, '48h', 'Avg. Hire Time'),
    ];

    final isMobile = MediaQuery.sizeOf(context).width < 600;
    return Container(
      padding: EdgeInsets.symmetric(vertical: 48, horizontal: isMobile ? 20 : 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: isMobile
              ? Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 24,
                  runSpacing: 24,
                  children: stats
                      .map((s) => SizedBox(width: 140, child: _StatCard(s.$1, s.$2, s.$3)))
                      .toList(),
                )
              : Row(
                  children: stats.expand((s) sync* {
                    yield Expanded(child: _StatCard(s.$1, s.$2, s.$3));
                    if (s != stats.last)
                      yield Container(
                          width: 1, height: 64, color: AppColors.outlineVariant,
                          margin: const EdgeInsets.symmetric(horizontal: 12));
                  }).toList(),
                ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.icon, this.value, this.label);
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.onTertiaryContainer, size: 24),
        ),
        Text(value,
            style: AppTextStyles.headlineLg
                .copyWith(color: AppColors.primary, fontSize: 30)),
        const SizedBox(height: 2),
        Text(label,
            style: AppTextStyles.labelSm
                .copyWith(color: AppColors.onSurfaceVariant)),
      ],
    );
  }
}

// ─── Features ─────────────────────────────────────────────────────────────────

class _FeaturesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const features = [
      (
        Symbols.auto_awesome,
        'AI Matching Engine',
        'Our AI analyzes hundreds of data points — skills, experience, personality fit, and test scores — to generate precise compatibility scores between candidates and roles.',
        AppColors.onTertiaryContainer,
      ),
      (
        Symbols.assignment,
        'Smart Assessments',
        'Automated technical and behavioral assessments that validate real capabilities. Results directly influence the AI match score to surface the best candidates.',
        AppColors.secondary,
      ),
      (
        Symbols.analytics,
        'Real-time Analytics',
        'Track your hiring pipeline with live dashboards. Monitor match quality, test completion rates, and hiring velocity — all in one place.',
        AppColors.primary,
      ),
    ];

    final isMobile = MediaQuery.sizeOf(context).width < 700;
    return Container(
      color: AppColors.surfaceContainerLow,
      padding: EdgeInsets.symmetric(vertical: 72, horizontal: isMobile ? 20 : 40),
      child: Column(
        children: [
          _SectionHeader(
            tag: 'WHY MATCHIQ',
            title: 'Smarter Hiring, Better Outcomes',
            subtitle:
                'Everything you need to find or fill the right role — powered by AI.',
          ),
          const SizedBox(height: 52),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: isMobile
                ? Column(
                    children: features
                        .map((f) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _FeatureCard(
                                icon: f.$1,
                                title: f.$2,
                                description: f.$3,
                                color: f.$4,
                              ),
                            ))
                        .toList(),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: features
                        .map((f) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: _FeatureCard(
                                  icon: f.$1,
                                  title: f.$2,
                                  description: f.$3,
                                  color: f.$4,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: const [
          BoxShadow(
              color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 20),
          Text(title,
              style:
                  AppTextStyles.headlineMd.copyWith(fontSize: 18)),
          const SizedBox(height: 10),
          Text(description,
              style: AppTextStyles.bodyMd
                  .copyWith(color: AppColors.onSurfaceVariant, height: 1.6)),
        ],
      ),
    );
  }
}

// ─── How it works ─────────────────────────────────────────────────────────────

class _HowItWorksSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const steps = [
      (
        '1',
        Symbols.person_add,
        'Create Profile',
        'Sign up and complete your professional profile. The AI immediately starts building your match score.',
      ),
      (
        '2',
        Symbols.auto_awesome,
        'Get AI Matched',
        'Our engine analyzes hundreds of data points to find the highest-compatibility roles or candidates.',
      ),
      (
        '3',
        Symbols.assignment_turned_in,
        'Complete Assessments',
        'Verify your skills with role-specific technical tests that boost your ranking in the talent pool.',
      ),
      (
        '4',
        Symbols.handshake,
        'Close the Deal',
        'Connect directly with matched companies or candidates and finalize your hire in record time.',
      ),
    ];

    final isMobile = MediaQuery.sizeOf(context).width < 700;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 72, horizontal: isMobile ? 20 : 40),
      child: Column(
        children: [
          _SectionHeader(
            tag: 'HOW IT WORKS',
            title: 'From Profile to Hire in 4 Steps',
            subtitle: 'A streamlined process built for speed and precision.',
          ),
          const SizedBox(height: 56),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: isMobile
                ? Column(
                    children: steps
                        .map((s) => Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: _StepCard(
                                number: s.$1,
                                icon: s.$2,
                                title: s.$3,
                                description: s.$4,
                              ),
                            ))
                        .toList(),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: steps.expand((s) sync* {
                      yield Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: _StepCard(
                            number: s.$1,
                            icon: s.$2,
                            title: s.$3,
                            description: s.$4,
                          ),
                        ),
                      );
                      if (s != steps.last)
                        yield Padding(
                          padding: const EdgeInsets.only(top: 26),
                          child: Icon(Symbols.arrow_forward,
                              color: AppColors.outlineVariant, size: 20),
                        );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
  });
  final String number;
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.onTertiaryContainer, size: 28),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.onTertiaryContainer,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(number,
                      style: AppTextStyles.labelSm.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 10)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(title,
            style: AppTextStyles.labelBold.copyWith(fontSize: 15),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(description,
            style: AppTextStyles.labelSm
                .copyWith(color: AppColors.onSurfaceVariant, height: 1.5),
            textAlign: TextAlign.center),
      ],
    );
  }
}

// ─── Roles section ────────────────────────────────────────────────────────────

class _RolesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 700;
    return Container(
      color: AppColors.surfaceContainerLow,
      padding: EdgeInsets.symmetric(vertical: 72, horizontal: isMobile ? 20 : 40),
      child: Column(
        children: [
          _SectionHeader(
            tag: 'FOR EVERYONE',
            title: 'Built for Candidates & Companies',
            subtitle: 'Two portals, one powerful platform.',
          ),
          const SizedBox(height: 48),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: isMobile
                ? Column(
                    children: [
                      _RoleCard(
                        icon: Symbols.person,
                        title: 'For Candidates',
                        color: AppColors.onTertiaryContainer,
                        features: const [
                          'AI-generated match score per role',
                          'Technical assessment platform',
                          'Profile strength tracking',
                          'Real-time application pipeline',
                        ],
                        ctaLabel: 'Get Started Free',
                        onCta: () => context.go(AppRoutes.registerCandidate),
                      ),
                      const SizedBox(height: 20),
                      _RoleCard(
                        icon: Symbols.corporate_fare,
                        title: 'For Companies',
                        color: AppColors.secondary,
                        features: const [
                          'AI-ranked candidate pool',
                          'Automated test dispatch',
                          'Match score breakdown',
                          'Configurable hiring pipeline',
                        ],
                        ctaLabel: 'Start Hiring',
                        onCta: () => context.go(AppRoutes.registerCompany),
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _RoleCard(
                          icon: Symbols.person,
                          title: 'For Candidates',
                          color: AppColors.onTertiaryContainer,
                          features: const [
                            'AI-generated match score per role',
                            'Technical assessment platform',
                            'Profile strength tracking',
                            'Real-time application pipeline',
                          ],
                          ctaLabel: 'Get Started Free',
                          onCta: () => context.go(AppRoutes.registerCandidate),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _RoleCard(
                          icon: Symbols.corporate_fare,
                          title: 'For Companies',
                          color: AppColors.secondary,
                          features: const [
                            'AI-ranked candidate pool',
                            'Automated test dispatch',
                            'Match score breakdown',
                            'Configurable hiring pipeline',
                          ],
                          ctaLabel: 'Start Hiring',
                          onCta: () => context.go(AppRoutes.registerCompany),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.features,
    required this.ctaLabel,
    required this.onCta,
  });
  final IconData icon;
  final String title;
  final Color color;
  final List<String> features;
  final String ctaLabel;
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 16),
          Text(title, style: AppTextStyles.headlineMd.copyWith(fontSize: 20)),
          const SizedBox(height: 20),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Icon(Symbols.check_circle, size: 16, color: color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(f,
                        style: AppTextStyles.bodyMd
                            .copyWith(height: 1.4, fontSize: 14)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onCta,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(ctaLabel, style: AppTextStyles.labelBold),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── CTA section ─────────────────────────────────────────────────────────────

class _CtaSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    return Padding(
      padding: isMobile
          ? const EdgeInsets.fromLTRB(16, 16, 16, 40)
          : const EdgeInsets.fromLTRB(40, 16, 40, 56),
      child: Container(
        padding: isMobile
            ? const EdgeInsets.symmetric(horizontal: 24, vertical: 40)
            : const EdgeInsets.symmetric(horizontal: 56, vertical: 56),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF000F1D), Color(0xFF0F2537)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.onTertiaryContainer.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Symbols.auto_awesome,
                  color: AppColors.onTertiaryContainer, size: 28),
            ),
            const SizedBox(height: 20),
            Text(
              'Ready to find your match?',
              style: AppTextStyles.headlineLg.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Text(
                'Join 10,000+ professionals and 500+ companies already using MatchIQ to hire smarter.',
                style: AppTextStyles.bodyMd
                    .copyWith(color: Colors.white54, height: 1.6),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 36),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                AppButton(
                  label: 'Get Started as Candidate',
                  isEmerald: true,
                  icon: Symbols.person,
                  onPressed: () => context.go(AppRoutes.registerCandidate),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go(AppRoutes.registerCompany),
                  icon: const Icon(Symbols.corporate_fare, size: 18),
                  label: const Text('Start Hiring'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white30),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Footer ───────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: Row(
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(7)),
                child: const Icon(Symbols.auto_awesome,
                    color: AppColors.onTertiaryContainer, size: 14),
              ),
              const SizedBox(width: 8),
              Text('MatchIQ', style: AppTextStyles.labelBold),
            ],
          ),
          const Spacer(),
          Flexible(
            child: Text(
              '© 2025 MatchIQ AI Recruitment. All rights reserved.',
              style: AppTextStyles.labelSm.copyWith(color: AppColors.outline),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared helper ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.tag,
    required this.title,
    required this.subtitle,
  });
  final String tag;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.onTertiaryContainer.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(tag,
              style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.onTertiaryContainer,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  fontSize: 11)),
        ),
        const SizedBox(height: 14),
        Text(title,
            style: AppTextStyles.headlineLg, textAlign: TextAlign.center),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(subtitle,
              style: AppTextStyles.bodyMd
                  .copyWith(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center),
        ),
      ],
    );
  }
}
