import 'package:dartz/dartz.dart';
import '../../../core/utils/typedef.dart';
import '../../domain/entities/activity.dart';
import '../../domain/entities/admin_stats.dart';
import '../../domain/entities/candidate.dart';
import '../../domain/entities/catalog.dart';
import '../../domain/entities/company.dart';
import '../../domain/entities/job_offer.dart';
import '../../domain/entities/technical_test.dart';
import 'app_datasource.dart';

class MockDatasource implements AppDatasource {
  // --- Catalog ---

  @override
  ResultFuture<List<Category>> getCategories() async {
    return const Right([
      Category(id: 1, name: 'Backend'),
      Category(id: 2, name: 'Frontend'),
      Category(id: 3, name: 'Full Stack'),
      Category(id: 4, name: 'Mobile'),
      Category(id: 5, name: 'DevOps'),
      Category(id: 6, name: 'Data / ML'),
    ]);
  }

  @override
  ResultFuture<List<CatalogSkill>> getSkillsByCategory(int categoryId) async {
    const allSkills = [
      CatalogSkill(id: 1, name: 'C#', categoryId: 1),
      CatalogSkill(id: 2, name: 'Python', categoryId: 1),
      CatalogSkill(id: 3, name: 'Node.js', categoryId: 1),
      CatalogSkill(id: 4, name: 'PostgreSQL', categoryId: 1),
      CatalogSkill(id: 5, name: 'React', categoryId: 2),
      CatalogSkill(id: 6, name: 'Vue.js', categoryId: 2),
      CatalogSkill(id: 7, name: 'TypeScript', categoryId: 2),
      CatalogSkill(id: 8, name: 'Flutter', categoryId: 4),
      CatalogSkill(id: 9, name: 'Swift', categoryId: 4),
      CatalogSkill(id: 10, name: 'Docker', categoryId: 5),
    ];
    final filtered = allSkills.where((s) => s.categoryId == categoryId).toList();
    return Right(filtered.isNotEmpty ? filtered : allSkills.take(4).toList());
  }

  // --- Candidate ---

  @override
  ResultFuture<CandidateProfile> getCandidateProfile() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return Right(_mockCandidateProfile);
  }

  @override
  ResultFuture<List<JobOffer>> getCandidateMatches() async {
    return const Right([]);
  }

  @override
  ResultFuture<List<JobOffer>> getJobOffers() async {
    return const Right([]);
  }

  @override
  ResultFuture<CandidateProfile> updateCandidateProfile({
    int? experienceYears,
    String? seniority,
    String? englishLevel,
    String? githubLink,
    String? linkedinUrl,
    String? profilePhotoUrl,
    List<int> categoryIds = const [],
    List<Map<String, dynamic>> skills = const [],
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return Right(_mockCandidateProfile);
  }

  @override
  ResultFuture<List<TechnicalTest>> getPendingTests() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return Right(_mockPendingTests);
  }

  @override
  ResultFuture<List<ActivityItem>> getActivityTimeline() async {
    return Right(_mockActivity);
  }

  @override
  ResultFuture<TestPreview> getTestPreview(int offerId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return Right(TestPreview(
      testId: offerId,
      title: 'Technical Assessment Preview',
      timeLimitMinutes: 60,
      totalQuestions: 6,
      multipleChoiceCount: 5,
      codeChallengeCount: 1,
    ));
  }

  @override
  ResultFuture<TestSession> startCandidateTest(int offerId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const Right(TestSession(
      testId: 1,
      offerId: 1,
      title: 'System Architecture Challenge',
      timeLimitMinutes: 60,
      questions: [
        TestQuestion(
          id: 1,
          orderIndex: 0,
          questionType: 'MultipleChoice',
          questionText:
              'Which design pattern best describes an application where all state flows in one direction?',
          options: {
            'A': 'MVC',
            'B': 'Unidirectional Data Flow (BLoC, Redux)',
            'C': 'Observer Pattern',
            'D': 'Factory Pattern'
          },
        ),
      ],
    ));
  }

  @override
  ResultFuture<TestResult> submitCandidateTest(
      int testId, List<AnswerItem> answers) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return const Right(TestResult(
      score: 85.0,
      feedback: 'Good job! Results will be fully processed shortly.',
      status: 'Submitted',
    ));
  }

  // --- Company Profile ---

  @override
  ResultFuture<CompanyProfile> getCompanyProfile() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return Right(_mockCompanyProfile);
  }

  @override
  ResultVoid updateCompanyProfile(String companyName) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return const Right(null);
  }

  // --- Company Offers ---

  @override
  ResultFuture<List<OfferTier>> getOfferTiers() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const Right(_mockTiers);
  }

  @override
  ResultFuture<AiParseResult> parseOfferDescription(
      String rawDescription) async {
    await Future.delayed(const Duration(milliseconds: 1200));
    return const Right(AiParseResult(
      title: 'Desarrollador React Senior',
      modality: 'remote',
      salary: 5000000,
      minExperienceYears: 3,
      requiredEnglishLevel: 'B2',
      suggestedCategoryIds: [2],
      suggestedSkillIds: [5, 7],
      confidenceNote: 'Skills identificadas con alta confianza.',
    ));
  }

  @override
  ResultFuture<JobOffer> createOffer(CreateOfferInput input) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return Right(JobOffer(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      title: input.title,
      companyName: 'Stellar AI',
      companyLogoUrl: '',
      salary: input.salary != null ? '\$${input.salary}' : 'No especificado',
      type: OfferType.fullTime,
      mode: input.modality == 'remote'
          ? OfferMode.remote
          : input.modality == 'hybrid'
              ? OfferMode.hybrid
              : OfferMode.onSite,
      skills: const [],
      description: input.description,
      postedAt: DateTime.now(),
      status: 'PendingPayment',
      tierId: input.tierId,
      checkoutUrl: null,
    ));
  }

  @override
  ResultFuture<List<JobOffer>> getCompanyOffers() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return Right(_mockCompanyOffers);
  }

  @override
  ResultFuture<String> createCheckout(int offerId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return const Right('https://checkout.wompi.co/l/mock-checkout-link');
  }

  // --- Company Matching ---

  @override
  ResultFuture<List<CandidateMatch>> getCompanyMatches() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return Right(_mockCandidateMatches);
  }

  @override
  ResultFuture<List<CandidateMatch>> getMatchesByOffer(int offerId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return Right(_mockCandidateMatches
        .where((m) => m.offerId == offerId.toString())
        .toList()
        .isNotEmpty
        ? _mockCandidateMatches
            .where((m) => m.offerId == offerId.toString())
            .toList()
        : _mockCandidateMatches);
  }

  @override
  ResultVoid sendTests(List<int> matchIds) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return const Right(null);
  }

  @override
  ResultFuture<CandidateMatch> selectCandidate(int matchId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final match = _mockCandidateMatches.firstWhere(
      (m) => m.matchId == matchId,
      orElse: () => _mockCandidateMatches.first,
    );
    return Right(CandidateMatch(
      matchId: match.matchId,
      candidateId: match.candidateId,
      candidateName: match.candidateName,
      headline: match.headline,
      matchScore: match.matchScore,
      skills: match.skills,
      offerId: match.offerId,
      offerTitle: match.offerTitle,
      testScore: match.testScore,
      testFeedback: match.testFeedback,
      status: MatchStatus.shortlisted,
    ));
  }

  @override
  ResultVoid rejectCandidate(int matchId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return const Right(null);
  }

  // --- Company Tests ---

  @override
  ResultFuture<TestSession> generateTest(int offerId) async {
    await Future.delayed(const Duration(milliseconds: 1500));
    return const Right(TestSession(
      testId: 99,
      offerId: 1,
      title: 'Test técnico generado por IA',
      timeLimitMinutes: 45,
      questions: [
        TestQuestion(
          id: 100,
          orderIndex: 0,
          questionType: 'MultipleChoice',
          questionText: '¿Cuál es la complejidad de búsqueda en un HashMap?',
          options: {'A': 'O(n)', 'B': 'O(log n)', 'C': 'O(1)', 'D': 'O(n²)'},
        ),
      ],
    ));
  }

  // --- Admin ---

  @override
  ResultFuture<AdminStats> getAdminStats() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return Right(_mockAdminStats);
  }

  // ---- Mock Data ----

  static final _mockCandidateProfile = CandidateProfile(
    userId: 'candidate-001',
    name: 'Alex Reyes',
    email: 'candidate@test.com',
    headline: 'Senior Product Designer',
    skills: const [
      'UI/UX Design', 'Figma', 'Flutter', 'React', 'Design Systems', 'Prototyping'
    ],
    matchScore: 94,
    profileStrength: 82,
    pendingTests: 3,
    activeApplications: 12,
    location: 'Bogotá, Colombia',
    bio: 'Passionate designer with 6+ years of experience.',
    experience: const [
      ExperienceItem(
          title: 'Senior Product Designer',
          company: 'TechCorp',
          startDate: 'Jan 2022',
          isCurrent: true),
      ExperienceItem(
          title: 'UI/UX Designer',
          company: 'Startup Hub',
          startDate: 'Mar 2020',
          endDate: 'Dec 2021'),
    ],
    education: const [
      EducationItem(
          degree: 'B.Sc. Multimedia Design',
          institution: 'Universidad de los Andes',
          year: '2018'),
    ],
  );

  static final _mockPendingTests = [
    TechnicalTest(
      id: 'test-001',
      offerId: 1,
      title: 'System Architecture Challenge',
      durationMinutes: 60,
      dueDate: DateTime.now().add(const Duration(days: 2)),
      status: TestStatus.pending,
      iconType: 'terminal',
    ),
    TechnicalTest(
      id: 'test-002',
      offerId: 2,
      title: 'Behavioral & Cultural Fit',
      durationMinutes: 25,
      dueDate: DateTime.now().add(const Duration(days: 5)),
      status: TestStatus.pending,
      iconType: 'psychology',
    ),
    TechnicalTest(
      id: 'test-003',
      offerId: 3,
      title: 'Frontend Design Challenge',
      durationMinutes: 45,
      dueDate: DateTime.now().subtract(const Duration(days: 1)),
      status: TestStatus.completed,
      iconType: 'design',
      score: 91,
    ),
    TechnicalTest(
      id: 'test-004',
      offerId: 4,
      title: 'Backend API Performance',
      durationMinutes: 90,
      dueDate: DateTime.now().subtract(const Duration(days: 3)),
      status: TestStatus.expired,
      iconType: 'terminal',
    ),
  ];

  static final _mockActivity = [
    ActivityItem(
      title: 'Interview Scheduled',
      description: 'Technical Round with Orbit Inc. for Monday, Oct 14.',
      timestamp: 'Today, 10:45 AM',
      type: ActivityType.interview,
    ),
    ActivityItem(
      title: 'New Match Found',
      description: 'AI matched you with a Senior Designer role at Stellar AI.',
      timestamp: '2 days ago',
      type: ActivityType.match,
    ),
    ActivityItem(
      title: 'Assessment Completed',
      description: 'You scored 91/100 on the Design Thinking test.',
      timestamp: '3 days ago',
      type: ActivityType.test,
    ),
  ];

  static const _mockCompanyProfile = CompanyProfile(
    userId: 'company-001',
    companyName: 'Stellar AI',
    email: 'company@stellar.ai',
    fullName: 'Ana García',
    profileCompleted: true,
    activeOffers: 5,
    totalCandidates: 124,
    pendingMatches: 18,
  );

  static const _mockTiers = [
    OfferTier(id: 1, name: 'Starter', minCandidates: 1, maxCandidates: 1, priceCop: 89000),
    OfferTier(id: 2, name: 'Básico', minCandidates: 2, maxCandidates: 3, priceCop: 199000),
    OfferTier(id: 3, name: 'Estándar', minCandidates: 4, maxCandidates: 7, priceCop: 349000),
    OfferTier(id: 4, name: 'Avanzado', minCandidates: 8, maxCandidates: 15, priceCop: 599000),
  ];

  static final _mockCompanyOffers = [
    JobOffer(
      id: '1',
      title: 'Senior React Developer',
      companyName: 'Stellar AI',
      companyLogoUrl: '',
      salary: '\$5.000.000 COP',
      type: OfferType.fullTime,
      mode: OfferMode.remote,
      skills: const ['React', 'TypeScript', 'Node.js'],
      description: 'Build the future of AI-powered products.',
      postedAt: DateTime.now().subtract(const Duration(days: 5)),
      isActive: true,
      status: 'Open',
      tierId: 3,
      tierName: 'Estándar',
    ),
    JobOffer(
      id: '2',
      title: 'Flutter Mobile Engineer',
      companyName: 'Stellar AI',
      companyLogoUrl: '',
      salary: '\$4.500.000 COP',
      type: OfferType.fullTime,
      mode: OfferMode.hybrid,
      skills: const ['Flutter', 'Dart', 'Firebase'],
      description: 'Create cross-platform mobile experiences.',
      postedAt: DateTime.now().subtract(const Duration(days: 12)),
      isActive: true,
      status: 'TestSent',
      tierId: 2,
      tierName: 'Básico',
    ),
    JobOffer(
      id: '3',
      title: 'Backend Python Engineer',
      companyName: 'Stellar AI',
      companyLogoUrl: '',
      salary: 'No especificado',
      type: OfferType.fullTime,
      mode: OfferMode.remote,
      skills: const ['Python', 'FastAPI', 'PostgreSQL'],
      description: 'Architect scalable backend systems.',
      postedAt: DateTime.now().subtract(const Duration(days: 20)),
      isActive: false,
      status: 'PendingPayment',
      tierId: 1,
      tierName: 'Starter',
      checkoutUrl: 'https://checkout.wompi.co/l/mock',
    ),
  ];

  static final _mockCandidateMatches = [
    CandidateMatch(
      matchId: 1,
      candidateId: 'c1',
      candidateName: 'María González',
      headline: 'B2 · 5y exp',
      matchScore: 97,
      skills: const ['React', 'TypeScript', 'Node.js'],
      offerId: '1',
      offerTitle: 'Senior React Developer',
      testScore: 94,
      testFeedback:
          'Buen desempeño general. Código limpio y bien estructurado.',
      aiInsight: 'Candidata con dominio avanzado de React y experiencia alineada al rol.',
      aiStrengths: const ['React avanzado', 'TypeScript sólido', 'Experiencia en proyectos escalables'],
      aiOpportunities: const ['Puede reforzar Node.js'],
      aiRecommendation: 'Altamente recomendada para el test técnico.',
      status: MatchStatus.reviewed,
    ),
    CandidateMatch(
      matchId: 2,
      candidateId: 'c2',
      candidateName: 'Carlos Rueda',
      headline: 'B1 · 3y exp',
      matchScore: 88,
      skills: const ['React', 'JavaScript', 'CSS'],
      offerId: '1',
      offerTitle: 'Senior React Developer',
      aiInsight: 'Candidato con buen manejo de frontend aunque menor experiencia en TypeScript.',
      aiStrengths: const ['React sólido', 'CSS avanzado'],
      aiOpportunities: const ['TypeScript limitado', 'Sin experiencia en backend'],
      aiRecommendation: 'Recomendado para el test técnico.',
      status: MatchStatus.new_,
    ),
    CandidateMatch(
      matchId: 3,
      candidateId: 'c3',
      candidateName: 'Sofia Martínez',
      headline: 'C1 · 7y exp',
      matchScore: 82,
      skills: const ['React', 'TypeScript', 'GraphQL'],
      offerId: '1',
      offerTitle: 'Senior React Developer',
      status: MatchStatus.new_,
    ),
  ];

  static const _mockAdminStats = AdminStats(
    totalCandidates: 1248,
    totalCompanies: 87,
    totalOffers: 58,
    totalMatches: 3421,
    activeTests: 156,
    pendingSubmissions: 8,
    usersLast30Days: 43,
    offersLast30Days: 10,
  );
}
