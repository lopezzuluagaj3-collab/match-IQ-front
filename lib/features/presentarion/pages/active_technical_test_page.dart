import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../config/router/app_routes.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../core/utils/web/camera.dart';
import '../../../core/utils/web/fullscreen.dart';
import '../../domain/entities/technical_test.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import '../bloc/proctor_cubit.dart';
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

  final Map<int, String> _mcAnswers = {};
  final Map<int, String> _codeAnswers = {};

  // Proctoring
  Timer? _frameTimer;
  bool _proctoringStarted = false;
  bool _proctoringEnded = false;
  bool _showingFullscreenWarning = false;
  late ProctorCubit _proctoringCubit;
  final CameraCapture _camera = CameraCapture();
  final FullscreenService _fullscreen = FullscreenService();

  @override
  void initState() {
    super.initState();
    _initSecurity();
    final offerId = int.tryParse(widget.offerId);
    if (offerId != null) {
      context.read<TestCubit>().previewTest(offerId);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Store cubit reference before dispose() is called, when context is still valid
    _proctoringCubit = context.read<ProctorCubit>();
  }

  Future<void> _initSecurity() async {
    if (!kIsWeb && Platform.isAndroid) {
      await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopProctoring();
    if (!kIsWeb && Platform.isAndroid) {
      FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE).catchError((_) => false);
    }
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
    // Validate before touching proctoring state — ending the session is irreversible
    if (_totalAnswered == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes responder al menos una pregunta antes de enviar el test.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
        ),
      );
      return;
    }
    if (_proctoringEnded) return;
    _proctoringEnded = true;
    _frameTimer?.cancel();
    _frameTimer = null;
    _camera.dispose();
    _fullscreen.dispose();
    // Both calls in parallel — neither depends on the other
    Future.wait([
      _proctoringCubit.isClosed ? Future.value() : _proctoringCubit.endSession(),
      context.read<TestCubit>().submitTest(session.testId, _mcAnswers, _codeAnswers),
    ]);
  }

  String get _formattedTime {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  int get _totalAnswered => _mcAnswers.length + _codeAnswers.length;

  Future<void> _handleStartTest(int offerId) async {
    if (!mounted) return;

    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _TermsDialog(),
    );

    if (accepted != true || !mounted) return;

    if (!kIsWeb) {
      final status = await Permission.camera.request();
      if (!mounted) return;

      if (status.isPermanentlyDenied) {
        _showCameraSettingsDialog();
        return;
      }
      if (status.isDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera permission denied. AI proctoring will be limited.'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }

    if (!mounted) return;
    context.read<TestCubit>().startTest(offerId);
    // startSession is deferred to when session loads — we need submissionId from the response
  }

  // ─── Proctoring ────────────────────────────────────────────────────────────

  Future<void> _startCameraCapture() async {
    await _camera.initialize();
    if (!mounted) return;
    _fullscreen.enter();
    _fullscreen.onExitFullscreen(() {
      if (mounted && !_proctoringEnded) _showFullscreenWarning();
    });
    _frameTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      final frame = _camera.captureFrame();
      if (frame != null && !_proctoringCubit.isClosed) {
        _proctoringCubit.processFrame(frame);
      }
    });
  }

  void _stopProctoring() {
    if (_proctoringEnded) return;
    _proctoringEnded = true;
    _frameTimer?.cancel();
    _frameTimer = null;
    _camera.dispose();
    _fullscreen.dispose();
    if (!_proctoringCubit.isClosed) {
      _proctoringCubit.endSession();
    }
  }

  void _showFullscreenWarning() {
    if (_showingFullscreenWarning) return;
    _showingFullscreenWarning = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.errorContainer.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Symbols.warning_amber, color: AppColors.error, size: 22),
            ),
            const SizedBox(width: 12),
            Text('¡Advertencia!',
                style: AppTextStyles.headlineMd.copyWith(fontSize: 18)),
          ],
        ),
        content: Text(
          'Has salido de pantalla completa. Salir durante el examen puede ser considerado una infracción y podría resultar en tu descalificación.',
          style: AppTextStyles.bodyMd
              .copyWith(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showingFullscreenWarning = false;
            },
            child: Text('Continuar sin pantalla completa',
                style: AppTextStyles.labelBold
                    .copyWith(color: AppColors.onSurfaceVariant)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showingFullscreenWarning = false;
              _fullscreen.enter();
            },
            icon: const Icon(Symbols.fullscreen, size: 18),
            label: const Text('Volver a pantalla completa'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  void _showProctoringAlert(String type) {
    final isDevice = type == 'device';
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.errorContainer.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isDevice ? Symbols.phone_android : Symbols.person_alert,
                color: AppColors.error,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Text('Violación detectada',
                style: AppTextStyles.headlineMd.copyWith(fontSize: 18)),
          ],
        ),
        content: Text(
          isDevice
              ? 'Se detectó un dispositivo no permitido en la cámara. Esta infracción ha sido registrada.'
              : 'Se detectó otra persona en el encuadre de la cámara. Esta infracción ha sido registrada.',
          style: AppTextStyles.bodyMd
              .copyWith(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  // ─── Camera settings fallback (native only) ────────────────────────────────

  void _showCameraSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.errorContainer.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Symbols.videocam_off, color: AppColors.error, size: 22),
            ),
            const SizedBox(width: 12),
            Text('Camera Required', style: AppTextStyles.headlineMd.copyWith(fontSize: 18)),
          ],
        ),
        content: Text(
          'Camera access has been permanently denied. Please enable it in your device settings to proceed with the AI-proctored assessment.',
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProctorCubit, ProctorState>(
      listenWhen: (prev, curr) =>
          (!prev.hasIntruder && curr.hasIntruder) ||
          (!prev.hasDevice && curr.hasDevice),
      listener: (_, ps) {
        if (ps.hasIntruder) _showProctoringAlert('intruder');
        if (ps.hasDevice) _showProctoringAlert('device');
      },
      child: BlocConsumer<TestCubit, TestState>(
      listener: (context, state) {
        if (state.session != null && _timer == null && !state.isLoading) {
          _startTimer(state.session!.timeLimitMinutes);
          if (!_proctoringStarted) {
            _proctoringStarted = true;
            final authState = context.read<AuthBloc>().state;
            if (authState is AuthAuthenticated) {
              debugPrint('[Proctoring] Starting session — user=${authState.user.id}, submission=${state.session!.submissionId}');
              _proctoringCubit.startSession(authState.user.id, state.session!.submissionId);
            } else {
              debugPrint('[Proctoring] Cannot start: authState=${authState.runtimeType}');
            }
            _startCameraCapture();
          }
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
                    onPressed: () => context.go(AppRoutes.candidateAssessments),
                    child: const Text('Back to Assessments'),
                  ),
                ],
              ),
            ),
          );
        }

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
                          Expanded(child: Text(preview.title, style: AppTextStyles.headlineMd)),
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
                      const SizedBox(height: 20),
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
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primaryContainer.withOpacity(0.2)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Symbols.videocam, size: 18, color: AppColors.primaryContainer),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'This assessment is AI-proctored via camera. Terms & conditions will be displayed before starting.',
                                style: AppTextStyles.labelSm.copyWith(color: AppColors.primaryContainer),
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
                                  ? () => _handleStartTest(offerId)
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
                    onPressed: () => context.go(AppRoutes.candidateAssessments),
                    child: const Text('Back to Assessments'),
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
            body: Center(child: Text('No questions found.', style: AppTextStyles.bodyLg)),
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
              BlocBuilder<ProctorCubit, ProctorState>(
                builder: (_, ps) {
                  if (ps.status != ProctorStatus.monitoring) {
                    return const SizedBox.shrink();
                  }
                  final looking = ps.isLooking;
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: looking ? AppColors.onTertiaryContainer : AppColors.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          looking ? 'Monitored' : 'Look at camera',
                          style: AppTextStyles.labelSm.copyWith(
                            color: looking
                                ? AppColors.tertiaryFixed
                                : AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
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
                    ...List.generate(questions.length, (i) {
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
                    }),
                    const Spacer(),
                    LinearProgressIndicator(
                      value: questions.isEmpty ? 0 : _totalAnswered / questions.length,
                      backgroundColor: AppColors.surfaceVariant,
                      color: AppColors.onTertiaryContainer,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 6),
                    Text('$_totalAnswered/${questions.length} answered',
                        style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(40),
                  child: question.isMultipleChoice
                      ? _MultipleChoiceQuestion(
                          index: _currentQuestion,
                          total: questions.length,
                          question: question,
                          selectedOption: _mcAnswers[question.id],
                          onSelect: (opt) => setState(() => _mcAnswers[question.id] = opt),
                          onPrevious: _currentQuestion > 0
                              ? () => setState(() => _currentQuestion--)
                              : null,
                          onNext: _currentQuestion < questions.length - 1
                              ? () => setState(() => _currentQuestion++)
                              : null,
                          onSubmit: state.isSubmitting ? null : () => _submit(session),
                          isLast: _currentQuestion == questions.length - 1,
                          isSubmitting: state.isSubmitting,
                          totalAnswered: _totalAnswered,
                        )
                      : _CodeChallengeQuestion(
                          key: ValueKey(question.id),
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
                          onSubmit: state.isSubmitting ? null : () => _submit(session),
                          isLast: _currentQuestion == questions.length - 1,
                          isSubmitting: state.isSubmitting,
                          totalAnswered: _totalAnswered,
                        ),
                ),
              ),
            ],
          ),
        );
      },
      ),
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
                child: const Icon(Symbols.check_circle, color: AppColors.onTertiaryContainer, size: 24),
              ),
              const SizedBox(width: 12),
              Text('Test Submitted!', style: AppTextStyles.headlineMd.copyWith(fontSize: 20)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (score != null)
                Text('Score: ${score.toStringAsFixed(1)}%',
                    style: AppTextStyles.headlineMd.copyWith(color: AppColors.onTertiaryContainer)),
              const SizedBox(height: 8),
              Text(
                state.result?.feedback ?? 'Your results will be available within 24 hours.',
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.candidateAssessments),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryContainer),
              child: const Text('Back to Assessments', style: TextStyle(color: Colors.white)),
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
    required this.totalAnswered,
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
  final int totalAnswered;

  @override
  Widget build(BuildContext context) {
    final opts = question.options ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Question ${index + 1} of $total',
            style: AppTextStyles.labelBold.copyWith(color: AppColors.secondary)),
        const SizedBox(height: 16),
        SelectionContainer.disabled(
          child: Text(question.questionText, style: AppTextStyles.bodyLg),
        ),
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
          totalAnswered: totalAnswered,
        ),
      ],
    );
  }
}

// ─── Code challenge question ──────────────────────────────────────────────────

class _CodeChallengeQuestion extends StatefulWidget {
  const _CodeChallengeQuestion({
    super.key,
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
    required this.totalAnswered,
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
  final int totalAnswered;

  @override
  State<_CodeChallengeQuestion> createState() => _CodeChallengeQuestionState();
}

class _CodeChallengeQuestionState extends State<_CodeChallengeQuestion> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.code);
  }

  @override
  void didUpdateWidget(_CodeChallengeQuestion oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync when navigating to a different question (key forces recreation, but guard anyway)
    if (oldWidget.code != widget.code && _controller.text != widget.code) {
      _controller.text = widget.code;
      _controller.selection = TextSelection.collapsed(offset: widget.code.length);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Question ${widget.index + 1} of ${widget.total}',
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
                widget.question.language?.toUpperCase() ?? 'CODE',
                style: AppTextStyles.labelSm
                    .copyWith(color: AppColors.error, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SelectionContainer.disabled(
          child: Text(widget.question.questionText, style: AppTextStyles.bodyLg),
        ),
        if (widget.question.functionSignature != null) ...[
          const SizedBox(height: 16),
          AppCard(
            child: SelectionContainer.disabled(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Function signature',
                      style: AppTextStyles.labelBold.copyWith(color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Text(widget.question.functionSignature!,
                      style: AppTextStyles.bodyMd
                          .copyWith(fontFamily: 'monospace', color: AppColors.secondary)),
                ],
              ),
            ),
          ),
        ],
        if (widget.question.exampleInput != null) ...[
          const SizedBox(height: 12),
          AppCard(
            child: SelectionContainer.disabled(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Example input',
                      style: AppTextStyles.labelBold.copyWith(color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Text(widget.question.exampleInput!,
                      style: AppTextStyles.bodyMd.copyWith(fontFamily: 'monospace')),
                ],
              ),
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
          padding: const EdgeInsets.all(4),
          child: TextField(
            controller: _controller,
            onChanged: widget.onCodeChanged,
            maxLines: 18,
            style: const TextStyle(fontFamily: 'monospace', color: Colors.white, fontSize: 13),
            cursorColor: Colors.white70,
            contextMenuBuilder: (context, editableTextState) => const SizedBox.shrink(),
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: true,
              fillColor: Color(0xFF1E1E1E),
              contentPadding: EdgeInsets.all(12),
              hintText: '// Write your solution here...',
              hintStyle: TextStyle(color: Colors.white38, fontFamily: 'monospace'),
            ),
          ),
        ),
        const SizedBox(height: 40),
        _NavRow(
          onPrevious: widget.onPrevious,
          onNext: widget.onNext,
          onSubmit: widget.onSubmit,
          isLast: widget.isLast,
          isSubmitting: widget.isSubmitting,
          totalAnswered: widget.totalAnswered,
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
    required this.totalAnswered,
  });

  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onSubmit;
  final bool isLast;
  final bool isSubmitting;
  final int totalAnswered;

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
          Tooltip(
            message: totalAnswered == 0
                ? 'Responde al menos una pregunta para enviar'
                : '',
            child: ElevatedButton.icon(
              onPressed: (isSubmitting || totalAnswered == 0) ? null : onSubmit,
              icon: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Symbols.send, size: 18),
              label: Text(isSubmitting ? 'Enviando...' : 'Enviar Test'),
              style: ElevatedButton.styleFrom(
                backgroundColor: totalAnswered == 0
                    ? AppColors.surfaceContainer
                    : AppColors.onTertiaryContainer,
                foregroundColor: totalAnswered == 0
                    ? AppColors.onSurfaceVariant
                    : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Preview row ──────────────────────────────────────────────────────────────

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
            color: isSelected ? AppColors.onTertiaryContainer : AppColors.outlineVariant,
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
                color: isSelected ? AppColors.onTertiaryContainer : AppColors.surfaceContainer,
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
            Expanded(
              child: SelectionContainer.disabled(child: Text(text, style: AppTextStyles.bodyMd)),
            ),
            if (isSelected)
              const Icon(Symbols.check_circle, color: AppColors.onTertiaryContainer, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Terms & Conditions dialog ────────────────────────────────────────────────

class _TermsDialog extends StatefulWidget {
  const _TermsDialog();

  @override
  State<_TermsDialog> createState() => _TermsDialogState();
}

class _TermsDialogState extends State<_TermsDialog> {
  bool _accepted = false;
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Symbols.security, color: AppColors.primaryContainer, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Terms & Conditions',
                    style: AppTextStyles.headlineMd.copyWith(fontSize: 18)),
                const SizedBox(height: 2),
                Text('Read carefully before starting the assessment',
                    style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 540,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            Container(
              height: 340,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  child: const _TermsContent(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => setState(() => _accepted = !_accepted),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Checkbox(
                      value: _accepted,
                      onChanged: (v) => setState(() => _accepted = v ?? false),
                      activeColor: AppColors.primaryContainer,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'I have read and agree to the terms and conditions above',
                        style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context, false),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.outlineVariant),
            foregroundColor: AppColors.onSurface,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Decline'),
        ),
        ElevatedButton.icon(
          onPressed: _accepted ? () => Navigator.pop(context, true) : null,
          icon: const Icon(Symbols.check, size: 18),
          label: const Text('Accept & Continue'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryContainer,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.surfaceContainer,
            disabledForegroundColor: AppColors.onSurfaceVariant,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}

// ─── Terms content ────────────────────────────────────────────────────────────

class _TermsContent extends StatelessWidget {
  const _TermsContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TermsSection(
          icon: Symbols.videocam,
          iconColor: AppColors.primaryContainer,
          title: '1. Camera Monitoring',
          body:
              'Your camera will remain active throughout the entire assessment. By proceeding, '
              'you consent to real-time video analysis performed by our AI proctoring system.',
        ),
        const SizedBox(height: 20),
        _TermsSection(
          icon: Symbols.smart_toy,
          iconColor: AppColors.onTertiaryContainer,
          title: '2. AI Fraud Detection',
          body: 'Our AI will continuously monitor the video feed to detect:',
          bullets: const [
            'Picking up or consulting a mobile phone or any other device',
            'The presence of additional people visible in the camera frame',
            'Suspicious head movements, gaze patterns, or prolonged eyes-off-screen',
            'Any behavior that may indicate external assistance during the test',
          ],
        ),
        const SizedBox(height: 20),
        _TermsSection(
          icon: Symbols.screen_lock_portrait,
          iconColor: AppColors.secondary,
          title: '3. Screen Security',
          body: 'To maintain assessment integrity:',
          bullets: const [
            'Screen recording and screenshots are blocked on mobile devices',
            'Copying text from assessment questions is disabled',
            'Navigating away from the test window may be flagged as a violation',
          ],
        ),
        const SizedBox(height: 20),
        _TermsSection(
          icon: Symbols.warning_amber,
          iconColor: AppColors.error,
          title: '4. Violations & Consequences',
          body:
              'Any detected violation will be automatically flagged and reported to the recruiting '
              'team. Multiple violations may result in immediate test termination and disqualification '
              'from the selection process.',
        ),
        const SizedBox(height: 20),
        _TermsSection(
          icon: Symbols.policy,
          iconColor: AppColors.onSurfaceVariant,
          title: '5. Data Privacy',
          body:
              'Video data is processed in real time and is not permanently stored on our servers. '
              'Incident reports contain only behavioral analysis summaries, not raw video recordings. '
              'All data is handled in accordance with applicable privacy regulations.',
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer.withOpacity(0.07),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primaryContainer.withOpacity(0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Symbols.info, size: 16, color: AppColors.primaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'By clicking "Accept & Continue" you confirm that you have read, understood, and '
                  'agreed to all terms above, and that you consent to camera-based AI monitoring '
                  'for the duration of this assessment.',
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.primaryContainer,
                    height: 1.55,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TermsSection extends StatelessWidget {
  const _TermsSection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    this.bullets,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final List<String>? bullets;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 17, color: iconColor),
            const SizedBox(width: 8),
            Text(title,
                style: AppTextStyles.labelBold.copyWith(fontSize: 13.5, color: AppColors.onSurface)),
          ],
        ),
        const SizedBox(height: 6),
        Text(body,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 13,
              height: 1.55,
            )),
        if (bullets != null) ...[
          const SizedBox(height: 6),
          ...bullets!.map(
            (b) => Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ',
                      style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant, fontSize: 13)),
                  Expanded(
                    child: Text(b,
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 13,
                          height: 1.45,
                        )),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
