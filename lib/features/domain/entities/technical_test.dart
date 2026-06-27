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
  });

  final int testId;
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
