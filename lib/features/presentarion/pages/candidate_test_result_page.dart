import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../config/router/app_routes.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../domain/entities/technical_test.dart';
import '../bloc/test_cubit.dart';
import '../widgets/shared/app_card.dart';

class CandidateTestResultPage extends StatefulWidget {
  const CandidateTestResultPage({super.key, required this.testId});
  final String testId;

  @override
  State<CandidateTestResultPage> createState() => _CandidateTestResultPageState();
}

class _CandidateTestResultPageState extends State<CandidateTestResultPage> {
  @override
  void initState() {
    super.initState();
    final id = int.tryParse(widget.testId);
    if (id != null) context.read<TestCubit>().fetchResult(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        title: const Text('Test Result'),
        leading: IconButton(
          icon: const Icon(Symbols.arrow_back),
          onPressed: () => context.go(AppRoutes.candidateAssessments),
        ),
      ),
      body: BlocBuilder<TestCubit, TestState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.onTertiaryContainer),
            );
          }

          if (state.error != null && state.result == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Symbols.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(state.error!, style: AppTextStyles.bodyLg, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      final id = int.tryParse(widget.testId);
                      if (id != null) context.read<TestCubit>().fetchResult(id);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final result = state.result;
          if (result == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.onTertiaryContainer),
            );
          }

          return _ResultBody(result: result);
        },
      ),
    );
  }
}

class _ResultBody extends StatelessWidget {
  const _ResultBody({required this.result});
  final TestResult result;

  @override
  Widget build(BuildContext context) {
    final score = result.score;
    final isPending = result.status == 'Pending' || result.status == 'Submitted';
    final scoreColor = score == null
        ? AppColors.secondary
        : score >= 80
            ? AppColors.onTertiaryContainer
            : score >= 50
                ? AppColors.secondary
                : AppColors.error;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              AppCard(
                radius: 24,
                child: Column(
                  children: [
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isPending
                            ? AppColors.secondaryContainer.withOpacity(0.2)
                            : AppColors.onTertiaryContainer.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPending ? Symbols.hourglass_top : Symbols.check_circle,
                            size: 14,
                            color: isPending ? AppColors.secondary : AppColors.onTertiaryContainer,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isPending ? 'Evaluation in progress' : 'Evaluated',
                            style: AppTextStyles.labelSm.copyWith(
                              color: isPending ? AppColors.secondary : AppColors.onTertiaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Score circle
                    if (score != null) ...[
                      SizedBox(
                        width: 140,
                        height: 140,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox.expand(
                              child: CircularProgressIndicator(
                                value: score / 100,
                                strokeWidth: 10,
                                backgroundColor: AppColors.surfaceVariant,
                                color: scoreColor,
                                strokeCap: StrokeCap.round,
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${score.toStringAsFixed(1)}%',
                                  style: AppTextStyles.headlineLg.copyWith(
                                    color: scoreColor,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  'Score',
                                  style: AppTextStyles.labelSm.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                    ] else if (isPending) ...[
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Symbols.hourglass_top,
                          size: 48,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],
                    // Feedback
                    if (result.feedback != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.outlineVariant),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Symbols.smart_toy, size: 16, color: AppColors.onTertiaryContainer),
                                const SizedBox(width: 8),
                                Text(
                                  'AI Feedback',
                                  style: AppTextStyles.labelBold.copyWith(
                                    color: AppColors.onTertiaryContainer,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              result.feedback!,
                              style: AppTextStyles.bodyMd.copyWith(
                                color: AppColors.onSurfaceVariant,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Submitted at
                    if (result.submittedAt != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Symbols.schedule, size: 14, color: AppColors.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Text(
                            'Submitted ${_formatDate(result.submittedAt!)}',
                            style: AppTextStyles.labelSm.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Pending notice
                    if (isPending) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Symbols.info, size: 16, color: AppColors.secondary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Your test is being evaluated by our AI. Results will be available within 24 hours.',
                                style: AppTextStyles.labelSm.copyWith(
                                  color: AppColors.secondary,
                                  height: 1.55,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.go(AppRoutes.candidateAssessments),
                  icon: const Icon(Symbols.arrow_back, size: 18),
                  label: const Text('Back to Assessments'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.outlineVariant),
                    foregroundColor: AppColors.onSurface,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
