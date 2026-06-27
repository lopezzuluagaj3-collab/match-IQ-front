import '../../../core/utils/typedef.dart';
import '../../domain/entities/activity.dart';
import '../../domain/entities/admin_stats.dart';
import '../../domain/entities/candidate.dart';
import '../../domain/entities/catalog.dart';
import '../../domain/entities/company.dart';
import '../../domain/entities/job_offer.dart';
import '../../domain/entities/technical_test.dart';

abstract class AppDatasource {
  // Catalog
  ResultFuture<List<Category>> getCategories();
  ResultFuture<List<CatalogSkill>> getSkillsByCategory(int categoryId);

  // Candidate
  ResultFuture<CandidateProfile> getCandidateProfile();
  ResultFuture<CandidateProfile> updateCandidateProfile({
    int? experienceYears,
    String? seniority,
    String? englishLevel,
    String? githubLink,
    String? linkedinUrl,
    String? profilePhotoUrl,
    List<int> categoryIds = const [],
    List<Map<String, dynamic>> skills = const [],
  });
  ResultFuture<List<JobOffer>> getCandidateMatches();
  ResultFuture<List<JobOffer>> getJobOffers();
  ResultFuture<List<TechnicalTest>> getPendingTests();
  ResultFuture<List<ActivityItem>> getActivityTimeline();

  // Candidate tests
  ResultFuture<TestPreview> getTestPreview(int offerId);
  ResultFuture<TestSession> startCandidateTest(int offerId);
  ResultFuture<TestResult> submitCandidateTest(int testId, List<AnswerItem> answers);

  // Company profile
  ResultVoid updateCompanyProfile(String companyName);

  // Company offers
  ResultFuture<CompanyProfile> getCompanyProfile();
  ResultFuture<List<OfferTier>> getOfferTiers();
  ResultFuture<AiParseResult> parseOfferDescription(String rawDescription);
  ResultFuture<JobOffer> createOffer(CreateOfferInput input);
  ResultFuture<List<JobOffer>> getCompanyOffers();
  ResultFuture<String> createCheckout(int offerId);

  // Company matching
  ResultFuture<List<CandidateMatch>> getCompanyMatches();
  ResultFuture<List<CandidateMatch>> getMatchesByOffer(int offerId);
  ResultVoid sendTests(List<int> matchIds);
  ResultFuture<CandidateMatch> selectCandidate(int matchId);
  ResultVoid rejectCandidate(int matchId);

  // Company tests
  ResultFuture<TestSession> generateTest(int offerId);

  // Admin
  ResultFuture<AdminStats> getAdminStats();
}
