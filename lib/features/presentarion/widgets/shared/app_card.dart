import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../config/theme/app_colors.dart';
import '../../bloc/theme_cubit.dart';

// ── AppCard — theme-aware surface card ──────────────────────────────────────

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.borderColor,
    this.radius = 24,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? borderColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = Theme.of(context).colorScheme.surface;
    final shadow = isDark
        ? const [BoxShadow(color: Colors.black38, blurRadius: 16, offset: Offset(0, 4))]
        : const [BoxShadow(color: Color(0x140F2537), blurRadius: 20, offset: Offset(0, 4))];

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(radius),
          border: borderColor != null ? Border.all(color: borderColor!, width: 1.5) : null,
          boxShadow: shadow,
        ),
        padding: padding ?? const EdgeInsets.all(20),
        child: child,
      ),
    );
  }
}

// ── FadeSlideCard — entrance animation wrapper ───────────────────────────────

class FadeSlideCard extends StatefulWidget {
  const FadeSlideCard({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.padding,
    this.onTap,
    this.borderColor,
    this.radius = 24,
  });

  final Widget child;
  final Duration delay;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? borderColor;
  final double radius;

  @override
  State<FadeSlideCard> createState() => _FadeSlideCardState();
}

class _FadeSlideCardState extends State<FadeSlideCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.07),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: AppCard(
          padding: widget.padding,
          onTap: widget.onTap,
          borderColor: widget.borderColor,
          radius: widget.radius,
          child: widget.child,
        ),
      ),
    );
  }
}

// ── EmeraldBadge ─────────────────────────────────────────────────────────────

class EmeraldBadge extends StatelessWidget {
  const EmeraldBadge({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.onTertiaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.onTertiaryContainer,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── AIPulseBadge — animated emerald glow for AI elements ─────────────────────

class AIPulseBadge extends StatefulWidget {
  const AIPulseBadge({super.key, required this.label});
  final String label;

  @override
  State<AIPulseBadge> createState() => _AIPulseBadgeState();
}

class _AIPulseBadgeState extends State<AIPulseBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _glow = Tween<double>(begin: 0.08, end: 0.18).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.onTertiaryContainer.withValues(alpha: _glow.value),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppColors.onTertiaryContainer.withValues(alpha: _glow.value * 0.6),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              color: AppColors.onTertiaryContainer,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ── StatusBadge ───────────────────────────────────────────────────────────────

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── ThemeToggleButton — reutilizable en cualquier página ─────────────────────

class ThemeToggleButton extends StatelessWidget {
  /// [onDark] = true cuando el botón se coloca sobre un fondo siempre oscuro
  /// (ej: navbar navy). false = detecta el tema actual para el estilo.
  const ThemeToggleButton({super.key, this.onDark = false});
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (ctx, mode) {
        final isDark = mode == ThemeMode.dark;
        final onDarkBg = onDark || isDark;
        return Tooltip(
          message: isDark ? 'Modo día' : 'Modo noche',
          child: GestureDetector(
            onTap: () => ctx.read<ThemeCubit>().toggle(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: onDarkBg
                    ? Colors.white.withValues(alpha: isDark ? 0.12 : 0.06)
                    : AppColors.primaryContainer.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: onDark
                    ? null
                    : Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : AppColors.outlineVariant,
                      ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (child, anim) => RotationTransition(
                  turns: Tween<double>(begin: 0.25, end: 0.0).animate(anim),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: Icon(
                  isDark ? Symbols.light_mode : Symbols.dark_mode,
                  key: ValueKey(isDark),
                  color: onDarkBg
                      ? (isDark
                          ? AppColors.onTertiaryContainer
                          : AppColors.onPrimaryContainer)
                      : AppColors.primary,
                  size: 20,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
