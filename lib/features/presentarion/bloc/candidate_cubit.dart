import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/activity.dart';
import '../../domain/entities/candidate.dart';
import '../../domain/entities/catalog.dart';
import '../../domain/entities/job_offer.dart';
import '../../domain/entities/technical_test.dart';
import '../../infrastructure/datasources/app_datasource.dart';

// State
class CandidateState extends Equatable {
  const CandidateState({
    this.profile,
    this.matches = const [],
    this.offers = const [],
    this.pendingTests = const [],
    this.activity = const [],
    this.categories = const [],
    this.catalogSkills = const [],
    this.isLoading = false,
    this.isSavingProfile = false,
    this.error,
  });

  final CandidateProfile? profile;
  final List<JobOffer> matches;
  final List<JobOffer> offers;
  final List<TechnicalTest> pendingTests;
  final List<ActivityItem> activity;
  final List<Category> categories;
  final List<CatalogSkill> catalogSkills;
  final bool isLoading;
  final bool isSavingProfile;
  final String? error;

  CandidateState copyWith({
    CandidateProfile? profile,
    List<JobOffer>? matches,
    List<JobOffer>? offers,
    List<TechnicalTest>? pendingTests,
    List<ActivityItem>? activity,
    List<Category>? categories,
    List<CatalogSkill>? catalogSkills,
    bool? isLoading,
    bool? isSavingProfile,
    String? error,
  }) =>
      CandidateState(
        profile: profile ?? this.profile,
        matches: matches ?? this.matches,
        offers: offers ?? this.offers,
        pendingTests: pendingTests ?? this.pendingTests,
        activity: activity ?? this.activity,
        categories: categories ?? this.categories,
        catalogSkills: catalogSkills ?? this.catalogSkills,
        isLoading: isLoading ?? this.isLoading,
        isSavingProfile: isSavingProfile ?? this.isSavingProfile,
        error: error,
      );

  @override
  List<Object?> get props => [
        profile, matches, offers, pendingTests, activity,
        categories, catalogSkills, isLoading, isSavingProfile, error,
      ];
}

// Cubit
class CandidateCubit extends Cubit<CandidateState> {
  CandidateCubit(this._datasource) : super(const CandidateState());

  final AppDatasource _datasource;

  Future<void> loadDashboard() async {
    emit(state.copyWith(isLoading: true));
    final results = await Future.wait([
      _datasource.getCandidateProfile(),
      _datasource.getPendingTests(),
    ]);

    emit(state.copyWith(
      profile: (results[0] as dynamic).getOrElse(() => null),
      pendingTests: (results[1] as dynamic).getOrElse(() => []),
      isLoading: false,
    ));
  }

  Future<void> loadOffers() async {
    emit(state.copyWith(isLoading: true));
    final result = await _datasource.getJobOffers();
    result.fold(
      (f) => emit(state.copyWith(isLoading: false, error: f.message)),
      (offers) => emit(state.copyWith(isLoading: false, offers: offers)),
    );
  }

  Future<void> loadAssessments() async {
    emit(state.copyWith(isLoading: true));
    final result = await _datasource.getPendingTests();
    result.fold(
      (f) => emit(state.copyWith(isLoading: false, error: f.message)),
      (tests) => emit(state.copyWith(isLoading: false, pendingTests: tests)),
    );
  }

  Future<void> loadProfile() async {
    emit(state.copyWith(isLoading: true));
    final result = await _datasource.getCandidateProfile();
    result.fold(
      (f) => emit(state.copyWith(isLoading: false, error: f.message)),
      (profile) => emit(state.copyWith(isLoading: false, profile: profile)),
    );
  }

  Future<void> updateProfile({
    int? experienceYears,
    String? seniority,
    String? englishLevel,
    String? githubLink,
    String? linkedinUrl,
    String? profilePhotoUrl,
    List<int> categoryIds = const [],
    List<Map<String, dynamic>> skills = const [],
  }) async {
    emit(state.copyWith(isSavingProfile: true));
    final result = await _datasource.updateCandidateProfile(
      experienceYears: experienceYears,
      seniority: seniority,
      englishLevel: englishLevel,
      githubLink: githubLink,
      linkedinUrl: linkedinUrl,
      profilePhotoUrl: profilePhotoUrl,
      categoryIds: categoryIds,
      skills: skills,
    );
    result.fold(
      (f) => emit(state.copyWith(isSavingProfile: false, error: f.message)),
      (profile) => emit(state.copyWith(isSavingProfile: false, profile: profile)),
    );
  }

  Future<void> loadCategories() async {
    if (state.categories.isNotEmpty) return;
    final result = await _datasource.getCategories();
    result.fold(
      (_) {},
      (cats) => emit(state.copyWith(categories: cats)),
    );
  }

  Future<void> loadSkillsByCategory(int categoryId) async {
    final result = await _datasource.getSkillsByCategory(categoryId);
    result.fold(
      (_) {},
      (skills) => emit(state.copyWith(catalogSkills: skills)),
    );
  }

  void clearCatalogSkills() => emit(state.copyWith(catalogSkills: []));
}
