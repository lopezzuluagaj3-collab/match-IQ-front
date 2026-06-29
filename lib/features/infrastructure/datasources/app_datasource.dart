import 'dart:typed_data';
import '../../../core/utils/typedef.dart';
import '../../domain/entities/activity.dart';
import '../../domain/entities/admin_stats.dart';
import '../../domain/entities/admin_user.dart';
import '../../domain/entities/candidate.dart';
import '../../domain/entities/catalog.dart';
import '../../domain/entities/company.dart';
import '../../domain/entities/company_dashboard_stats.dart';
import '../../domain/entities/job_offer.dart';
import '../../domain/entities/payment.dart';
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
  ResultFuture<TestResult> getTestResult(int testId);

  // Company profile
  ResultFuture<CompanyDashboardStats> getCompanyDashboard();
  ResultVoid updateCompanyProfile(String companyName);
  ResultFuture<Uint8List> downloadCompanyReport();

  // Company offers
  ResultFuture<CompanyProfile> getCompanyProfile();
  ResultFuture<List<OfferTier>> getOfferTiers();
  ResultFuture<AiParseResult> parseOfferDescription(String rawDescription);
  ResultFuture<JobOffer> createOffer(CreateOfferInput input);
  ResultFuture<List<JobOffer>> getCompanyOffers();
  ResultFuture<JobOffer> getOfferById(int offerId);
  ResultFuture<CheckoutResult> createCheckout(int offerId);
  ResultFuture<bool> verifySession(String sessionId);

  // Company matching
  ResultFuture<List<CandidateMatch>> getCompanyMatches();
  ResultFuture<List<CandidateMatch>> getMatchesByOffer(int offerId);
  ResultFuture<List<CandidateMatch>> runMatching(int offerId);
  ResultFuture<List<CandidateMatch>> reevaluateMatching(int offerId);
  ResultVoid sendTests(List<int> matchIds);
  ResultFuture<CandidateMatch> selectCandidate(int matchId);
  ResultVoid rejectCandidate(int matchId);

  // Company tests
  ResultFuture<MatchTestSubmission> getTestSubmission(int matchId);
  ResultFuture<ProctoringReport> getProctoringReport(int matchId);
  ResultFuture<TestSession> generateTest(int offerId, int timeLimitMinutes);
  ResultFuture<TestSession?> getTestByOffer(int offerId); // null if not yet generated
  ResultFuture<TestSession> regenerateTest(int offerId, int timeLimitMinutes);
  ResultFuture<ChatResult> chatWithQuestion(int questionId, String message);
  ResultFuture<JobOffer> updateOffer(int offerId, Map<String, dynamic> fields);

  // Admin
  ResultFuture<AdminStats> getAdminStats();
  ResultFuture<List<AdminUser>> getAdminUsers({String? role, bool? isActive});
  ResultFuture<AdminUser> getAdminUserById(int userId);
  ResultVoid createAdminUser({
    required String fullName,
    required String email,
    required String cedula,
    required String password,
    required String confirmPassword,
  });
  ResultFuture<AdminUser> toggleUserStatus(int userId);
  ResultVoid deleteUser(int userId);
  ResultFuture<List<int>> downloadAdminReport();
}
