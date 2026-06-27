import 'dart:async';
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

class ActiveTechnicalTestPage extends StatefulWidget {
  const ActiveTechnicalTestPage({super.key, required this.offerId});
  final String offerId;

  @override
  State<ActiveTechnicalTestPage> createState() => _ActiveTechnicalTestPageState();
}

class _ActiveTechnicalTestPageState extends State<ActiveTechnicalTestPage> {
  int _currentQuestion = 0;
  int _remainingSeconds = 60 * 60;
  Timer? _timer;

  // questionId → selectedOption (A/B/C/D) for MC
  final Map<int, String> _mcAnswers = {};
  // questionId → code text for code challenges
  final Map<int, String> _codeAnswers = {};

  @override
  void initState() {
    super.initState();
    final offerId = int.tryParse(widget.offerId);
    if (offerId != null) {
      context.read<TestCubit>().previewTest(offerId);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer(int timeLimitMinutes) {
    _remainingSeconds = timeLimitMinutes * 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _timer?.cancel();
        _submit(context.read<TestCubit>().state.session!);
      }
    });
  }

  void _submit(TestSession session) {
    context.read<TestCubit>().submitTest(
      session.testId,
      _mcAnswers,
      _codeAnswers,
    );
  }

  String get _formattedTime {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  int get _totalAnswered => _mcAnswers.length + _codeAnswers.length;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TestCubit, TestState>(
      listener: (context, state) {
        if (state.session != null && _timer == null && !state.isLoading) {
          _startTimer(state.session!.timeLimitMinutes);
        }
        if (state.isSubmitted) {
          _timer?.cancel();
          _showResultDialog(context, state);
        }
        if (state.error != null && !state.isSubmitting) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!), backgroundColor: AppColors.error),
          );
        }
      },
      builder: (context, state) {
        if (state.isLoadingPreview) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator(color: AppColors.onTertiaryContainer)),
          );
        }

        if (state.error != null && state.preview == null && state.session == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Symbols.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(state.error!, style: AppTextStyles.bodyLg, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go(AppRoutes.candidateDashboard),
                    child: const Text('Back to Dashboard'),
                  ),
                ],
              ),
            ),
          );
        }

        // Show preview screen until user confirms
        if (state.preview != null && state.session == null && !state.isLoading) {
          final preview = state.preview!;
          final offerId = int.tryParse(widget.offerId);
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              title: const Text('Assessment Preview'),
              leading: IconButton(
                icon: const Icon(Symbols.arrow_back),
                onPressed: () => context.go(AppRoutes.candidateAssessments),
              ),
            ),
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: AppCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Symbols.assignment, color: AppColors.primaryContainer, size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(preview.title, style: AppTextStyles.headlineMd),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      _PreviewRow(icon: Symbols.timer, label: 'Time limit', value: '${preview.timeLimitMinutes} minutes'),
                      const SizedBox(height: 12),
                      _PreviewRow(icon: Symbols.quiz, label: 'Total questions', value: '${preview.totalQuestions}'),
                      const SizedBox(height: 12),
                      _PreviewRow(icon: Symbols.check_box, label: 'Multiple choice', value: '${preview.multipleChoiceCount} questions'),
                      const SizedBox(height: 12),
                      _PreviewRow(icon: Symbols.code, label: 'Code challenges', value: '${preview.codeChallengeCount} questions'),
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.errorContainer.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.error.withOpacity(0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Symbols.warning, size: 18, color: AppColors.error),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Once you start, the timer begins and cannot be paused. Make sure you have ${preview.timeLimitMinutes} minutes available.',
                                style: AppTextStyles.labelSm.copyWith(color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => context.go(AppRoutes.candidateAssessments),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: AppColors.outlineVariant),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: offerId != null
                                  ? () => context.read<TestCubit>().startTest(offerId)
                                  : null,
                              icon: const Icon(Symbols.play_arrow, size: 20),
                              label: const Text('Start Test'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryContainer,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        if (state.isLoading) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator(color: AppColors.onTertiaryContainer)),
          );
        }

        if (state.error != null && state.session == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Symbols.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(state.error!, style: AppTextStyles.bodyLg, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go(AppRoutes.candidateDashboard),
                    child: const Text('Back to Dashboard'),
                  ),
                ],
              ),
            ),
          );
        }

        final session = state.session;
        if (session == null) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator(color: AppColors.onTertiaryContainer)),
          );
        }

        final questions = session.questions;
        if (questions.isEmpty) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Text('No questions found.', style: AppTextStyles.bodyLg),
            ),
          );
        }

        final question = questions[_currentQuestion];
        final isLate = _remainingSeconds < 300;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            title: Text(session.title),
            centerTitle: false,
            actions: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isLate
                      ? AppColors.errorContainer
                      : AppColors.onTertiaryContainer.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    Icon(Symbols.timer,
                        size: 16,
                        color: isLate ? AppColors.error : AppColors.tertiaryFixed),
                    const SizedBox(width: 6),
                    Text(
                      _formattedTime,
                      style: AppTextStyles.labelBold.copyWith(
                          color: isLate ? AppColors.error : AppColors.tertiaryFixed),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Question navigator sidebar
              Container(
                width: 200,
                height: double.infinity,
                color: AppColors.surfaceContainerLow,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Questions', style: AppTextStyles.labelBold),
                    const SizedBox(height: 16),
                    ...List.generate(
                      questions.length,
                      (i) {
                        final q = questions[i];
                        final answered = _mcAnswers.containsKey(q.id) ||
                            (_codeAnswers[q.id]?.isNotEmpty ?? false);
                        return GestureDetector(
                          onTap: () => setState(() => _currentQuestion = i),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: i == _currentQuestion
                                  ? AppColors.primaryContainer
                                  : answered
                                      ? AppColors.onTertiaryContainer.withOpacity(0.1)
                                      : AppColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: i == _currentQuestion
                                    ? AppColors.primaryContainer
                                    : AppColors.outlineVariant,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text('Q${i + 1}',
                                    style: AppTextStyles.labelBold.copyWith(
                                        color: i == _currentQuestion
                                            ? Colors.white
                                            : AppColors.onSurface)),
                                const Spacer(),
                                if (answered)
                                  const Icon(Symbols.check_circle,
                                      size: 14, color: AppColors.onTertiaryContainer),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const Spacer(),
                    LinearProgressIndicator(
                      value: questions.isEmpty
                          ? 0
                          : _totalAnswered / questions.length,
                      backgroundColor: AppColors.surfaceVariant,
                      color: AppColors.onTertiaryContainer,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 6),
                    Text('$_totalAnswered/${questions.length} answered',
                        style: AppTextStyles.labelSm
                            .copyWith(color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
              // Question content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(40),
                  child: question.isMultipleChoice
                      ? _MultipleChoiceQuestion(
                          index: _currentQuestion,
                          total: questions.length,
                          question: question,
                          selectedOption: _mcAnswers[question.id],
                          onSelect: (opt) =>
                              setState(() => _mcAnswers[question.id] = opt),
                          onPrevious: _currentQuestion > 0
                              ? () => setState(() => _currentQuestion--)
                              : null,
                          onNext: _currentQuestion < questions.length - 1
                              ? () => setState(() => _currentQuestion++)
                              : null,
                          onSubmit: state.isSubmitting
                              ? null
                              : () => _submit(session),
                          isLast: _currentQuestion == questions.length - 1,
                          isSubmitting: state.isSubmitting,
                        )
                      : _CodeChallengeQuestion(
                          index: _currentQuestion,
                          total: questions.length,
                          question: question,
                          code: _codeAnswers[question.id] ?? '',
                          onCodeChanged: (code) =>
                              setState(() => _codeAnswers[question.id] = code),
                          onPrevious: _currentQuestion > 0
                              ? () => setState(() => _currentQuestion--)
                              : null,
                          onNext: _currentQuestion < questions.length - 1
                              ? () => setState(() => _currentQuestion++)
                              : null,
                          onSubmit: state.isSubmitting
                              ? null
                              : () => _submit(session),
                          isLast: _currentQuestion == questions.length - 1,
                          isSubmitting: state.isSubmitting,
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showResultDialog(BuildContext context, TestState state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        final score = state.result?.score;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.onTertiaryContainer.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Symbols.check_circle,
                    color: AppColors.onTertiaryContainer, size: 24),
              ),
              const SizedBox(width: 12),
              Text('Test Submitted!',
                  style: AppTextStyles.headlineMd.copyWith(fontSize: 20)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (score != null)
                Text('Score: ${score.toStringAsFixed(1)}%',
                    style: AppTextStyles.headlineMd
                        .copyWith(color: AppColors.onTertiaryContainer)),
              const SizedBox(height: 8),
              Text(
                state.result?.feedback ??
                    'Your results will be available within 24 hours.',
                style: AppTextStyles.bodyMd
                    .copyWith(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.candidateDashboard),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer),
              child: const Text('Back to Dashboard',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}

// ─── Multiple choice question ─────────────────────────────────────────────────

class _MultipleChoiceQuestion extends StatelessWidget {
  const _MultipleChoiceQuestion({
    required this.index,
    required this.total,
    required this.question,
    required this.selectedOption,
    required this.onSelect,
    required this.onPrevious,
    required this.onNext,
    required this.onSubmit,
    required this.isLast,
    required this.isSubmitting,
  });

  final int index;
  final int total;
  final TestQuestion question;
  final String? selectedOption;
  final ValueChanged<String> onSelect;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onSubmit;
  final bool isLast;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    final opts = question.options ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Question ${index + 1} of $total',
            style: AppTextStyles.labelBold.copyWith(color: AppColors.secondary)),
        const SizedBox(height: 16),
        Text(question.questionText, style: AppTextStyles.bodyLg),
        const SizedBox(height: 32),
        ...opts.entries.map(
          (e) => _OptionCard(
            label: e.key,
            text: e.value,
            isSelected: selectedOption == e.key,
            onTap: () => onSelect(e.key),
          ),
        ),
        const SizedBox(height: 40),
        _NavRow(
          onPrevious: onPrevious,
          onNext: onNext,
          onSubmit: onSubmit,
          isLast: isLast,
          isSubmitting: isSubmitting,
        ),
      ],
    );
  }
}

// ─── Code challenge question ──────────────────────────────────────────────────

class _CodeChallengeQuestion extends StatelessWidget {
  const _CodeChallengeQuestion({
    required this.index,
    required this.total,
    required this.question,
    required this.code,
    required this.onCodeChanged,
    required this.onPrevious,
    required this.onNext,
    required this.onSubmit,
    required this.isLast,
    required this.isSubmitting,
  });

  final int index;
  final int total;
  final TestQuestion question;
  final String code;
  final ValueChanged<String> onCodeChanged;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onSubmit;
  final bool isLast;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Question ${index + 1} of $total',
            style: AppTextStyles.labelBold.copyWith(color: AppColors.secondary)),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.errorContainer.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                question.language?.toUpperCase() ?? 'CODE',
                style: AppTextStyles.labelSm
                    .copyWith(color: AppColors.error, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(question.questionText, style: AppTextStyles.bodyLg),
        if (question.functionSignature != null) ...[
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Function signature',
                    style:
                        AppTextStyles.labelBold.copyWith(color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 8),
                Text(question.functionSignature!,
                    style: AppTextStyles.bodyMd.copyWith(
                        fontFamily: 'monospace', color: AppColors.secondary)),
              ],
            ),
          ),
        ],
        if (question.exampleInput != null) ...[
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Example input',
                    style:
                        AppTextStyles.labelBold.copyWith(color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 8),
                Text(question.exampleInput!,
                    style: AppTextStyles.bodyMd.copyWith(fontFamily: 'monospace')),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        Text('Your solution', style: AppTextStyles.labelBold),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: TextEditingController(text: code)
              ..selection = TextSelection.collapsed(offset: code.length),
            onChanged: onCodeChanged,
            maxLines: 18,
            style: const TextStyle(
                fontFamily: 'monospace', color: Colors.white, fontSize: 13),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: '// Write your solution here...',
              hintStyle: TextStyle(color: Colors.white38, fontFamily: 'monospace'),
            ),
          ),
        ),
        const SizedBox(height: 40),
        _NavRow(
          onPrevious: onPrevious,
          onNext: onNext,
          onSubmit: onSubmit,
          isLast: isLast,
          isSubmitting: isSubmitting,
        ),
      ],
    );
  }
}

// ─── Navigation row ───────────────────────────────────────────────────────────

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.onPrevious,
    required this.onNext,
    required this.onSubmit,
    required this.isLast,
    required this.isSubmitting,
  });

  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onSubmit;
  final bool isLast;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (onPrevious != null)
          OutlinedButton.icon(
            onPressed: onPrevious,
            icon: const Icon(Symbols.arrow_back, size: 18),
            label: const Text('Previous'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.outlineVariant),
              foregroundColor: AppColors.onSurface,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          )
        else
          const SizedBox(),
        if (!isLast)
          ElevatedButton.icon(
            onPressed: onNext,
            icon: const Icon(Symbols.arrow_forward, size: 18),
            label: const Text('Next Question'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          )
        else
          ElevatedButton.icon(
            onPressed: isSubmitting ? null : onSubmit,
            icon: isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Symbols.send, size: 18),
            label: Text(isSubmitting ? 'Submitting...' : 'Submit Test'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.onTertiaryContainer,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
      ],
    );
  }
}

// ─── Preview row ─────────────────────────────────────────────────────────────

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.secondary),
        const SizedBox(width: 10),
        Text(label, style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
        const Spacer(),
        Text(value, style: AppTextStyles.labelBold),
      ],
    );
  }
}

// ─── Option card ──────────────────────────────────────────────────────────────

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.label,
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.onTertiaryContainer.withOpacity(0.08)
              : AppColors.surfaceContainerLowest,
          border: Border.all(
            color: isSelected
                ? AppColors.onTertiaryContainer
                : AppColors.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.onTertiaryContainer
                    : AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  label,
                  style: AppTextStyles.labelBold.copyWith(
                      color: isSelected ? Colors.white : AppColors.onSurface),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(text, style: AppTextStyles.bodyMd)),
            if (isSelected)
              const Icon(Symbols.check_circle,
                  color: AppColors.onTertiaryContainer, size: 20),
          ],
        ),
      ),
    );
  }
}
