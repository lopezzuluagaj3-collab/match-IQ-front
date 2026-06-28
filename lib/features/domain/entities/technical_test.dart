import 'package:equatable/equatable.dart';

enum TestStatus { pending, inProgress, completed, expired }

class TechnicalTest extends Equatable {
  const TechnicalTest({
    required this.id,
    required this.title,
    required this.durationMinutes,
    required this.dueDate,
    required this.status,
    required this.iconType,
    this.score,
    this.companyName,
    this.offerId,
  });

  final String id;
  final String title;
  final int durationMinutes;
  final DateTime dueDate;
  final TestStatus status;
  final String iconType;
  final int? score;
  final String? companyName;
  final int? offerId;

  String get daysUntilDue {
    final diff = dueDate.difference(DateTime.now()).inDays;
    if (diff < 0) return 'Expired';
    if (diff == 0) return 'Due today';
    return 'Due in $diff day${diff == 1 ? '' : 's'}';
  }

  @override
  List<Object?> get props => [id];
}

// ─── Active test session entities ────────────────────────────────────────────

class TestQuestion extends Equatable {
  const TestQuestion({
    required this.id,
    required this.orderIndex,
    required this.questionType,
    required this.questionText,
    this.options,
    this.language,
    this.functionSignature,
    this.exampleInput,
    this.expectedBehavior,
    this.correctAnswer,
    this.explanation,
    this.isGorilla = false,
    this.gorillaHint,
  });

  final int id;
  final int orderIndex;
  final String questionType; // 'MultipleChoice' | 'CodeChallenge'
  final String questionText;
  final Map<String, String>? options; // {'A': '...', 'B': '...', ...}
  final String? language;
  final String? functionSignature;
  final String? exampleInput;
  final String? expectedBehavior;
  final String? correctAnswer; // e.g. "B"
  final String? explanation;   // only visible to company
  final bool isGorilla;
  final String? gorillaHint;

  bool get isMultipleChoice => questionType == 'MultipleChoice';

  @override
  List<Object?> get props => [id];
}

class TestSession extends Equatable {
  const TestSession({
    required this.testId,
    required this.offerId,
    required this.title,
    required this.timeLimitMinutes,
    required this.questions,
    this.submissionId = 0,
  });

  final int testId;
  /// ID de la submission devuelto por /candidate/start — requerido para proctoring.
  /// Es 0 cuando el TestSession fue creado desde el lado empresa (generate/regenerate).
  final int submissionId;
  final int offerId;
  final String title;
  final int timeLimitMinutes;
  final List<TestQuestion> questions;

  @override
  List<Object?> get props => [testId];
}

class AnswerItem extends Equatable {
  const AnswerItem({
    required this.questionId,
    this.selectedOption,
    this.codeSubmitted,
  });

  final int questionId;
  final String? selectedOption; // 'A', 'B', 'C' or 'D'
  final String? codeSubmitted;

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        if (selectedOption != null) 'selectedOption': selectedOption,
        if (codeSubmitted != null) 'codeSubmitted': codeSubmitted,
      };

  @override
  List<Object?> get props => [questionId];
}

class TestPreview extends Equatable {
  const TestPreview({
    required this.testId,
    required this.title,
    required this.timeLimitMinutes,
    required this.totalQuestions,
    required this.multipleChoiceCount,
    required this.codeChallengeCount,
  });

  final int testId;
  final String title;
  final int timeLimitMinutes;
  final int totalQuestions;
  final int multipleChoiceCount;
  final int codeChallengeCount;

  @override
  List<Object?> get props => [testId];
}

class TestResult extends Equatable {
  const TestResult({
    this.score,
    this.feedback,
    required this.status,
    this.submittedAt,
  });

  final double? score;
  final String? feedback;
  final String status;
  final DateTime? submittedAt;

  @override
  List<Object?> get props => [status, score];
}

// ─── Match test submission (company view) ────────────────────────────────────

class SubmissionQuestion extends Equatable {
  const SubmissionQuestion({
    required this.id,
    required this.orderIndex,
    required this.questionType,
    required this.questionText,
    this.options,
    this.functionSignature,
    this.expectedBehavior,
    this.correctAnswer,
    this.selectedOption,
    this.codeSubmitted,
    this.isCorrect,
    this.aiFeedback,
  });

  final int id;
  final int orderIndex;
  final String questionType;
  final String questionText;
  final Map<String, String>? options;
  final String? functionSignature;
  final String? expectedBehavior;
  final String? correctAnswer;
  final String? selectedOption;
  final String? codeSubmitted;
  final bool? isCorrect;
  final String? aiFeedback;

  bool get isMultipleChoice => questionType == 'MultipleChoice';

  @override
  List<Object?> get props => [id];
}

class MatchTestSubmission extends Equatable {
  const MatchTestSubmission({
    required this.matchId,
    required this.candidateName,
    required this.status,
    required this.questions,
    this.score,
    this.globalFeedback,
    this.submittedAt,
    this.aiEvaluatedAt,
  });

  final int matchId;
  final String candidateName;
  final String status;
  final List<SubmissionQuestion> questions;
  final double? score;
  final String? globalFeedback;
  final DateTime? submittedAt;
  final DateTime? aiEvaluatedAt;

  int get totalQuestions => questions.length;
  int get correctAnswers => questions.where((q) => q.isCorrect == true).length;
  bool get isPending => status == 'Pending' || status == 'Failed';

  @override
  List<Object?> get props => [matchId];
}

// ─── Proctoring report (company view, after candidate completes test) ────────

class ProctoringEvent extends Equatable {
  const ProctoringEvent({
    required this.tipo,
    required this.timestamp,
    this.detalle,
    this.evidencia,
  });

  final String tipo;
  final String? detalle;
  final String? evidencia;
  final DateTime timestamp;

  @override
  List<Object?> get props => [tipo, timestamp];
}

class ProctoringReport extends Equatable {
  const ProctoringReport({
    required this.sessionId,
    required this.inicio,
    required this.fin,
    required this.totalFramesProcesados,
    required this.totalEventos,
    required this.integrityScore,
    required this.eventos,
    this.integritySummary,
  });

  final String sessionId;
  final DateTime inicio;
  final DateTime fin;
  final int totalFramesProcesados;
  final int totalEventos;

  /// 0–100. Calculated on first company fetch and cached. Color: ≥80 green, 50–79 yellow, <50 red.
  final double integrityScore;

  /// AI-generated Spanish paragraph summarizing incidents. Null until first fetch.
  final String? integritySummary;
  final List<ProctoringEvent> eventos;

  @override
  List<Object?> get props => [sessionId];
}

// ─── Chat result (company editing questions via AI) ───────────────────────────

class ChatResult extends Equatable {
  const ChatResult({
    required this.updatedQuestion,
    required this.assistantMessage,
  });

  final TestQuestion updatedQuestion;
  final String assistantMessage;

  @override
  List<Object?> get props => [updatedQuestion, assistantMessage];
}
