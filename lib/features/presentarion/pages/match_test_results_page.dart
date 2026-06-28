import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../domain/entities/technical_test.dart';
import '../../domain/entities/user.dart';
import '../bloc/company_cubit.dart';
import '../widgets/shared/app_card.dart';
import '../widgets/shared/app_sidebar.dart';

class MatchTestResultsPage extends StatefulWidget {
  const MatchTestResultsPage({super.key, required this.matchId});
  final int matchId;

  @override
  State<MatchTestResultsPage> createState() => _MatchTestResultsPageState();
}

class _MatchTestResultsPageState extends State<MatchTestResultsPage> {
  @override
  void initState() {
    super.initState();
    context.read<CompanyCubit>().loadTestSubmission(widget.matchId);
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithSidebar(
      currentRoute: '/company/matches',
      role: UserRole.company,
      child: BlocBuilder<CompanyCubit, CompanyState>(
        builder: (context, state) {
          if (state.isLoadingSubmission) {
            return const Center(
              child: CircularProgressIndicator(
                  color: AppColors.onTertiaryContainer),
            );
          }
          if (state.error != null && state.testSubmission == null) {
            return _ErrorState(
              message: state.error!,
              onRetry: () =>
                  context.read<CompanyCubit>().loadTestSubmission(widget.matchId),
            );
          }
          final submission = state.testSubmission;
          if (submission == null) {
            return const _ErrorState(message: 'No se encontraron resultados.');
          }
          return _SubmissionContent(submission: submission);
        },
      ),
    );
  }
}

// ─── Main content ─────────────────────────────────────────────────────────────

class _SubmissionContent extends StatelessWidget {
  const _SubmissionContent({required this.submission});
  final MatchTestSubmission submission;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back + breadcrumb
          Row(
            children: [
              InkWell(
                onTap: () => context.pop(),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Symbols.arrow_back_ios_new,
                          size: 14, color: AppColors.secondary),
                      const SizedBox(width: 6),
                      Text('Back to Offers',
                          style: AppTextStyles.labelBold
                              .copyWith(color: AppColors.secondary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Header hero card
          _HeroCard(submission: submission),
          const SizedBox(height: 24),

          // Estado pendiente / fallido
          if (submission.isPending) ...[
            _PendingCard(status: submission.status),
            const SizedBox(height: 24),
          ],

          // AI Feedback global
          if (submission.globalFeedback != null) ...[
            _FeedbackCard(feedback: submission.globalFeedback!),
            const SizedBox(height: 24),
          ],

          // Questions breakdown
          Text('Respuestas del Candidato', style: AppTextStyles.headlineMd),
          const SizedBox(height: 4),
          Text(
            '${submission.totalQuestions} preguntas · ${submission.correctAnswers} correctas',
            style:
                AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          ...submission.questions.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _QuestionCard(
                  index: e.key + 1,
                  question: e.value,
                ),
              )),
        ],
      ),
    );
  }
}

// ─── Hero card ────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.submission});
  final MatchTestSubmission submission;

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $h:$m';
  }

  Color get _scoreColor {
    final s = submission.score ?? 0;
    if (s >= 80) return AppColors.onTertiaryContainer;
    if (s >= 60) return AppColors.secondary;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = submission.submittedAt != null
        ? _formatDate(submission.submittedAt!)
        : null;
    final totalQ = submission.totalQuestions;
    final correct = submission.correctAnswers;
    final pct = totalQ > 0 ? correct / totalQ : 0.0;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2537), Color(0xFF000F1D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
              color: Color(0x1A0F2537),
              blurRadius: 20,
              offset: Offset(0, 8)),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                submission.candidateName.isNotEmpty
                    ? submission.candidateName[0].toUpperCase()
                    : '?',
                style: AppTextStyles.headlineLg
                    .copyWith(color: Colors.white, fontSize: 26),
              ),
            ),
          ),
          const SizedBox(width: 20),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(submission.candidateName,
                    style: AppTextStyles.headlineMd
                        .copyWith(color: Colors.white, fontSize: 22)),
                const SizedBox(height: 4),
                if (dateStr != null) ...[
                  const SizedBox(height: 6),
                  _InfoChip(
                      icon: Symbols.calendar_today,
                      label: 'Enviado: $dateStr',
                      light: true),
                ],
                const SizedBox(height: 6),
                _StatusChip(status: submission.status),
              ],
            ),
          ),
          const SizedBox(width: 24),

          // Score ring
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: (submission.score ?? 0) / 100,
                      strokeWidth: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation(_scoreColor),
                      strokeCap: StrokeCap.round,
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            submission.score != null
                                ? '${submission.score!.toStringAsFixed(0)}%'
                                : 'N/A',
                            style: AppTextStyles.headlineMd.copyWith(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800),
                          ),
                          Text('score',
                              style: AppTextStyles.labelSm.copyWith(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Mini progress bar for correct/total
              SizedBox(
                width: 100,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$correct/$totalQ correctas',
                            style: AppTextStyles.labelSm.copyWith(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor:
                            Colors.white.withValues(alpha: 0.1),
                        valueColor:
                            AlwaysStoppedAnimation(_scoreColor),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Pending evaluation card ──────────────────────────────────────────────────

class _PendingCard extends StatelessWidget {
  const _PendingCard({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final isFailed = status == 'Failed';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isFailed ? AppColors.error : const Color(0xFFF59E0B))
            .withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isFailed ? AppColors.error : const Color(0xFFF59E0B))
              .withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isFailed ? Symbols.error_outline : Symbols.hourglass_top,
            size: 20,
            color: isFailed ? AppColors.error : const Color(0xFFF59E0B),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isFailed
                  ? 'La evaluación de la IA falló y será reintentada automáticamente.'
                  : 'El candidato completó el test. La IA está procesando la evaluación.',
              style: AppTextStyles.bodyMd.copyWith(
                  color: isFailed ? AppColors.error : const Color(0xFF92400E)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Status chip ──────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'Evaluated' => ('Evaluado', AppColors.onTertiaryContainer),
      'Pending' => ('Pendiente', const Color(0xFFF59E0B)),
      'Failed' => ('Error', AppColors.error),
      _ => (status, AppColors.outline),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(label,
          style: AppTextStyles.labelSm
              .copyWith(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

// ─── AI Feedback card ─────────────────────────────────────────────────────────

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.feedback});
  final String feedback;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.onTertiaryContainer.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Symbols.auto_awesome,
                    size: 18, color: AppColors.onTertiaryContainer),
              ),
              const SizedBox(width: 12),
              Text('Evaluación de IA', style: AppTextStyles.headlineMd),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.onTertiaryContainer.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color:
                      AppColors.onTertiaryContainer.withValues(alpha: 0.15)),
            ),
            child: Text(feedback,
                style:
                    AppTextStyles.bodyMd.copyWith(height: 1.6)),
          ),
        ],
      ),
    );
  }
}

// ─── Question card ────────────────────────────────────────────────────────────

class _QuestionCard extends StatefulWidget {
  const _QuestionCard({required this.index, required this.question});
  final int index;
  final SubmissionQuestion question;

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final isCorrect = q.isCorrect;
    final statusColor = isCorrect == true
        ? AppColors.onTertiaryContainer
        : isCorrect == false
            ? AppColors.error
            : AppColors.outline;
    final statusIcon = isCorrect == true
        ? Symbols.check_circle
        : isCorrect == false
            ? Symbols.cancel
            : Symbols.help;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Q number
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text('${widget.index}',
                        style: AppTextStyles.labelBold
                            .copyWith(color: statusColor, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _TypeChip(type: q.questionType),
                          const Spacer(),
                          Icon(statusIcon, size: 18, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            isCorrect == true
                                ? 'Correcta'
                                : isCorrect == false
                                    ? 'Incorrecta'
                                    : 'Sin evaluar',
                            style: AppTextStyles.labelSm
                                .copyWith(color: statusColor, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(q.questionText,
                          style: AppTextStyles.bodyMd
                              .copyWith(fontWeight: FontWeight.w500, height: 1.4)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _expanded
                      ? Symbols.keyboard_arrow_up
                      : Symbols.keyboard_arrow_down,
                  color: AppColors.outline,
                  size: 20,
                ),
              ],
            ),
          ),

          // Expanded detail
          if (_expanded) ...[
            const SizedBox(height: 16),
            const Divider(color: AppColors.outlineVariant),
            const SizedBox(height: 12),
            if (q.isMultipleChoice && q.options != null)
              _MultipleChoiceDetail(question: q)
            else if (q.codeSubmitted != null || q.functionSignature != null)
              _CodeDetail(question: q),
            if (q.aiFeedback != null) ...[
              const SizedBox(height: 12),
              _ExplanationBox(text: q.aiFeedback!),
            ],
          ],
        ],
      ),
    );
  }
}

// ─── Multiple choice answer detail ────────────────────────────────────────────

class _MultipleChoiceDetail extends StatelessWidget {
  const _MultipleChoiceDetail({required this.question});
  final SubmissionQuestion question;

  @override
  Widget build(BuildContext context) {
    final options = question.options!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: options.entries.map((entry) {
        final key = entry.key;
        final isCorrect = key == question.correctAnswer;
        final isSelected = key == question.selectedOption;

        Color bgColor = AppColors.surfaceContainerLow;
        Color borderColor = AppColors.outlineVariant.withValues(alpha: 0.4);
        Color textColor = AppColors.onSurface;
        Widget? trailing;

        if (isCorrect && isSelected) {
          bgColor = AppColors.onTertiaryContainer.withValues(alpha: 0.08);
          borderColor = AppColors.onTertiaryContainer.withValues(alpha: 0.4);
          textColor = AppColors.onSurface;
          trailing = const Icon(Symbols.check_circle,
              size: 18, color: AppColors.onTertiaryContainer);
        } else if (isCorrect) {
          bgColor = AppColors.onTertiaryContainer.withValues(alpha: 0.06);
          borderColor = AppColors.onTertiaryContainer.withValues(alpha: 0.3);
          trailing = const Icon(Symbols.check_circle,
              size: 18, color: AppColors.onTertiaryContainer);
        } else if (isSelected) {
          bgColor = AppColors.error.withValues(alpha: 0.06);
          borderColor = AppColors.error.withValues(alpha: 0.35);
          textColor = AppColors.error;
          trailing = Icon(Symbols.cancel,
              size: 18, color: AppColors.error.withValues(alpha: 0.8));
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? AppColors.onTertiaryContainer.withValues(alpha: 0.15)
                        : isSelected
                            ? AppColors.error.withValues(alpha: 0.1)
                            : AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(key,
                        style: AppTextStyles.labelBold.copyWith(
                            fontSize: 12,
                            color: isCorrect
                                ? AppColors.onTertiaryContainer
                                : isSelected
                                    ? AppColors.error
                                    : AppColors.onSurfaceVariant)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(entry.value,
                      style: AppTextStyles.bodyMd
                          .copyWith(color: textColor, fontSize: 14)),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing,
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Code challenge detail ────────────────────────────────────────────────────

class _CodeDetail extends StatelessWidget {
  const _CodeDetail({required this.question});
  final SubmissionQuestion question;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (question.functionSignature != null) ...[
          Text('Firma esperada',
              style: AppTextStyles.labelBold
                  .copyWith(color: AppColors.onSurfaceVariant, fontSize: 12)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(question.functionSignature!,
                style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: Colors.white70,
                    height: 1.5)),
          ),
          const SizedBox(height: 12),
        ],
        Text(
          question.codeSubmitted != null
              ? 'Código enviado'
              : 'Sin respuesta enviada',
          style: AppTextStyles.labelBold
              .copyWith(color: AppColors.onSurfaceVariant, fontSize: 12),
        ),
        const SizedBox(height: 6),
        if (question.codeSubmitted != null)
          _CodeBlock(
            code: question.codeSubmitted!,
            isCorrect: question.isCorrect,
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Symbols.code_off,
                    size: 16, color: AppColors.outline),
                const SizedBox(width: 8),
                Text('El candidato no envió código.',
                    style: AppTextStyles.bodyMd
                        .copyWith(color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
      ],
    );
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.code, this.isCorrect});
  final String code;
  final bool? isCorrect;

  @override
  Widget build(BuildContext context) {
    final borderColor = isCorrect == true
        ? AppColors.onTertiaryContainer.withValues(alpha: 0.4)
        : isCorrect == false
            ? AppColors.error.withValues(alpha: 0.3)
            : AppColors.outlineVariant.withValues(alpha: 0.4);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // code header tab
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Symbols.code, size: 13, color: Color(0xFF8B949E)),
                SizedBox(width: 6),
                Text('Código enviado',
                    style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8B949E),
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              code,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: Color(0xFFE6EDF3),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Explanation box ──────────────────────────────────────────────────────────

class _ExplanationBox extends StatelessWidget {
  const _ExplanationBox({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(Symbols.lightbulb,
                size: 15,
                color: AppColors.secondary.withValues(alpha: 0.8)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurface,
                    fontSize: 13,
                    height: 1.5)),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    final isCode = type == 'CodeChallenge';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isCode
            ? AppColors.secondary.withValues(alpha: 0.1)
            : AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCode ? Symbols.code : Symbols.radio_button_checked,
            size: 11,
            color: isCode ? AppColors.secondary : AppColors.outline,
          ),
          const SizedBox(width: 4),
          Text(
            isCode ? 'Código' : 'Opción múltiple',
            style: AppTextStyles.labelSm.copyWith(
                fontSize: 10,
                color: isCode ? AppColors.secondary : AppColors.outline,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(
      {required this.icon, required this.label, this.light = false});
  final IconData icon;
  final String label;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final color =
        light ? Colors.white.withValues(alpha: 0.6) : AppColors.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Flexible(
          child: Text(label,
              style: AppTextStyles.labelSm.copyWith(color: color),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Symbols.error_outline,
              size: 48, color: AppColors.outlineVariant),
          const SizedBox(height: 12),
          Text(message,
              style: AppTextStyles.bodyLg
                  .copyWith(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Symbols.refresh, size: 16),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.onTertiaryContainer,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
