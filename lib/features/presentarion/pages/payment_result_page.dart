import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../config/router/app_routes.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../domain/entities/user.dart';
import '../bloc/company_cubit.dart';
import '../widgets/shared/app_sidebar.dart';

class PaymentResultPage extends StatefulWidget {
  const PaymentResultPage({super.key, required this.success, this.offerId});

  final bool success;
  final int? offerId;

  @override
  State<PaymentResultPage> createState() => _PaymentResultPageState();
}

class _PaymentResultPageState extends State<PaymentResultPage> {
  Timer? _redirectTimer;
  int _countdown = 4;

  @override
  void initState() {
    super.initState();
    if (widget.success) {
      _startRedirectCountdown();
    }
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    super.dispose();
  }

  void _startRedirectCountdown() {
    _redirectTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_countdown <= 1) {
        t.cancel();
        _goToDashboard();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  Future<void> _goToDashboard() async {
    if (!mounted) return;
    await context.read<CompanyCubit>().loadDashboard();
    if (mounted) context.go(AppRoutes.companyDashboard);
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithSidebar(
      currentRoute: AppRoutes.companyDashboard,
      role: UserRole.company,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: widget.success ? _SuccessBody(
            countdown: _countdown,
            onGoNow: _goToDashboard,
          ) : _CancelBody(
            offerId: widget.offerId,
          ),
        ),
      ),
    );
  }
}

// ─── Success ──────────────────────────────────────────────────────────────────

class _SuccessBody extends StatelessWidget {
  const _SuccessBody({required this.countdown, required this.onGoNow});
  final int countdown;
  final VoidCallback onGoNow;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: AppColors.onTertiaryContainer.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Symbols.check_circle,
              size: 48, color: AppColors.onTertiaryContainer),
        ),
        const SizedBox(height: 24),
        Text('Payment Confirmed!',
            style: AppTextStyles.headlineLg
                .copyWith(color: AppColors.onTertiaryContainer)),
        const SizedBox(height: 10),
        Text(
          'Your offer is now active and candidates will start matching.',
          textAlign: TextAlign.center,
          style:
              AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: onGoNow,
          icon: const Icon(Symbols.dashboard, size: 18),
          label: Text('Go to Dashboard ($countdown)'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.onTertiaryContainer,
            padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}

// ─── Cancel ───────────────────────────────────────────────────────────────────

class _CancelBody extends StatelessWidget {
  const _CancelBody({this.offerId});
  final int? offerId;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(Symbols.cancel,
              size: 48, color: AppColors.error.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: 24),
        Text('Payment Cancelled',
            style: AppTextStyles.headlineLg.copyWith(color: AppColors.error)),
        const SizedBox(height: 10),
        Text(
          'Your offer is still in Pending Payment status.\nYou can try again whenever you\'re ready.',
          textAlign: TextAlign.center,
          style:
              AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (offerId != null)
              OutlinedButton.icon(
                onPressed: () =>
                    context.go(AppRoutes.offerPendingPath(offerId!)),
                icon: const Icon(Symbols.arrow_back, size: 16),
                label: const Text('Back to Offer'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.outlineVariant),
                  foregroundColor: AppColors.onSurface,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                ),
              ),
            if (offerId != null) const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: () => context.go(AppRoutes.companyDashboard),
              icon: const Icon(Symbols.dashboard, size: 16),
              label: const Text('Go to Dashboard'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
