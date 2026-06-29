import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../config/router/app_routes.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';


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
            backgroundColor: const Color(0xFF000F1D),
            toolbarHeight: 68,
            title: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: AppColors.emeraldGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Symbols.auto_awesome,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Text('MatchIQ',
                    style: AppTextStyles.headlineMd.copyWith(
                        color: Colors.white,
                        fontSize: 20,
                        letterSpacing: -0.5)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => context.go(AppRoutes.login),
                child: Text('Iniciar sesión',
                    style: AppTextStyles.labelBold
                        .copyWith(color: Colors.white70)),
              ),
              const SizedBox(width: 6),
              Container(
                margin: const EdgeInsets.only(right: 20),
                child: ElevatedButton(
                  onPressed: () => context.go(AppRoutes.registerCandidate),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.onTertiaryContainer,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                  child: const Text('Comenzar gratis'),
                ),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                const _HeroSection(),
                const _StatsBar(),
                const _FeaturesSection(),
                const _HowItWorksSection(),
                const _RolesSection(),
                const _CtaSection(),
                const _Footer(),
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
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isMobile = w < 700;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF000F1D), Color(0xFF0B1E30), Color(0xFF112840)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          // Background grid pattern
          Positioned.fill(
            child: CustomPaint(painter: _GridPainter()),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                isMobile ? 20 : 40, isMobile ? 56 : 80, isMobile ? 20 : 40, 0),
            child: Column(
              children: [
                // Badge
                _Badge(label: 'Plataforma de Reclutamiento con IA'),
                SizedBox(height: isMobile ? 28 : 36),

                // Headline
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: isMobile ? 38 : 62,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                        letterSpacing: -2,
                        color: Colors.white,
                      ),
                      children: const [
                        TextSpan(text: 'El candidato perfecto,\n'),
                        TextSpan(
                          text: 'encontrado por IA',
                          style: TextStyle(
                            color: Color(0xFF34D399),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: isMobile ? 16 : 24),

                // Subtitle
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Text(
                    'MatchIQ conecta candidatos y empresas usando inteligencia artificial — generando scores de compatibilidad, assessments técnicos automáticos y rankings en tiempo real.',
                    style: AppTextStyles.bodyLg.copyWith(
                      color: Colors.white.withValues(alpha: 0.55),
                      height: 1.65,
                      fontSize: isMobile ? 15 : 17,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: isMobile ? 36 : 44),

                // CTAs
                Wrap(
                  spacing: 14,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    _PrimaryBtn(
                      label: 'Buscar trabajo',
                      icon: Symbols.search,
                      onPressed: () => context.go(AppRoutes.registerCandidate),
                    ),
                    _SecondaryBtn(
                      label: 'Contratar talento',
                      icon: Symbols.corporate_fare,
                      onPressed: () => context.go(AppRoutes.registerCompany),
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 48 : 72),

                // Floating dashboard preview
                _DashboardPreview(isMobile: isMobile),
                const SizedBox(height: 0),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..strokeWidth = 1;
    const step = 60.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF34D399).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
            color: const Color(0xFF34D399).withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Symbols.auto_awesome, size: 14, color: Color(0xFF34D399)),
          const SizedBox(width: 7),
          Text(label,
              style: AppTextStyles.labelBold.copyWith(
                  color: const Color(0xFF34D399), fontSize: 12)),
        ],
      ),
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  const _PrimaryBtn(
      {required this.label,
      required this.icon,
      required this.onPressed});
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF34D399),
        foregroundColor: const Color(0xFF000F1D),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding:
            const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        textStyle: AppTextStyles.labelBold,
      ),
    );
  }
}

class _SecondaryBtn extends StatelessWidget {
  const _SecondaryBtn(
      {required this.label,
      required this.icon,
      required this.onPressed});
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        textStyle: AppTextStyles.labelBold,
      ),
    );
  }
}

class _DashboardPreview extends StatelessWidget {
  const _DashboardPreview({required this.isMobile});
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: Container(
        margin: const EdgeInsets.only(bottom: -2),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0D2035),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 60,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Window chrome
            Row(
              children: [
                ...['FF5F57', 'FFBD2E', '28C840'].map((c) => Container(
                      width: 11,
                      height: 11,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: Color(int.parse('FF$c', radix: 16)),
                        shape: BoxShape.circle,
                      ),
                    )),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('matchiq.app/company/matches',
                      style: AppTextStyles.labelSm.copyWith(
                          color: Colors.white38, fontSize: 10)),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 16),
            // Match cards
            if (!isMobile)
              Row(
                children: [
                  Expanded(child: _MatchPreviewCard(name: 'Alejandro R.', score: 94, role: 'Senior Flutter Dev', tags: ['Flutter', 'Firebase', 'BLoC'])),
                  const SizedBox(width: 12),
                  Expanded(child: _MatchPreviewCard(name: 'Valentina M.', score: 88, role: 'Full Stack Engineer', tags: ['React', 'Node.js', 'AWS'])),
                  const SizedBox(width: 12),
                  Expanded(child: _MatchPreviewCard(name: 'Carlos P.', score: 81, role: 'Backend Developer', tags: ['Python', 'FastAPI', 'PostgreSQL'])),
                ],
              )
            else
              _MatchPreviewCard(name: 'Alejandro R.', score: 94, role: 'Senior Flutter Dev', tags: ['Flutter', 'Firebase', 'BLoC']),
          ],
        ),
      ),
    );
  }
}

class _MatchPreviewCard extends StatelessWidget {
  const _MatchPreviewCard({
    required this.name,
    required this.score,
    required this.role,
    required this.tags,
  });
  final String name;
  final int score;
  final String role;
  final List<String> tags;

  Color get _scoreColor {
    if (score >= 90) return const Color(0xFF34D399);
    if (score >= 75) return const Color(0xFFFBBF24);
    return const Color(0xFFF87171);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.secondary.withValues(alpha: 0.4),
                child: Text(name[0],
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12)),
                    Text(role,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 10),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _scoreColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$score%',
                    style: TextStyle(
                        color: _scoreColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: tags
                .map((t) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(t,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 9,
                              fontWeight: FontWeight.w500)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Stats bar ────────────────────────────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  const _StatsBar();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    const items = [
      (Symbols.group, '10,000+', 'Candidatos'),
      (Symbols.business, '500+', 'Empresas'),
      (Symbols.auto_awesome, '94%', 'Precisión IA'),
      (Symbols.schedule, '48h', 'Tiempo promedio de contratación'),
    ];

    return Container(
      color: const Color(0xFF0A1929),
      padding: EdgeInsets.symmetric(
          vertical: 36, horizontal: isMobile ? 20 : 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: isMobile
              ? Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 32,
                  runSpacing: 28,
                  children: items
                      .map((i) => SizedBox(
                          width: 140,
                          child: _StatItem(i.$1, i.$2, i.$3)))
                      .toList(),
                )
              : Row(
                  children: items.expand((i) sync* {
                    yield Expanded(child: _StatItem(i.$1, i.$2, i.$3));
                    if (i != items.last)
                      yield Container(
                          width: 1,
                          height: 48,
                          color: Colors.white.withValues(alpha: 0.08));
                  }).toList(),
                ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem(this.icon, this.value, this.label);
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF34D399), size: 22),
        const SizedBox(height: 10),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 28,
                letterSpacing: -1)),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45), fontSize: 12),
            textAlign: TextAlign.center),
      ],
    );
  }
}

// ─── Features ─────────────────────────────────────────────────────────────────

class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 700;
    const features = [
      (
        Symbols.psychology,
        'Motor de Matching IA',
        'Nuestro algoritmo analiza cientos de variables — skills, experiencia, resultados de assessments — para generar un score de compatibilidad preciso entre candidato y rol.',
        Color(0xFF34D399),
      ),
      (
        Symbols.assignment,
        'Assessments Técnicos',
        'Pruebas técnicas y de comportamiento generadas por IA, específicas para cada rol. Los resultados impactan directamente el score de matching y el ranking de candidatos.',
        Color(0xFF60A5FA),
      ),
      (
        Symbols.analytics,
        'Analytics en Tiempo Real',
        'Dashboards en vivo para monitorear tu pipeline de contratación. Sigue la calidad del match, tasas de completitud de tests y velocidad de contratación desde un solo lugar.',
        Color(0xFFA78BFA),
      ),
    ];

    return Container(
      color: const Color(0xFFF7F9FB),
      padding: EdgeInsets.symmetric(
          vertical: 80, horizontal: isMobile ? 20 : 40),
      child: Column(
        children: [
          const _SectionHeader(
            tag: 'POR QUÉ MATCHIQ',
            title: 'Contratación inteligente,\nmejores resultados',
            subtitle:
                'Todo lo que necesitas para encontrar o cubrir el rol correcto — potenciado por IA.',
          ),
          const SizedBox(height: 56),
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
                                  body: f.$3,
                                  accent: f.$4),
                            ))
                        .toList(),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: features
                        .map((f) => Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: _FeatureCard(
                                    icon: f.$1,
                                    title: f.$2,
                                    body: f.$3,
                                    accent: f.$4),
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
    required this.body,
    required this.accent,
  });
  final IconData icon;
  final String title;
  final String body;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A0F2537), blurRadius: 24, offset: Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Colored top accent bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accent, size: 24),
                ),
                const SizedBox(height: 20),
                Text(title,
                    style: AppTextStyles.headlineMd
                        .copyWith(fontSize: 17, letterSpacing: -0.3)),
                const SizedBox(height: 12),
                Text(body,
                    style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant, height: 1.65,
                        fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── How It Works ─────────────────────────────────────────────────────────────

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 700;
    const steps = [
      (Symbols.person_add, '1', 'Crea tu perfil',
          'Regístrate y completa tu perfil profesional. La IA empieza a construir tu score de matching de inmediato.'),
      (Symbols.auto_awesome, '2', 'Match con IA',
          'Nuestro motor analiza cientos de variables para encontrar los roles o candidatos con mayor compatibilidad.'),
      (Symbols.assignment_turned_in, '3', 'Completa Assessments',
          'Valida tus habilidades con pruebas técnicas específicas al rol que potencian tu posición en el ranking.'),
      (Symbols.handshake, '4', 'Cierra el Deal',
          'Conecta directamente con empresas o candidatos seleccionados y finaliza la contratación en tiempo récord.'),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(
          vertical: 80, horizontal: isMobile ? 20 : 40),
      child: Column(
        children: [
          const _SectionHeader(
            tag: 'CÓMO FUNCIONA',
            title: 'De perfil a contratación\nen 4 pasos',
            subtitle: 'Un proceso diseñado para velocidad y precisión.',
          ),
          const SizedBox(height: 60),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: isMobile
                ? Column(
                    children: steps
                        .map((s) => Padding(
                              padding: const EdgeInsets.only(bottom: 28),
                              child: _StepTile(
                                  icon: s.$1,
                                  number: s.$2,
                                  title: s.$3,
                                  body: s.$4),
                            ))
                        .toList(),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: steps.expand((s) sync* {
                      yield Expanded(
                          child: _StepCard(
                              icon: s.$1,
                              number: s.$2,
                              title: s.$3,
                              body: s.$4));
                      if (s != steps.last)
                        yield Padding(
                          padding: const EdgeInsets.only(top: 30),
                          child: Icon(Symbols.arrow_forward_ios,
                              color: AppColors.outlineVariant, size: 16),
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
  const _StepCard(
      {required this.icon,
      required this.number,
      required this.title,
      required this.body});
  final IconData icon;
  final String number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  color: AppColors.onTertiaryContainer, size: 30),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: const Color(0xFF34D399),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(number,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 10)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(title,
            style: AppTextStyles.labelBold.copyWith(fontSize: 14),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(body,
              style: AppTextStyles.labelSm
                  .copyWith(color: AppColors.onSurfaceVariant, height: 1.55),
              textAlign: TextAlign.center),
        ),
      ],
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile(
      {required this.icon,
      required this.number,
      required this.title,
      required this.body});
  final IconData icon;
  final String number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                  color: AppColors.primaryContainer, shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.onTertiaryContainer, size: 24),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                    color: const Color(0xFF34D399),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2)),
                child: Center(
                    child: Text(number,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 8))),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AppTextStyles.labelBold.copyWith(fontSize: 14)),
              const SizedBox(height: 4),
              Text(body,
                  style: AppTextStyles.labelSm
                      .copyWith(color: AppColors.onSurfaceVariant, height: 1.55)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Roles ────────────────────────────────────────────────────────────────────

class _RolesSection extends StatelessWidget {
  const _RolesSection();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 700;
    return Container(
      color: const Color(0xFF0A1929),
      padding: EdgeInsets.symmetric(
          vertical: 80, horizontal: isMobile ? 20 : 40),
      child: Column(
        children: [
          const _SectionHeader(
            tag: 'PARA TODOS',
            title: 'Hecho para Candidatos\ny Empresas',
            subtitle: 'Dos portales. Una plataforma poderosa.',
            dark: true,
          ),
          const SizedBox(height: 48),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: isMobile
                ? Column(children: [
                    _RoleCard(
                      icon: Symbols.person,
                      title: 'Para Candidatos',
                      accent: const Color(0xFF34D399),
                      features: const [
                        'Score de compatibilidad IA por oferta',
                        'Plataforma de assessments técnicos',
                        'Seguimiento de fortaleza de perfil',
                        'Pipeline de aplicaciones en tiempo real',
                      ],
                      ctaLabel: 'Crear perfil gratis',
                      onCta: () => context.go(AppRoutes.registerCandidate),
                    ),
                    const SizedBox(height: 20),
                    _RoleCard(
                      icon: Symbols.corporate_fare,
                      title: 'Para Empresas',
                      accent: const Color(0xFF60A5FA),
                      features: const [
                        'Pool de candidatos rankeados por IA',
                        'Dispatch automático de tests',
                        'Desglose del score de matching',
                        'Pipeline de contratación configurable',
                      ],
                      ctaLabel: 'Empezar a contratar',
                      onCta: () => context.go(AppRoutes.registerCompany),
                    ),
                  ])
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _RoleCard(
                          icon: Symbols.person,
                          title: 'Para Candidatos',
                          accent: const Color(0xFF34D399),
                          features: const [
                            'Score de compatibilidad IA por oferta',
                            'Plataforma de assessments técnicos',
                            'Seguimiento de fortaleza de perfil',
                            'Pipeline de aplicaciones en tiempo real',
                          ],
                          ctaLabel: 'Crear perfil gratis',
                          onCta: () =>
                              context.go(AppRoutes.registerCandidate),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _RoleCard(
                          icon: Symbols.corporate_fare,
                          title: 'Para Empresas',
                          accent: const Color(0xFF60A5FA),
                          features: const [
                            'Pool de candidatos rankeados por IA',
                            'Dispatch automático de tests',
                            'Desglose del score de matching',
                            'Pipeline de contratación configurable',
                          ],
                          ctaLabel: 'Empezar a contratar',
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
    required this.accent,
    required this.features,
    required this.ctaLabel,
    required this.onCta,
  });
  final IconData icon;
  final String title;
  final Color accent;
  final List<String> features;
  final String ctaLabel;
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 24),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: AppTextStyles.headlineMd
                  .copyWith(color: Colors.white, fontSize: 20)),
          const SizedBox(height: 20),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(Symbols.check_circle, size: 16, color: accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(f,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 13,
                              height: 1.4)),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onCta,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: const Color(0xFF000F1D),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: AppTextStyles.labelBold,
              ),
              child: Text(ctaLabel),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── CTA ─────────────────────────────────────────────────────────────────────

class _CtaSection extends StatelessWidget {
  const _CtaSection();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          isMobile ? 16 : 40, 0, isMobile ? 16 : 40, isMobile ? 40 : 56),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 24 : 64,
            vertical: isMobile ? 44 : 64),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF064E3B), Color(0xFF065F46)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
                color: Color(0x3034D399), blurRadius: 40, offset: Offset(0, 16))
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Symbols.auto_awesome,
                  color: Color(0xFF6EE7B7), size: 30),
            ),
            const SizedBox(height: 20),
            Text(
              '¿Listo para encontrar tu match perfecto?',
              style: AppTextStyles.headlineLg
                  .copyWith(color: Colors.white, letterSpacing: -0.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Text(
                'Únete a más de 10,000 profesionales y 500+ empresas que ya usan MatchIQ para contratar con inteligencia.',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    height: 1.65,
                    fontSize: 15),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 36),
            Wrap(
              spacing: 14,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => context.go(AppRoutes.registerCandidate),
                  icon: const Icon(Symbols.person, size: 18),
                  label: const Text('Soy candidato'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF064E3B),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    textStyle: AppTextStyles.labelBold,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go(AppRoutes.registerCompany),
                  icon: const Icon(Symbols.corporate_fare, size: 18),
                  label: const Text('Soy empresa'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.35)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    textStyle: AppTextStyles.labelBold,
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

// ─── Footer ──────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 20 : 40, vertical: 28),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: Row(
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                    gradient: AppColors.emeraldGradient,
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Symbols.auto_awesome,
                    color: Colors.white, size: 15),
              ),
              const SizedBox(width: 8),
              Text('MatchIQ',
                  style: AppTextStyles.labelBold
                      .copyWith(color: AppColors.primary)),
            ],
          ),
          const Spacer(),
          Flexible(
            child: Text(
              '© 2025 MatchIQ · Reclutamiento con IA',
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

// ─── Section header ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.tag,
    required this.title,
    required this.subtitle,
    this.dark = false,
  });
  final String tag;
  final String title;
  final String subtitle;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF34D399).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
                color: const Color(0xFF34D399).withValues(alpha: 0.3)),
          ),
          child: Text(tag,
              style: AppTextStyles.labelSm.copyWith(
                  color: const Color(0xFF34D399),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  fontSize: 11)),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          style: AppTextStyles.headlineLg.copyWith(
              color: dark ? Colors.white : AppColors.primary,
              letterSpacing: -0.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Text(
            subtitle,
            style: AppTextStyles.bodyMd.copyWith(
                color: dark
                    ? Colors.white.withValues(alpha: 0.45)
                    : AppColors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
