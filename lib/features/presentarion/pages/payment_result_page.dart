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
  const PaymentResultPage({super.key, this.offerId, this.sessionId});

  final int? offerId;
  final String? sessionId;

  @override
  State<PaymentResultPage> createState() => _PaymentResultPageState();
}

class _PaymentResultPageState extends State<PaymentResultPage> {
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    if (widget.sessionId != null) {
      context.read<CompanyCubit>().verifySession(widget.sessionId!);
    }
  }

  Future<void> _goToDashboard() async {
    if (!mounted || _isNavigating) return;
    setState(() => _isNavigating = true);
    await context.read<CompanyCubit>().loadDashboard();
    if (mounted) context.go(AppRoutes.companyDashboard);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CompanyCubit, CompanyState>(
      buildWhen: (prev, curr) =>
          prev.isSaving != curr.isSaving ||
          prev.sessionActivated != curr.sessionActivated ||
          prev.error != curr.error,
      builder: (context, state) {
        final isVerifying = widget.sessionId != null &&
            (state.isSaving || (state.sessionActivated == null && state.error == null));
        final isBlocked = isVerifying || _isNavigating;

        return Stack(
          children: [
            ScaffoldWithSidebar(
              currentRoute: AppRoutes.companyDashboard,
              role: UserRole.company,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: _buildBody(context, state),
                ),
              ),
            ),

            // Full-screen blocking overlay while verifying or navigating
            if (isBlocked) ...[
              const ModalBarrier(color: Colors.black54, dismissible: false),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1F0F2537),
                        blurRadius: 32,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 52,
                        height: 52,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: AppColors.onTertiaryContainer,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _isNavigating ? 'Loading dashboard…' : 'Verifying payment…',
                        style: AppTextStyles.headlineMd.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isNavigating
                            ? 'Almost there, please wait.'
                            : 'Confirming your payment with Stripe.',
                        style: AppTextStyles.bodyMd
                            .copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, CompanyState state) {
    // User cancelled in Stripe (no session_id in URL)
    if (widget.sessionId == null) {
      return _CancelBody(offerId: widget.offerId);
    }

    // Verifying — overlay handles the UI
    if (state.isSaving || (state.sessionActivated == null && state.error == null)) {
      return const SizedBox.shrink();
    }

    // Error from verify-session
    if (state.error != null) {
      return _ErrorBody(
        error: state.error!,
        offerId: widget.offerId,
        onRetry: () => context.read<CompanyCubit>().verifySession(widget.sessionId!),
      );
    }

    // Payment confirmed and offer activated
    if (state.sessionActivated == true) {
      return _SuccessBody(onGoNow: _goToDashboard);
    }

    // Payment not yet processed (Stripe may still be processing)
    return _PendingBody(
      offerId: widget.offerId,
      onRetry: () => context.read<CompanyCubit>().verifySession(widget.sessionId!),
    );
  }
}

// ─── Success ──────────────────────────────────────────────────────────────────

class _SuccessBody extends StatefulWidget {
  const _SuccessBody({required this.onGoNow});
  final VoidCallback onGoNow;

  @override
  State<_SuccessBody> createState() => _SuccessBodyState();
}

class _SuccessBodyState extends State<_SuccessBody> {
  int _countdown = 4;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      if (_countdown <= 1) {
        widget.onGoNow();
        return false;
      }
      setState(() => _countdown--);
      return true;
    });
  }

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
          onPressed: widget.onGoNow,
          icon: const Icon(Symbols.dashboard, size: 18),
          label: Text('Go to Dashboard ($_countdown)'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.onTertiaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}

// ─── Pending (Stripe still processing) ───────────────────────────────────────

class _PendingBody extends StatelessWidget {
  const _PendingBody({this.offerId, required this.onRetry});
  final int? offerId;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Symbols.hourglass_top,
              size: 48, color: Color(0xFFF59E0B)),
        ),
        const SizedBox(height: 24),
        Text('Payment Processing',
            style: AppTextStyles.headlineLg
                .copyWith(color: const Color(0xFFF59E0B))),
        const SizedBox(height: 10),
        Text(
          'Your payment is still being processed by Stripe.\nThis can take a few seconds — try checking again shortly.',
          textAlign: TextAlign.center,
          style:
              AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Symbols.refresh, size: 16),
              label: const Text('Check Again'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFF59E0B)),
                foregroundColor: const Color(0xFFF59E0B),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
            if (offerId != null) ...[
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () =>
                    context.go(AppRoutes.offerPendingPath(offerId!)),
                icon: const Icon(Symbols.arrow_back, size: 16),
                label: const Text('Back to Offer'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ],
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

// ─── Error ────────────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.error, this.offerId, required this.onRetry});
  final String error;
  final int? offerId;
  final VoidCallback onRetry;

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
          child: const Icon(Symbols.error, size: 48, color: AppColors.error),
        ),
        const SizedBox(height: 24),
        Text('Verification Failed',
            style: AppTextStyles.headlineLg.copyWith(color: AppColors.error)),
        const SizedBox(height: 10),
        Text(
          error,
          textAlign: TextAlign.center,
          style:
              AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Symbols.refresh, size: 16),
              label: const Text('Try Again'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                foregroundColor: AppColors.error,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
            if (offerId != null) ...[
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () =>
                    context.go(AppRoutes.offerPendingPath(offerId!)),
                icon: const Icon(Symbols.arrow_back, size: 16),
                label: const Text('Back to Offer'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
