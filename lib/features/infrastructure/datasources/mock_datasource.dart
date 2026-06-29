import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
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

  @override
  ResultFuture<TestResult> getTestResult(int testId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return const Right(TestResult(
      score: 85.0,
      feedback: 'Good performance! You demonstrated solid understanding of the core concepts.',
      status: 'Evaluated',
    ));
  }

  // --- Company Dashboard ---

  @override
  ResultFuture<CompanyDashboardStats> getCompanyDashboard() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const Right(CompanyDashboardStats(
      offers: CompanyDashboardOffers(
        total: 10,
        open: 3,
        testSent: 2,
        completed: 4,
        cancelled: 1,
        expired: 0,
        pendingPayment: 0,
      ),
      matches: CompanyDashboardMatches(
        total: 87,
        testSent: 40,
        testCompleted: 31,
        selected: 8,
        rejected: 15,
        selectionRate: 20.0,
      ),
      tests: CompanyDashboardTests(
        sent: 40,
        completed: 31,
        evaluated: 28,
        expired: 3,
        completionRate: 77.5,
        averageScore: 72.4,
      ),
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
  ResultFuture<JobOffer> getOfferById(int offerId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final offer = _mockCompanyOffers
        .where((o) => o.id == offerId.toString())
        .firstOrNull;
    if (offer == null) {
      return const Left(ServerFailure(message: 'Oferta no encontrada'));
    }
    return Right(offer);
  }

  @override
  ResultFuture<CheckoutResult> createCheckout(int offerId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return const Right(CheckoutResult(url: 'https://checkout.stripe.com/c/pay/mock', activated: false));
  }

  @override
  ResultFuture<bool> verifySession(String sessionId) async {
    await Future.delayed(const Duration(seconds: 1));
    return const Right(true);
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
  ResultFuture<List<CandidateMatch>> runMatching(int offerId) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return Right(_mockCandidateMatches);
  }

  @override
  ResultFuture<List<CandidateMatch>> reevaluateMatching(int offerId) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    return Right(_mockCandidateMatches);
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

  static const _mockTestSession = TestSession(
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
        correctAnswer: 'C',
        explanation: 'HashMap utiliza hashing para O(1) promedio.',
      ),
    ],
  );

  @override
  ResultFuture<MatchTestSubmission> getTestSubmission(int matchId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return Right(MatchTestSubmission(
      matchId: matchId,
      candidateName: 'Carlos Mendoza',
      status: 'Evaluated',
      score: 82.5,
      globalFeedback:
          'El candidato demuestra un dominio sólido de estructuras de datos y algoritmos. '
          'Respondió correctamente la mayoría de las preguntas de opción múltiple y presentó '
          'una solución funcional al reto de código con complejidad O(n log n). '
          'Se recomienda avanzar a la siguiente etapa del proceso.',
      submittedAt: DateTime.now().subtract(const Duration(hours: 2)),
      aiEvaluatedAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 55)),
      questions: const [
        SubmissionQuestion(
          id: 1,
          orderIndex: 1,
          questionType: 'MultipleChoice',
          questionText: '¿Cuál es la complejidad temporal de búsqueda en un HashMap?',
          options: {'A': 'O(n)', 'B': 'O(log n)', 'C': 'O(1)', 'D': 'O(n²)'},
          correctAnswer: 'C',
          selectedOption: 'C',
          isCorrect: true,
          aiFeedback: 'HashMap usa hashing para lograr O(1) en el caso promedio.',
        ),
        SubmissionQuestion(
          id: 2,
          orderIndex: 2,
          questionType: 'MultipleChoice',
          questionText: '¿Qué patrón de arquitectura separa la lógica de negocio de la UI en Flutter?',
          options: {
            'A': 'MVC',
            'B': 'BLoC / Cubit',
            'C': 'Singleton',
            'D': 'Observer'
          },
          correctAnswer: 'B',
          selectedOption: 'B',
          isCorrect: true,
          aiFeedback: 'BLoC (Business Logic Component) es el patrón recomendado en Flutter para separar lógica de UI.',
        ),
        SubmissionQuestion(
          id: 3,
          orderIndex: 3,
          questionType: 'MultipleChoice',
          questionText: '¿Cuál de los siguientes NO es un principio SOLID?',
          options: {
            'A': 'Single Responsibility',
            'B': 'Open/Closed',
            'C': 'Dynamic Binding',
            'D': 'Dependency Inversion'
          },
          correctAnswer: 'C',
          selectedOption: 'A',
          isCorrect: false,
          aiFeedback: 'Dynamic Binding no es un principio SOLID. SOLID incluye: SRP, OCP, LSP, ISP, DIP.',
        ),
        SubmissionQuestion(
          id: 4,
          orderIndex: 4,
          questionType: 'MultipleChoice',
          questionText: '¿Qué estructura de datos es LIFO (Last In, First Out)?',
          options: {
            'A': 'Queue',
            'B': 'Stack',
            'C': 'LinkedList',
            'D': 'Heap'
          },
          correctAnswer: 'B',
          selectedOption: 'B',
          isCorrect: true,
          aiFeedback: 'Stack (pila) sigue el principio LIFO — el último elemento añadido es el primero en salir.',
        ),
        SubmissionQuestion(
          id: 5,
          orderIndex: 5,
          questionType: 'MultipleChoice',
          questionText: '¿Cuál es la diferencia principal entre `async/await` y `Future.then()` en Dart?',
          options: {
            'A': 'No hay diferencia, son equivalentes',
            'B': 'async/await es más legible y maneja errores con try/catch',
            'C': 'Future.then() es más eficiente en rendimiento',
            'D': 'async/await solo funciona con streams'
          },
          correctAnswer: 'B',
          selectedOption: 'B',
          isCorrect: true,
          aiFeedback: 'async/await es azúcar sintáctica sobre Futures que mejora la legibilidad y permite manejo de errores con try/catch.',
        ),
        SubmissionQuestion(
          id: 6,
          orderIndex: 6,
          questionType: 'CodeChallenge',
          questionText:
              'Implementa una función en Dart que reciba una lista de enteros y retorne los elementos únicos ordenados de mayor a menor.',
          functionSignature: 'List<int> uniqueSorted(List<int> nums)',
          expectedBehavior: 'Retorna los elementos únicos de la lista, ordenados de mayor a menor.',
          codeSubmitted: '''List<int> uniqueSorted(List<int> nums) {
  return nums.toSet().toList()..sort((a, b) => b.compareTo(a));
}''',
          isCorrect: true,
          aiFeedback: 'Solución correcta: usa Set para eliminar duplicados y sort con comparador inverso.',
        ),
      ],
    ));
  }

  @override
  ResultFuture<Uint8List> downloadCompanyReport() async {
    await Future.delayed(const Duration(milliseconds: 800));
    // Return empty bytes in mock — real download only works against live backend
    return Right(Uint8List(0));
  }

  @override
  ResultFuture<ProctoringReport> getProctoringReport(int matchId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return Right(ProctoringReport(
      sessionId: 'mock-session-001',
      inicio: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
      fin: DateTime.now().subtract(const Duration(minutes: 30)),
      totalFramesProcesados: 7200,
      totalEventos: 2,
      integrityScore: 60.0,
      integritySummary:
          'Durante la sesión se detectaron dos incidentes: uso de dispositivo adicional '
          'y presencia de una segunda persona. El score de integridad de 60/100 indica '
          'riesgo moderado. Se recomienda revisar los eventos antes de tomar una decisión.',
      eventos: [
        ProctoringEvent(
          tipo: 'dispositivo_prohibido',
          detalle: 'Detectado: cell phone',
          evidencia: null,
          timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 20)),
        ),
        ProctoringEvent(
          tipo: 'segunda_persona',
          detalle: 'Rostro adicional detectado en frame',
          evidencia: null,
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ],
    ));
  }

  @override
  ResultFuture<TestSession> generateTest(int offerId, int timeLimitMinutes) async {
    await Future.delayed(const Duration(milliseconds: 1500));
    return Right(TestSession(
      testId: _mockTestSession.testId,
      offerId: offerId,
      title: _mockTestSession.title,
      timeLimitMinutes: timeLimitMinutes,
      questions: _mockTestSession.questions,
    ));
  }

  @override
  ResultFuture<TestSession?> getTestByOffer(int offerId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const Right(null); // no test yet in mock
  }

  @override
  ResultFuture<TestSession> regenerateTest(int offerId, int timeLimitMinutes) async {
    await Future.delayed(const Duration(milliseconds: 1500));
    return Right(TestSession(
      testId: _mockTestSession.testId,
      offerId: offerId,
      title: _mockTestSession.title,
      timeLimitMinutes: timeLimitMinutes,
      questions: _mockTestSession.questions,
    ));
  }

  @override
  ResultFuture<ChatResult> chatWithQuestion(int questionId, String message) async {
    await Future.delayed(const Duration(milliseconds: 800));
    const updatedQ = TestQuestion(
      id: 100,
      orderIndex: 0,
      questionType: 'MultipleChoice',
      questionText: '¿Cuál es la complejidad promedio de búsqueda en un HashMap?',
      options: {'A': 'O(n)', 'B': 'O(log n)', 'C': 'O(1)', 'D': 'O(n²)'},
      correctAnswer: 'C',
      explanation: 'HashMap usa hashing para lograr O(1) en el caso promedio.',
    );
    return const Right(ChatResult(
      updatedQuestion: updatedQ,
      assistantMessage: 'He ajustado la pregunta para ser más específica sobre la complejidad promedio.',
    ));
  }

  @override
  ResultFuture<JobOffer> updateOffer(int offerId, Map<String, dynamic> fields) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return const Left(ServerFailure(message: 'Mock: updateOffer not implemented'));
  }

  // --- Admin ---

  @override
  ResultFuture<AdminStats> getAdminStats() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return Right(_mockAdminStats);
  }

  @override
  ResultFuture<List<AdminUser>> getAdminUsers(
      {String? role, bool? isActive}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    var list = List<AdminUser>.from(_mockAdminUsers);
    if (role != null) list = list.where((u) => u.role == role).toList();
    if (isActive != null) {
      list = list.where((u) => u.isActive == isActive).toList();
    }
    return Right(list);
  }

  @override
  ResultFuture<AdminUser> getAdminUserById(int userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return Right(_mockAdminUsers.firstWhere((u) => u.id == userId));
    } catch (_) {
      return Left(ServerFailure(message: 'Usuario $userId no encontrado.'));
    }
  }

  @override
  ResultVoid createAdminUser({
    required String fullName,
    required String email,
    required String cedula,
    required String password,
    required String confirmPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return const Right(null);
  }

  @override
  ResultFuture<AdminUser> toggleUserStatus(int userId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    try {
      final user = _mockAdminUsers.firstWhere((u) => u.id == userId);
      final updated = AdminUser(
        id: user.id,
        email: user.email,
        fullName: user.fullName,
        cedula: user.cedula,
        role: user.role,
        isActive: !user.isActive,
        emailVerified: user.emailVerified,
        createdAt: user.createdAt,
        profileName: user.profileName,
      );
      final idx = _mockAdminUsers.indexWhere((u) => u.id == userId);
      _mockAdminUsers[idx] = updated;
      return Right(updated);
    } catch (_) {
      return Left(ServerFailure(message: 'Usuario $userId no encontrado.'));
    }
  }

  @override
  ResultVoid deleteUser(int userId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _mockAdminUsers.removeWhere((u) => u.id == userId);
    return const Right(null);
  }

  // ---- Mock Data ----

  static final _mockCandidateProfile = CandidateProfile(
    userId: 'candidate-001',
    name: 'Alex Reyes',
    email: 'candidate@test.com',
    headline: 'Senior Product Designer',
    primaryCategoryId: 2,
    skillEntries: const [
      SkillEntry(id: 5, name: 'React', level: 4),
      SkillEntry(id: 7, name: 'TypeScript', level: 3),
      SkillEntry(id: 8, name: 'Flutter', level: 5),
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
      status: MatchStatus.testCompleted,
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
    totalCandidates: 120,
    totalCompanies: 35,
    usersRegisteredLast30Days: 45,
    totalOffers: 58,
    offersCreatedLast30Days: 10,
    offersActive: 18,
    offersCompleted: 20,
    offersCancelled: 3,
    offersExpired: 1,
    offersPendingPayment: 5,
    offersByStatus: {
      'PendingPayment': 5,
      'Open': 18,
      'Completed': 20,
      'Cancelled': 3,
      'Expired': 1,
    },
    totalMatches: 430,
    matchesSelected: 28,
    matchesRejected: 45,
    matchesTestSent: 62,
    matchesTestCompleted: 38,
    activeTests: 12,
    pendingSubmissions: 8,
    submissionsEvaluated: 95,
    submissionsExpired: 12,
    averageTestScore: 74.3,
    totalRevenueCop: 4850000,
    paymentsCompleted: 24,
    paymentsPending: 3,
    testCompletionRate: 88.8,
    selectionRate: 25.2,
  );

  static final _mockAdminUsers = <AdminUser>[
    AdminUser(
      id: 1,
      email: 'admin@matchiq.co',
      fullName: 'Admin MatchIQ',
      cedula: '0000000001',
      role: 'Admin',
      isActive: true,
      emailVerified: true,
      createdAt: DateTime(2026, 1, 1),
    ),
    AdminUser(
      id: 2,
      email: 'maria.gonzalez@gmail.com',
      fullName: 'María González',
      cedula: '1234567890',
      role: 'Candidate',
      isActive: true,
      emailVerified: true,
      createdAt: DateTime(2026, 3, 15),
    ),
    AdminUser(
      id: 3,
      email: 'carlos.rueda@gmail.com',
      fullName: 'Carlos Rueda',
      cedula: '0987654321',
      role: 'Candidate',
      isActive: true,
      emailVerified: true,
      createdAt: DateTime(2026, 4, 2),
    ),
    AdminUser(
      id: 4,
      email: 'sofia.m@gmail.com',
      fullName: 'Sofía Martínez',
      cedula: '1122334455',
      role: 'Candidate',
      isActive: false,
      emailVerified: false,
      createdAt: DateTime(2026, 5, 10),
    ),
    AdminUser(
      id: 5,
      email: 'hr@stellarai.co',
      fullName: 'Stellar AI HR',
      cedula: '2233445566',
      role: 'Company',
      isActive: true,
      emailVerified: true,
      createdAt: DateTime(2026, 2, 20),
      profileName: 'Stellar AI',
    ),
    AdminUser(
      id: 6,
      email: 'talent@nexusfintech.com',
      fullName: 'Nexus FinTech Talent',
      cedula: '3344556677',
      role: 'Company',
      isActive: true,
      emailVerified: true,
      createdAt: DateTime(2026, 3, 5),
      profileName: 'Nexus FinTech',
    ),
  ];
}
