import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/router/app_routes.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../config/theme/responsive.dart';
import '../../domain/entities/technical_test.dart';
import '../../domain/entities/user.dart';
import '../bloc/company_cubit.dart';
import '../widgets/shared/app_card.dart';
import '../widgets/shared/app_sidebar.dart';
import '../widgets/shared/app_text_field.dart';

class OfferPendingPage extends StatefulWidget {
  const OfferPendingPage({super.key, required this.offerId});

  final int offerId;

  @override
  State<OfferPendingPage> createState() => _OfferPendingPageState();
}

class _OfferPendingPageState extends State<OfferPendingPage> {
  final _timeLimitCtrl = TextEditingController(text: '45');
  bool _waitingForPayment = false;
  Timer? _pollTimer;
  int _pollSeconds = 0;
  static const _pollInterval = 5;
  static const _pollTimeoutSeconds = 600; // 10 min

  @override
  void initState() {
    super.initState();
    context.read<CompanyCubit>().loadTestForOffer(widget.offerId);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _timeLimitCtrl.dispose();
    super.dispose();
  }

  int get _timeLimit => int.tryParse(_timeLimitCtrl.text.trim()) ?? 45;

  void _startPolling() {
    _pollSeconds = 0;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: _pollInterval), (_) async {
      _pollSeconds += _pollInterval;

      if (_pollSeconds >= _pollTimeoutSeconds) {
        _pollTimer?.cancel();
        if (mounted) {
          setState(() => _waitingForPayment = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Payment not confirmed yet. Refresh the page once you complete the payment.'),
              backgroundColor: AppColors.error,
              duration: Duration(seconds: 6),
            ),
          );
        }
        return;
      }

      if (!mounted) { _pollTimer?.cancel(); return; }

      await context.read<CompanyCubit>().refreshOffer(widget.offerId);
      if (!mounted) return;

      final offers = context.read<CompanyCubit>().state.offers;
      final updated = offers
          .where((o) => o.id == widget.offerId.toString())
          .firstOrNull;

      if (updated != null && updated.status != 'PendingPayment') {
        _pollTimer?.cancel();
        if (mounted) context.go(AppRoutes.companyDashboard);
      }
    });
  }

  Future<void> _checkNow() async {
    await context.read<CompanyCubit>().refreshOffer(widget.offerId);
    if (!mounted) return;
    final offers = context.read<CompanyCubit>().state.offers;
    final updated =
        offers.where((o) => o.id == widget.offerId.toString()).firstOrNull;
    if (updated != null && updated.status != 'PendingPayment') {
      _pollTimer?.cancel();
      context.go(AppRoutes.companyDashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CompanyCubit, CompanyState>(
      listenWhen: (prev, curr) =>
          (curr.checkoutUrl != prev.checkoutUrl && curr.checkoutUrl != null) ||
          (curr.offerActivated && !prev.offerActivated),
      listener: (context, state) {
        if (state.offerActivated) {
          _pollTimer?.cancel();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Payment already confirmed — your offer is now active!'),
              backgroundColor: Color(0xFF16A34A),
              duration: Duration(seconds: 4),
            ),
          );
          context.read<CompanyCubit>().loadDashboard();
          context.go(AppRoutes.companyDashboard);
          return;
        }
        if (state.checkoutUrl != null && !_waitingForPayment) {
          final uri = Uri.tryParse(state.checkoutUrl!);
          if (uri != null) {
            launchUrl(uri, mode: LaunchMode.externalApplication);
          }
          setState(() => _waitingForPayment = true);
          _startPolling();
        }
      },
      child: ScaffoldWithSidebar(
        currentRoute: AppRoutes.offerPending,
        role: UserRole.company,
        child: BlocBuilder<CompanyCubit, CompanyState>(
          builder: (context, state) {
            final offer = state.createdOffer ??
                state.offers
                    .where((o) => o.id == widget.offerId.toString())
                    .firstOrNull;
            final offerTitle = offer?.title ?? 'Offer #${widget.offerId}';
            final offerStatus = offer?.statusLabel ?? 'Pending Payment';

            return SingleChildScrollView(
              padding: Responsive.pagePadding(context),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ──────────────────────────────────────────
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => context.go(AppRoutes.companyDashboard),
                          icon: const Icon(Symbols.arrow_back,
                              color: AppColors.onSurface),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(offerTitle,
                                  style: AppTextStyles.headlineLg,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              StatusBadge(
                                label: offerStatus,
                                color: const Color(0xFFF59E0B),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // ── Test Configuration Card ──────────────────────────
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: AppColors.emeraldGradient,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Symbols.auto_awesome,
                                    color: Colors.white, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Text('Test Configuration',
                                  style: AppTextStyles.headlineMd
                                      .copyWith(fontSize: 18)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Generate a technical test with AI or adjust existing questions before paying.',
                            style: AppTextStyles.bodyMd
                                .copyWith(color: AppColors.onSurfaceVariant),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: 200,
                            child: AppTextField(
                              label: 'Time limit (min)',
                              hint: '45',
                              prefixIcon: Symbols.timer,
                              controller: _timeLimitCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (state.isParsing)
                            const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.onTertiaryContainer,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text('Generating...'),
                              ],
                            )
                          else
                            Row(
                              children: [
                                AppButton(
                                  label: state.testSession == null
                                      ? 'Generate Test with AI'
                                      : 'Regenerate Test',
                                  isEmerald: true,
                                  icon: Symbols.auto_awesome,
                                  onPressed: () {
                                    if (state.testSession == null) {
                                      context
                                          .read<CompanyCubit>()
                                          .generateTest(
                                              widget.offerId, _timeLimit);
                                    } else {
                                      context
                                          .read<CompanyCubit>()
                                          .regenerateTest(
                                              widget.offerId, _timeLimit);
                                    }
                                  },
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Test Questions Card ──────────────────────────────
                    if (state.testSession != null) ...[
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Symbols.quiz,
                                    color: AppColors.secondary, size: 22),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        state.testSession!.title,
                                        style: AppTextStyles.headlineMd
                                            .copyWith(fontSize: 18),
                                      ),
                                      Text(
                                        '${state.testSession!.timeLimitMinutes} min · ${state.testSession!.questions.length} questions',
                                        style: AppTextStyles.labelSm.copyWith(
                                            color: AppColors.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ...state.testSession!.questions
                                .asMap()
                                .entries
                                .map((entry) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: _QuestionTile(
                                        index: entry.key,
                                        question: entry.value,
                                      ),
                                    )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── CTA Footer ───────────────────────────────────────
                    if (_waitingForPayment)
                      _PaymentWaitingCard(onCheckNow: _checkNow)
                    else
                      Row(
                        children: [
                          OutlinedButton(
                            onPressed: state.isSaving
                                ? null
                                : () =>
                                    context.go(AppRoutes.companyDashboard),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: AppColors.outlineVariant),
                              foregroundColor: AppColors.onSurface,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 14),
                            ),
                            child: const Text('Cancel Offer'),
                          ),
                          const Spacer(),
                          AppButton(
                            label: 'Proceed to Payment',
                            isEmerald: true,
                            icon: Symbols.arrow_forward,
                            isLoading: state.isSaving,
                            onPressed: state.isSaving
                                ? null
                                : () => context
                                    .read<CompanyCubit>()
                                    .createCheckout(widget.offerId),
                          ),
                        ],
                      ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Payment waiting card ─────────────────────────────────────────────────────

class _PaymentWaitingCard extends StatefulWidget {
  const _PaymentWaitingCard({required this.onCheckNow});
  final VoidCallback onCheckNow;

  @override
  State<_PaymentWaitingCard> createState() => _PaymentWaitingCardState();
}

class _PaymentWaitingCardState extends State<_PaymentWaitingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.onTertiaryContainer.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.onTertiaryContainer.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, child) => Opacity(
              opacity: 0.5 + _pulse.value * 0.5,
              child: child,
            ),
            child: const Icon(Symbols.payment,
                size: 40, color: AppColors.onTertiaryContainer),
          ),
          const SizedBox(height: 16),
          Text('Waiting for payment confirmation',
              style: AppTextStyles.headlineMd.copyWith(
                  fontSize: 17, color: AppColors.onTertiaryContainer)),
          const SizedBox(height: 8),
          Text(
            'Complete the payment in the tab that just opened.\nThis page will update automatically once confirmed.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd
                .copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.onTertiaryContainer,
                ),
              ),
              const SizedBox(width: 10),
              Text('Checking every 5 seconds…',
                  style: AppTextStyles.labelSm
                      .copyWith(color: AppColors.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: widget.onCheckNow,
            icon: const Icon(Symbols.refresh, size: 16),
            label: const Text('Check Now'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.onTertiaryContainer),
              foregroundColor: AppColors.onTertiaryContainer,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Question tile ────────────────────────────────────────────────────────────

class _QuestionTile extends StatefulWidget {
  const _QuestionTile({required this.index, required this.question});

  final int index;
  final TestQuestion question;

  @override
  State<_QuestionTile> createState() => _QuestionTileState();
}

class _QuestionTileState extends State<_QuestionTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final badge = q.isMultipleChoice ? 'MultipleChoice' : 'CodeChallenge';
    final badgeColor =
        q.isMultipleChoice ? AppColors.secondary : AppColors.onTertiaryContainer;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text(
                    '#${widget.index + 1}',
                    style: AppTextStyles.labelBold
                        .copyWith(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                          color: badgeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      q.questionText.length > 80
                          ? '${q.questionText.substring(0, 80)}...'
                          : q.questionText,
                      style: AppTextStyles.labelSm,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Symbols.keyboard_arrow_up
                        : Symbols.keyboard_arrow_down,
                    color: AppColors.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Expanded content
          if (_expanded) ...[
            const Divider(height: 1, color: AppColors.outlineVariant),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Full question text
                  Text(q.questionText, style: AppTextStyles.bodyMd),
                  const SizedBox(height: 12),

                  // MultipleChoice options
                  if (q.isMultipleChoice && q.options != null) ...[
                    ...q.options!.entries.map((e) {
                      final isCorrect =
                          q.correctAnswer != null && e.key == q.correctAnswer;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isCorrect
                                    ? AppColors.onTertiaryContainer
                                        .withValues(alpha: 0.15)
                                    : AppColors.surfaceContainer,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isCorrect
                                      ? AppColors.onTertiaryContainer
                                      : AppColors.outlineVariant,
                                ),
                              ),
                              child: Text(
                                e.key,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: isCorrect
                                      ? AppColors.onTertiaryContainer
                                      : AppColors.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                e.value,
                                style: AppTextStyles.bodyMd.copyWith(
                                  color: isCorrect
                                      ? AppColors.onTertiaryContainer
                                      : AppColors.onSurface,
                                  fontWeight: isCorrect
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                            if (isCorrect)
                              const Icon(Symbols.check_circle,
                                  color: AppColors.onTertiaryContainer,
                                  size: 18),
                          ],
                        ),
                      );
                    }),
                  ],

                  // CodeChallenge details
                  if (!q.isMultipleChoice) ...[
                    if (q.functionSignature != null) ...[
                      Text('Function signature:',
                          style: AppTextStyles.labelBold),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(q.functionSignature!,
                            style: const TextStyle(
                                fontFamily: 'monospace', fontSize: 13)),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (q.exampleInput != null) ...[
                      Text('Example input:', style: AppTextStyles.labelBold),
                      const SizedBox(height: 4),
                      Text(q.exampleInput!, style: AppTextStyles.bodyMd),
                      const SizedBox(height: 8),
                    ],
                    if (q.expectedBehavior != null) ...[
                      Text('Expected behavior:',
                          style: AppTextStyles.labelBold),
                      const SizedBox(height: 4),
                      Text(q.expectedBehavior!, style: AppTextStyles.bodyMd),
                      const SizedBox(height: 8),
                    ],
                  ],

                  // Explanation
                  if (q.explanation != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color:
                            AppColors.secondaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Symbols.info,
                              size: 16, color: AppColors.secondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(q.explanation!,
                                style: AppTextStyles.labelSm.copyWith(
                                    color: AppColors.onSecondaryContainer)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Edit with AI button
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: () => _showChatDialog(context, q),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.secondary),
                        foregroundColor: AppColors.secondary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      icon: const Icon(Symbols.auto_awesome, size: 16),
                      label: const Text('Edit with AI'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showChatDialog(BuildContext context, TestQuestion question) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<CompanyCubit>(),
        child: _ChatDialog(question: question),
      ),
    );
  }
}

// ─── Chat dialog ──────────────────────────────────────────────────────────────

class _ChatDialog extends StatefulWidget {
  const _ChatDialog({required this.question});

  final TestQuestion question;

  @override
  State<_ChatDialog> createState() => _ChatDialogState();
}

class _ChatDialogState extends State<_ChatDialog> {
  final _ctrl = TextEditingController();
  String? _assistantMessage;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _send() {
    final msg = _ctrl.text.trim();
    if (msg.isEmpty) return;
    context.read<CompanyCubit>().chatWithQuestion(widget.question.id, msg);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CompanyCubit, CompanyState>(
      listenWhen: (prev, curr) =>
          curr.lastChatMessage != prev.lastChatMessage &&
          curr.lastChatMessage != null,
      listener: (context, state) {
        setState(() => _assistantMessage = state.lastChatMessage);
        _ctrl.clear();
      },
      builder: (context, state) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Symbols.auto_awesome,
                  color: AppColors.onTertiaryContainer, size: 20),
              const SizedBox(width: 8),
              Text('Edit question with AI',
                  style: AppTextStyles.headlineMd.copyWith(fontSize: 17)),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Question #${widget.question.orderIndex + 1}',
                  style: AppTextStyles.labelBold
                      .copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.question.questionText.length > 120
                      ? '${widget.question.questionText.substring(0, 120)}...'
                      : widget.question.questionText,
                  style: AppTextStyles.bodyMd,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _ctrl,
                  maxLines: 3,
                  enabled: !state.isSaving,
                  decoration: InputDecoration(
                    hintText:
                        'e.g. "Make this question harder" or "Translate to Spanish"',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                if (state.isSaving)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: CircularProgressIndicator(
                        color: AppColors.onTertiaryContainer,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                if (_assistantMessage != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.onTertiaryContainer.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.onTertiaryContainer
                              .withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Symbols.check_circle,
                                size: 15,
                                color: AppColors.onTertiaryContainer),
                            const SizedBox(width: 6),
                            Text('AI Response',
                                style: AppTextStyles.labelBold.copyWith(
                                    color: AppColors.onTertiaryContainer)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(_assistantMessage!,
                            style: AppTextStyles.bodyMd.copyWith(
                                color: AppColors.onTertiaryContainer)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: state.isSaving ? null : _send,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.onTertiaryContainer,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Symbols.send, size: 16),
              label: const Text('Send'),
            ),
          ],
        );
      },
    );
  }
}
