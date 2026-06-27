import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/catalog.dart';
import '../../domain/entities/company.dart';
import '../../domain/entities/job_offer.dart';
import '../../infrastructure/datasources/app_datasource.dart';

class CompanyState extends Equatable {
  const CompanyState({
    this.profile,
    this.matches = const [],
    this.offers = const [],
    this.tiers = const [],
    this.categories = const [],
    this.availableSkills = const [],
    this.aiParseResult,
    this.createdOffer,
    this.checkoutUrl,
    this.selectedOfferId,
    this.isLoading = false,
    this.isSaving = false,
    this.isParsing = false,
    this.error,
  });

  final CompanyProfile? profile;
  final List<CandidateMatch> matches;
  final List<JobOffer> offers;
  final List<OfferTier> tiers;
  final List<Category> categories;
  final List<CatalogSkill> availableSkills;
  final AiParseResult? aiParseResult;
  final JobOffer? createdOffer;
  final String? checkoutUrl;
  final int? selectedOfferId;
  final bool isLoading;
  final bool isSaving;
  final bool isParsing;
  final String? error;

  CompanyState copyWith({
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
    int? selectedOfferId,
    bool? isLoading,
    bool? isSaving,
    bool? isParsing,
    String? error,
    bool clearError = false,
  }) =>
      CompanyState(
        profile: profile ?? this.profile,
        matches: matches ?? this.matches,
        offers: offers ?? this.offers,
        tiers: tiers ?? this.tiers,
        categories: categories ?? this.categories,
        availableSkills: availableSkills ?? this.availableSkills,
        aiParseResult: clearAiParseResult ? null : (aiParseResult ?? this.aiParseResult),
        createdOffer: clearCreatedOffer ? null : (createdOffer ?? this.createdOffer),
        checkoutUrl: clearCheckoutUrl ? null : (checkoutUrl ?? this.checkoutUrl),
        selectedOfferId: selectedOfferId ?? this.selectedOfferId,
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        isParsing: isParsing ?? this.isParsing,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [
        profile, matches, offers, tiers, categories, availableSkills,
        aiParseResult, createdOffer, checkoutUrl, selectedOfferId,
        isLoading, isSaving, isParsing, error,
      ];
}

class CompanyCubit extends Cubit<CompanyState> {
  CompanyCubit(this._datasource) : super(const CompanyState());

  final AppDatasource _datasource;

  Future<void> loadDashboard() async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final profileRes = await _datasource.getCompanyProfile();
    final matchesRes = await _datasource.getCompanyMatches();
    final offersRes = await _datasource.getCompanyOffers();

    CompanyProfile? profile = profileRes.fold((l) => null, (r) => r);
    final List<CandidateMatch> matches = matchesRes.getOrElse(() => []);
    final List<JobOffer> offers = offersRes.getOrElse(() => []);

    // Derive KPIs from live data — the API profile doesn't include them
    if (profile != null) {
      profile = CompanyProfile(
        userId: profile.userId,
        companyName: profile.companyName,
        email: profile.email,
        fullName: profile.fullName,
        profileCompleted: profile.profileCompleted,
        activeOffers: offers.where((o) => o.isActive).length,
        totalCandidates: matches.length,
        pendingMatches: matches.where((m) => m.status == MatchStatus.new_).length,
      );
    }

    final error = profileRes.isLeft()
        ? profileRes.fold((f) => f.message, (_) => null)
        : null;

    emit(state.copyWith(
      profile: profile,
      matches: matches,
      offers: offers,
      isLoading: false,
      error: error,
    ));
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
      (offer) async {
        emit(state.copyWith(isSaving: false, createdOffer: offer));
        if (offer.isPendingPayment) {
          final offerId = int.tryParse(offer.id);
          if (offerId != null) {
            final checkoutResult = await _datasource.createCheckout(offerId);
            checkoutResult.fold(
              (f) => emit(state.copyWith(error: f.message)),
              (url) => emit(state.copyWith(checkoutUrl: url)),
            );
          }
        }
      },
    );
  }

  Future<void> loadOfferMatches(int offerId) async {
    emit(state.copyWith(isLoading: true, selectedOfferId: offerId));
    final result = await _datasource.getMatchesByOffer(offerId);
    result.fold(
      (f) => emit(state.copyWith(isLoading: false, error: f.message)),
      (matches) => emit(state.copyWith(isLoading: false, matches: matches)),
    );
  }

  Future<void> sendTests(List<int> matchIds) async {
    emit(state.copyWith(isSaving: true, clearError: true));
    final result = await _datasource.sendTests(matchIds);
    result.fold(
      (f) => emit(state.copyWith(isSaving: false, error: f.message)),
      (_) => emit(state.copyWith(isSaving: false)),
    );
  }

  Future<void> selectCandidate(int matchId) async {
    emit(state.copyWith(isSaving: true, clearError: true));
    final result = await _datasource.selectCandidate(matchId);
    result.fold(
      (f) => emit(state.copyWith(isSaving: false, error: f.message)),
      (updated) {
        final newMatches = state.matches.map((m) => m.matchId == matchId ? updated : m).toList();
        emit(state.copyWith(isSaving: false, matches: newMatches));
      },
    );
  }

  Future<void> rejectCandidate(int matchId) async {
    emit(state.copyWith(isSaving: true, clearError: true));
    final result = await _datasource.rejectCandidate(matchId);
    result.fold(
      (f) => emit(state.copyWith(isSaving: false, error: f.message)),
      (_) {
        final newMatches = state.matches.map((m) {
          if (m.matchId == matchId) {
            return CandidateMatch(
              matchId: m.matchId,
              candidateId: m.candidateId,
              candidateName: m.candidateName,
              headline: m.headline,
              matchScore: m.matchScore,
              skills: m.skills,
              offerId: m.offerId,
              offerTitle: m.offerTitle,
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
        emit(state.copyWith(isSaving: false, matches: newMatches));
      },
    );
  }

  Future<void> generateTest(int offerId) async {
    emit(state.copyWith(isSaving: true, clearError: true));
    final result = await _datasource.generateTest(offerId);
    result.fold(
      (f) => emit(state.copyWith(isSaving: false, error: f.message)),
      (_) => emit(state.copyWith(isSaving: false)),
    );
  }
}
