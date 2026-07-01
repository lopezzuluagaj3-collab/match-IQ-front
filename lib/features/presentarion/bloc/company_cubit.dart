import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/web/download_helper.dart';
import '../../domain/entities/catalog.dart';
import '../../domain/entities/company.dart';
import '../../domain/entities/company_dashboard_stats.dart';
import '../../domain/entities/job_offer.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/technical_test.dart';
import '../../infrastructure/datasources/app_datasource.dart';

class CompanyState extends Equatable {
  const CompanyState({
    this.dashboard,
    this.profile,
    this.matches = const [],
    this.offers = const [],
    this.tiers = const [],
    this.categories = const [],
    this.availableSkills = const [],
    this.aiParseResult,
    this.createdOffer,
    this.checkoutUrl,
    this.offerActivated = false,
    this.sessionActivated,
    this.selectedOfferId,
    this.testSession,
    this.testSubmission,
    this.lastChatMessage,
    this.isLoading = false,
    this.isLoadingMatches = false,
    this.isLoadingSubmission = false,
    this.isLoadingProctoring = false,
    this.isDownloadingReport = false,
    this.isSaving = false,
    this.isParsing = false,
    this.proctoringReport,
    this.isActingOnMatchId,
    this.error,
  });

  final CompanyDashboardStats? dashboard;
  final CompanyProfile? profile;
  final List<CandidateMatch> matches;
  final List<JobOffer> offers;
  final List<OfferTier> tiers;
  final List<Category> categories;
  final List<CatalogSkill> availableSkills;
  final AiParseResult? aiParseResult;
  final JobOffer? createdOffer;
  final String? checkoutUrl;
  final bool offerActivated;
  final bool? sessionActivated;
  final int? selectedOfferId;
  final TestSession? testSession;
  final MatchTestSubmission? testSubmission;
  final String? lastChatMessage;
  final bool isLoading;
  final bool isLoadingMatches;
  final bool isLoadingSubmission;
  final bool isLoadingProctoring;
  final bool isDownloadingReport;
  final bool isSaving;
  final bool isParsing;
  final ProctoringReport? proctoringReport;
  final int? isActingOnMatchId;
  final String? error;

  CompanyState copyWith({
    CompanyDashboardStats? dashboard,
    CompanyProfile? profile,
    List<CandidateMatch>? matches,
    List<JobOffer>? offers,
    List<OfferTier>? tiers,
    List<Category>? categories,
    List<CatalogSkill>? availableSkills,
    AiParseResult? aiParseResult,
    bool clearAiParseResult = false,
    JobOffer? createdOffer,
    bool clearCreatedOffer = false,
    String? checkoutUrl,
    bool clearCheckoutUrl = false,
    bool? offerActivated,
    bool? sessionActivated,
    bool clearSessionActivated = false,
    int? selectedOfferId,
    TestSession? testSession,
    bool clearTestSession = false,
    MatchTestSubmission? testSubmission,
    bool clearTestSubmission = false,
    String? lastChatMessage,
    bool clearLastChatMessage = false,
    bool? isLoading,
    bool? isLoadingMatches,
    bool? isLoadingSubmission,
    bool? isLoadingProctoring,
    bool? isDownloadingReport,
    bool? isSaving,
    bool? isParsing,
    ProctoringReport? proctoringReport,
    bool clearProctoringReport = false,
    int? isActingOnMatchId,
    bool clearActingMatchId = false,
    String? error,
    bool clearError = false,
  }) =>
      CompanyState(
        dashboard: dashboard ?? this.dashboard,
        profile: profile ?? this.profile,
        matches: matches ?? this.matches,
        offers: offers ?? this.offers,
        tiers: tiers ?? this.tiers,
        categories: categories ?? this.categories,
        availableSkills: availableSkills ?? this.availableSkills,
        aiParseResult: clearAiParseResult ? null : (aiParseResult ?? this.aiParseResult),
        createdOffer: clearCreatedOffer ? null : (createdOffer ?? this.createdOffer),
        checkoutUrl: clearCheckoutUrl ? null : (checkoutUrl ?? this.checkoutUrl),
        offerActivated: offerActivated ?? this.offerActivated,
        sessionActivated: clearSessionActivated ? null : (sessionActivated ?? this.sessionActivated),
        selectedOfferId: selectedOfferId ?? this.selectedOfferId,
        testSession: clearTestSession ? null : (testSession ?? this.testSession),
        testSubmission: clearTestSubmission ? null : (testSubmission ?? this.testSubmission),
        lastChatMessage: clearLastChatMessage ? null : (lastChatMessage ?? this.lastChatMessage),
        isLoading: isLoading ?? this.isLoading,
        isLoadingMatches: isLoadingMatches ?? this.isLoadingMatches,
        isLoadingSubmission: isLoadingSubmission ?? this.isLoadingSubmission,
        isLoadingProctoring: isLoadingProctoring ?? this.isLoadingProctoring,
        isDownloadingReport: isDownloadingReport ?? this.isDownloadingReport,
        isSaving: isSaving ?? this.isSaving,
        isParsing: isParsing ?? this.isParsing,
        proctoringReport: clearProctoringReport ? null : (proctoringReport ?? this.proctoringReport),
        isActingOnMatchId: clearActingMatchId ? null : (isActingOnMatchId ?? this.isActingOnMatchId),
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [
        dashboard, profile, matches, offers, tiers, categories, availableSkills,
        aiParseResult, createdOffer, checkoutUrl, offerActivated, sessionActivated,
        selectedOfferId, testSession, testSubmission, lastChatMessage, proctoringReport,
        isLoading, isLoadingMatches, isLoadingSubmission,
        isLoadingProctoring, isDownloadingReport, isSaving, isParsing,
        isActingOnMatchId, error,
      ];
}

class CompanyCubit extends Cubit<CompanyState> {
  CompanyCubit(this._datasource) : super(const CompanyState());

  final AppDatasource _datasource;

  Future<void> loadDashboard() async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final dashboardRes = await _datasource.getCompanyDashboard();
    final profileRes = await _datasource.getCompanyProfile();

    final dashboard = dashboardRes.fold((_) => null, (d) => d);
    final profile = profileRes.fold((_) => null, (p) => p);

    final error = dashboardRes.isLeft()
        ? dashboardRes.fold((f) => f.message, (_) => null)
        : null;

    emit(state.copyWith(
      dashboard: dashboard,
      profile: profile,
      isLoading: false,
      error: error,
    ));
  }

  Future<void> loadOffers() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    final result = await _datasource.getCompanyOffers();
    result.fold(
      (f) => emit(state.copyWith(isLoading: false, error: f.message)),
      (offers) => emit(state.copyWith(isLoading: false, offers: offers)),
    );
  }

  Future<void> updateProfile(String companyName) async {
    emit(state.copyWith(isSaving: true, clearError: true));
    final result = await _datasource.updateCompanyProfile(companyName);
    result.fold(
      (f) => emit(state.copyWith(isSaving: false, error: f.message)),
      (_) {
        final updated = state.profile != null
            ? CompanyProfile(
                userId: state.profile!.userId,
                companyName: companyName,
                email: state.profile!.email,
                fullName: state.profile!.fullName,
                profileCompleted: state.profile!.profileCompleted,
                activeOffers: state.profile!.activeOffers,
                totalCandidates: state.profile!.totalCandidates,
                pendingMatches: state.profile!.pendingMatches,
              )
            : state.profile;
        emit(state.copyWith(isSaving: false, profile: updated));
      },
    );
  }

  Future<void> refreshOffer(int offerId) async {
    final result = await _datasource.getOfferById(offerId);
    result.fold(
      (_) {},
      (updated) {
        final exists = state.offers.any((o) => o.id == updated.id);
        final newOffers = exists
            ? state.offers.map((o) => o.id == updated.id ? updated : o).toList()
            : [...state.offers, updated];
        emit(state.copyWith(offers: newOffers));
      },
    );
  }

  Future<void> loadTiers() async {
    if (state.tiers.isNotEmpty) return;
    final result = await _datasource.getOfferTiers();
    result.fold(
      (f) => emit(state.copyWith(error: f.message)),
      (tiers) => emit(state.copyWith(tiers: tiers)),
    );
  }

  Future<void> loadCategories() async {
    if (state.categories.isNotEmpty) return;
    final result = await _datasource.getCategories();
    result.fold(
      (f) => emit(state.copyWith(error: f.message)),
      (cats) => emit(state.copyWith(categories: cats)),
    );
  }

  Future<void> loadSkillsByCategory(int categoryId) async {
    final result = await _datasource.getSkillsByCategory(categoryId);
    result.fold(
      (f) => emit(state.copyWith(error: f.message)),
      (skills) => emit(state.copyWith(availableSkills: skills)),
    );
  }

  Future<void> parseDescription(String rawDescription) async {
    emit(state.copyWith(isParsing: true, clearAiParseResult: true, clearError: true));
    final result = await _datasource.parseOfferDescription(rawDescription);
    result.fold(
      (f) => emit(state.copyWith(isParsing: false, error: f.message)),
      (parsed) => emit(state.copyWith(isParsing: false, aiParseResult: parsed)),
    );
  }

  Future<void> createOffer(CreateOfferInput input) async {
    emit(state.copyWith(isSaving: true, clearCreatedOffer: true, clearCheckoutUrl: true, clearError: true));
    final result = await _datasource.createOffer(input);
    result.fold(
      (f) => emit(state.copyWith(isSaving: false, error: f.message)),
      (offer) => emit(state.copyWith(isSaving: false, createdOffer: offer)),
    );
  }

  Future<void> loadOfferMatches(int offerId) async {
    emit(state.copyWith(isLoadingMatches: true, selectedOfferId: offerId));
    final result = await _datasource.getMatchesByOffer(offerId);
    result.fold(
      (f) => emit(state.copyWith(isLoadingMatches: false, error: f.message)),
      (matches) => emit(state.copyWith(isLoadingMatches: false, matches: matches)),
    );
  }

  void clearOfferSelection() {
    emit(state.copyWith(matches: [], selectedOfferId: -1));
  }

  Future<void> runMatching(int offerId) async {
    emit(state.copyWith(isSaving: true, clearError: true));
    final result = await _datasource.runMatching(offerId);
    result.fold(
      (f) => emit(state.copyWith(isSaving: false, error: f.message)),
      (matches) => emit(state.copyWith(isSaving: false, matches: matches)),
    );
  }

  Future<void> reevaluateMatching(int offerId) async {
    emit(state.copyWith(isSaving: true, clearError: true));
    final result = await _datasource.reevaluateMatching(offerId);
    result.fold(
      (f) => emit(state.copyWith(isSaving: false, error: f.message)),
      (matches) => emit(state.copyWith(isSaving: false, matches: matches)),
    );
  }

  Future<void> sendTests(List<int> matchIds) async {
    emit(state.copyWith(isSaving: true, clearError: true));
    final result = await _datasource.sendTests(matchIds);
    result.fold(
      (f) => emit(state.copyWith(isSaving: false, error: f.message)),
      (_) async {
        emit(state.copyWith(isSaving: false));
        if (state.selectedOfferId != null && state.selectedOfferId! > 0) {
          await loadOfferMatches(state.selectedOfferId!);
        }
      },
    );
  }

  Future<void> selectCandidate(int matchId) async {
    emit(state.copyWith(isActingOnMatchId: matchId, clearError: true));
    final result = await _datasource.selectCandidate(matchId);
    result.fold(
      (f) => emit(state.copyWith(clearActingMatchId: true, error: f.message)),
      (updated) async {
        final newMatches = state.matches.map((m) => m.matchId == matchId ? updated : m).toList();
        emit(state.copyWith(clearActingMatchId: true, matches: newMatches));
        if (state.selectedOfferId != null && state.selectedOfferId! > 0) {
          await refreshOffer(state.selectedOfferId!);
        }
      },
    );
  }

  Future<void> rejectCandidate(int matchId) async {
    emit(state.copyWith(isActingOnMatchId: matchId, clearError: true));
    final result = await _datasource.rejectCandidate(matchId);
    result.fold(
      (f) => emit(state.copyWith(clearActingMatchId: true, error: f.message)),
      (_) {
        final newMatches = state.matches.map((m) {
          if (m.matchId == matchId) {
            return CandidateMatch(
              matchId: m.matchId,
              candidateId: m.candidateId,
              candidateName: m.candidateName,
              headline: m.headline,
              matchScore: m.matchScore,
              adjustedScore: m.adjustedScore,
              skills: m.skills,
              offerId: m.offerId,
              offerTitle: m.offerTitle,
              email: m.email,
              testScore: m.testScore,
              testFeedback: m.testFeedback,
              aiInsight: m.aiInsight,
              aiStrengths: m.aiStrengths,
              aiOpportunities: m.aiOpportunities,
              aiRecommendation: m.aiRecommendation,
              status: MatchStatus.rejected,
            );
          }
          return m;
        }).toList();
        emit(state.copyWith(clearActingMatchId: true, matches: newMatches));
      },
    );
  }

  Future<void> generateTest(int offerId, int timeLimitMinutes) async {
    emit(state.copyWith(isParsing: true, clearError: true));
    final result = await _datasource.generateTest(offerId, timeLimitMinutes);
    result.fold(
      (f) => emit(state.copyWith(isParsing: false, error: f.message)),
      (session) => emit(state.copyWith(isParsing: false, testSession: session)),
    );
  }

  Future<void> loadTestForOffer(int offerId) async {
    emit(state.copyWith(isLoading: true, clearTestSession: true, clearError: true));
    final result = await _datasource.getTestByOffer(offerId);
    result.fold(
      (f) => emit(state.copyWith(isLoading: false, error: f.message)),
      (session) => emit(state.copyWith(isLoading: false, testSession: session)),
    );
  }

  Future<void> regenerateTest(int offerId, int timeLimitMinutes) async {
    emit(state.copyWith(isParsing: true, clearError: true));
    final result = await _datasource.regenerateTest(offerId, timeLimitMinutes);
    result.fold(
      (f) => emit(state.copyWith(isParsing: false, error: f.message)),
      (session) => emit(state.copyWith(isParsing: false, testSession: session)),
    );
  }

  Future<void> chatWithQuestion(int questionId, String message) async {
    emit(state.copyWith(
        isSaving: true, clearLastChatMessage: true, clearError: true));
    final result = await _datasource.chatWithQuestion(questionId, message);
    result.fold(
      (f) => emit(state.copyWith(isSaving: false, error: f.message)),
      (chatResult) {
        if (state.testSession != null) {
          final updatedQuestions = state.testSession!.questions.map((q) {
            return q.id == chatResult.updatedQuestion.id
                ? chatResult.updatedQuestion
                : q;
          }).toList();
          final updatedSession = TestSession(
            testId: state.testSession!.testId,
            offerId: state.testSession!.offerId,
            title: state.testSession!.title,
            timeLimitMinutes: state.testSession!.timeLimitMinutes,
            questions: updatedQuestions,
          );
          emit(state.copyWith(
            isSaving: false,
            testSession: updatedSession,
            lastChatMessage: chatResult.assistantMessage,
          ));
        } else {
          emit(state.copyWith(
            isSaving: false,
            lastChatMessage: chatResult.assistantMessage,
          ));
        }
      },
    );
  }

  Future<void> updateOfferDetails(
      int offerId, Map<String, dynamic> fields) async {
    emit(state.copyWith(isSaving: true, clearError: true));
    final result = await _datasource.updateOffer(offerId, fields);
    result.fold(
      (f) => emit(state.copyWith(isSaving: false, error: f.message)),
      (updatedOffer) {
        final newOffers = state.offers.map((o) {
          return o.id == updatedOffer.id ? updatedOffer : o;
        }).toList();
        emit(state.copyWith(isSaving: false, offers: newOffers));
      },
    );
  }

  Future<void> loadTestSubmission(int matchId) async {
    emit(state.copyWith(
        isLoadingSubmission: true, clearTestSubmission: true, clearError: true));
    final result = await _datasource.getTestSubmission(matchId);
    result.fold(
      (f) => emit(state.copyWith(isLoadingSubmission: false, error: f.message)),
      (submission) =>
          emit(state.copyWith(isLoadingSubmission: false, testSubmission: submission)),
    );
  }

  Future<void> createCheckout(int offerId) async {
    if (state.isSaving) return;
    emit(state.copyWith(isSaving: true, clearCheckoutUrl: true, offerActivated: false, clearError: true));
    final result = await _datasource.createCheckout(offerId);
    result.fold(
      (f) => emit(state.copyWith(isSaving: false, error: f.message)),
      (checkout) {
        if (checkout.activated) {
          emit(state.copyWith(isSaving: false, offerActivated: true));
        } else {
          emit(state.copyWith(isSaving: false, checkoutUrl: checkout.url));
        }
      },
    );
  }

  Future<void> verifySession(String sessionId, {Duration initialDelay = Duration.zero}) async {
    emit(state.copyWith(isSaving: true, clearSessionActivated: true, clearError: true));

    // With an initialDelay we probe twice (mid-wait and end-of-wait) instead of
    // waiting the full delay before a single check, since Stripe's webhook can
    // land at any point during that window.
    final attempts = initialDelay > Duration.zero ? 2 : 1;
    final delayBetweenAttempts = initialDelay ~/ attempts;

    bool activated = false;
    String? lastErrorMessage;

    for (var attempt = 0; attempt < attempts; attempt++) {
      if (delayBetweenAttempts > Duration.zero) {
        await Future.delayed(delayBetweenAttempts);
      }
      final result = await _datasource.verifySession(sessionId);
      final isActivated = result.fold(
        (f) {
          lastErrorMessage = f.message;
          return false;
        },
        (value) {
          lastErrorMessage = null;
          return value;
        },
      );
      if (isActivated) {
        activated = true;
        break;
      }
    }

    if (activated) {
      emit(state.copyWith(isSaving: false, sessionActivated: true));
    } else if (lastErrorMessage != null) {
      emit(state.copyWith(isSaving: false, error: lastErrorMessage));
    } else {
      emit(state.copyWith(isSaving: false, sessionActivated: false));
    }
  }

  Future<void> loadProctoringReport(int matchId) async {
    emit(state.copyWith(
        isLoadingProctoring: true, clearProctoringReport: true, clearError: true));
    final result = await _datasource.getProctoringReport(matchId);
    result.fold(
      (f) => emit(state.copyWith(isLoadingProctoring: false, error: f.message)),
      (report) =>
          emit(state.copyWith(isLoadingProctoring: false, proctoringReport: report)),
    );
  }

  Future<void> downloadReport() async {
    emit(state.copyWith(isDownloadingReport: true, clearError: true));
    final result = await _datasource.downloadCompanyReport();
    result.fold(
      (f) => emit(state.copyWith(isDownloadingReport: false, error: f.message)),
      (bytes) {
        if (bytes.isNotEmpty) {
          triggerFileDownload(bytes, 'reporte-empresa.xlsx');
        }
        emit(state.copyWith(isDownloadingReport: false));
      },
    );
  }
}
