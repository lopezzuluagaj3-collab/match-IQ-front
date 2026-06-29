import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/technical_test.dart';
import '../../infrastructure/datasources/app_datasource.dart';

class TestState extends Equatable {
  const TestState({
    this.preview,
    this.session,
    this.result,
    this.isLoadingPreview = false,
    this.isLoading = false,
    this.isSubmitting = false,
    this.isSubmitted = false,
    this.error,
  });

  final TestPreview? preview;
  final TestSession? session;
  final TestResult? result;
  final bool isLoadingPreview;
  final bool isLoading;
  final bool isSubmitting;
  final bool isSubmitted;
  final String? error;

  TestState copyWith({
    TestPreview? preview,
    TestSession? session,
    TestResult? result,
    bool? isLoadingPreview,
    bool? isLoading,
    bool? isSubmitting,
    bool? isSubmitted,
    String? error,
  }) =>
      TestState(
        preview: preview ?? this.preview,
        session: session ?? this.session,
        result: result ?? this.result,
        isLoadingPreview: isLoadingPreview ?? this.isLoadingPreview,
        isLoading: isLoading ?? this.isLoading,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        isSubmitted: isSubmitted ?? this.isSubmitted,
        error: error,
      );

  @override
  List<Object?> get props =>
      [preview, session, result, isLoadingPreview, isLoading, isSubmitting, isSubmitted, error];
}

class TestCubit extends Cubit<TestState> {
  TestCubit(this._datasource) : super(const TestState());

  final AppDatasource _datasource;

  Future<void> previewTest(int offerId) async {
    emit(state.copyWith(isLoadingPreview: true));
    final result = await _datasource.getTestPreview(offerId);
    result.fold(
      (f) => emit(state.copyWith(isLoadingPreview: false, error: f.message)),
      (preview) => emit(state.copyWith(isLoadingPreview: false, preview: preview)),
    );
  }

  Future<void> startTest(int offerId) async {
    emit(state.copyWith(isLoading: true));
    final result = await _datasource.startCandidateTest(offerId);
    result.fold(
      (f) => emit(state.copyWith(isLoading: false, error: f.message)),
      (session) => emit(state.copyWith(isLoading: false, session: session)),
    );
  }

  Future<void> fetchResult(int testId) async {
    emit(state.copyWith(isLoading: true));
    final result = await _datasource.getTestResult(testId);
    result.fold(
      (f) => emit(state.copyWith(isLoading: false, error: f.message)),
      (testResult) => emit(state.copyWith(isLoading: false, result: testResult)),
    );
  }

  Future<void> submitTest(int testId, Map<int, String> mcAnswers, Map<int, String> codeAnswers) async {
    emit(state.copyWith(isSubmitting: true));
    final answers = [
      ...mcAnswers.entries.map((e) => AnswerItem(questionId: e.key, selectedOption: e.value)),
      ...codeAnswers.entries.map((e) => AnswerItem(questionId: e.key, codeSubmitted: e.value)),
    ];
    final result = await _datasource.submitCandidateTest(testId, answers);
    result.fold(
      (f) => emit(state.copyWith(isSubmitting: false, error: f.message)),
      (testResult) => emit(state.copyWith(
        isSubmitting: false,
        isSubmitted: true,
        result: testResult,
      )),
    );
  }
}
