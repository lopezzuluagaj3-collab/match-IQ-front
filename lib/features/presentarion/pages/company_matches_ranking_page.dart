import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../config/router/app_routes.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../domain/entities/job_offer.dart';
import '../../domain/entities/user.dart';
import '../bloc/company_cubit.dart';
import '../../../config/theme/responsive.dart';
import '../widgets/shared/app_card.dart';
import '../widgets/shared/app_sidebar.dart';

class CompanyMatchesRankingPage extends StatefulWidget {
  const CompanyMatchesRankingPage({super.key});

  @override
  State<CompanyMatchesRankingPage> createState() =>
      _CompanyMatchesRankingPageState();
}

class _CompanyMatchesRankingPageState
    extends State<CompanyMatchesRankingPage> {
  @override
  void initState() {
    super.initState();
    context.read<CompanyCubit>().loadOffers();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithSidebar(
      currentRoute: AppRoutes.companyMatches,
      role: UserRole.company,
      child: BlocBuilder<CompanyCubit, CompanyState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: Responsive.pagePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _PageHeader(
                  offersCount: state.offers.length,
                  isLoading: state.isLoading,
                ),
                const SizedBox(height: 24),

                if (state.isLoading)
                  const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.onTertiaryContainer),
                  )
                else if (state.offers.isEmpty)
                  _EmptyOffersState()
                else
                  ...state.offers.map((offer) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _OfferCard(offer: offer),
                      )),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Page Header ─────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.offersCount, required this.isLoading});
  final int offersCount;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    final titleColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mis Ofertas', style: AppTextStyles.headlineLg),
        const SizedBox(height: 4),
        Text(
          '$offersCount oferta${offersCount == 1 ? '' : 's'} creada${offersCount == 1 ? '' : 's'}',
          style: AppTextStyles.bodyMd
              .copyWith(color: AppColors.onSurfaceVariant),
        ),
      ],
    );

    final refreshBtn = IconButton(
      tooltip: 'Refresh',
      onPressed: isLoading
          ? null
          : () => context.read<CompanyCubit>().loadOffers(),
      icon: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.onSurfaceVariant,
              ),
            )
          : const Icon(Symbols.refresh, color: AppColors.onSurfaceVariant),
    );

    final newOfferBtn = ElevatedButton.icon(
      onPressed: () => context.go(AppRoutes.createOffer),
      icon: const Icon(Symbols.add, size: 18),
      label: const Text('Nueva Oferta'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.onTertiaryContainer,
        foregroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleColumn,
          const SizedBox(height: 12),
          Row(
            children: [
              refreshBtn,
              const SizedBox(width: 8),
              Expanded(child: newOfferBtn),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: titleColumn),
        refreshBtn,
        const SizedBox(width: 8),
        newOfferBtn,
      ],
    );
  }
}

// ─── Offer Card ───────────────────────────────────────────────────────────────

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.offer});
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
    final id = int.tryParse(offer.id);

    return AppCard(
      child: InkWell(
        onTap: id == null
            ? null
            : () => context.push(AppRoutes.offerMatchesPath(id)),
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Symbols.work,
                  color: AppColors.onTertiaryContainer, size: 24),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(offer.title,
                            style: AppTextStyles.labelBold
                                .copyWith(fontSize: 15),
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
                      _MetaChip(
                          icon: Symbols.payments, label: offer.salary),
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
            const SizedBox(width: 12),

            // Setup & Pay (si pendiente)
            if (offer.isPendingPayment) ...[
              OutlinedButton.icon(
                onPressed: id == null
                    ? null
                    : () => context.go(AppRoutes.offerPendingPath(id)),
                icon: const Icon(Symbols.edit, size: 14),
                label: const Text('Setup & Pay'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: _statusColor),
                  foregroundColor: _statusColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(width: 10),
            ],

            // Arrow
            const Icon(Symbols.arrow_forward_ios,
                size: 16, color: AppColors.outline),
          ],
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyOffersState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64),
        child: Column(
          children: [
            const Icon(Symbols.work_outline,
                size: 56, color: AppColors.outlineVariant),
            const SizedBox(height: 16),
            Text('No tienes ofertas aún.',
                style: AppTextStyles.bodyLg
                    .copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 8),
            Text('Crea tu primera oferta para empezar a recibir candidatos.',
                style: AppTextStyles.bodyMd
                    .copyWith(color: AppColors.outline)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => context.go(AppRoutes.createOffer),
              icon: const Icon(Symbols.add, size: 16),
              label: const Text('Nueva Oferta'),
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
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

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
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600)),
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
