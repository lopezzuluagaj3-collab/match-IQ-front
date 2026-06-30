import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/api/token_storage.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utils/typedef.dart';
import '../../domain/entities/activity.dart';
import '../../domain/entities/admin_stats.dart';
import '../../domain/entities/admin_user.dart';
import '../../domain/entities/candidate.dart' show CandidateProfile, SkillEntry;
import '../../domain/entities/catalog.dart';
import '../../domain/entities/company.dart';
import '../../domain/entities/company_dashboard_stats.dart';
import '../../domain/entities/job_offer.dart';
import '../../domain/entities/market_analytics.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/technical_test.dart';
import 'app_datasource.dart';

class RemoteDatasource implements AppDatasource {
  RemoteDatasource(this._client, this._storage);

  final ApiClient _client;
  // ignore: unused_field
  final TokenStorage _storage;

  // ─── Catalog ─────────────────────────────────────────────────────────────

  @override
  ResultFuture<List<Category>> getCategories() async {
    final result = await _client.get(ApiConstants.categories);
    return result.fold(
      (f) => Left(f),
      (data) {
        final list = data as List<dynamic>? ?? [];
        return Right(list
            .map((c) => Category(id: c['id'] as int, name: c['name'] as String))
            .toList());
      },
    );
  }

  @override
  ResultFuture<List<CatalogSkill>> getSkillsByCategory(int categoryId) async {
    final result = await _client.get(ApiConstants.skillsByCategory(categoryId));
    return result.fold(
      (f) => Left(f),
      (data) {
        final list = data as List<dynamic>? ?? [];
        return Right(list
            .map((s) => CatalogSkill(
                  id: s['id'] as int,
                  name: s['name'] as String,
                  categoryId: s['categoryId'] as int,
                ))
            .toList());
      },
    );
  }

  // ─── Candidate ───────────────────────────────────────────────────────────

  @override
  ResultFuture<CandidateProfile> getCandidateProfile() async {
    final result = await _client.get(ApiConstants.candidateProfile);
    return result.fold(
      (f) => Left(f),
      (data) {
        if (data == null) {
          return const Left(ServerFailure(message: 'Perfil no encontrado'));
        }
        final map = data as Map<String, dynamic>;
        final rawSkills = map['skills'] as List<dynamic>? ?? [];
        final skillEntries = rawSkills.map((s) {
          final m = s as Map<String, dynamic>;
          return SkillEntry(
            id: m['skillId'] as int? ?? m['id'] as int? ?? 0,
            name: m['skillName'] as String? ?? '',
            level: m['level'] as int? ?? 3,
          );
        }).where((e) => e.id > 0).toList();
        final rawCategories = map['categories'] as List<dynamic>? ?? [];
        final firstCategoryMap = rawCategories.firstOrNull as Map<String, dynamic>?;
        final firstCategory = firstCategoryMap?['name'] as String?;
        final primaryCategoryId = firstCategoryMap?['id'] as int?;
        final seniority = map['seniority'] as String? ?? '';
        final years = map['experienceYears'] as int? ?? 0;

        return Right(CandidateProfile(
          userId: map['userId'].toString(),
          name: map['fullName'] as String,
          email: map['email'] as String,
          headline: [
            if (seniority.isNotEmpty) _capitalize(seniority),
            if (firstCategory != null) firstCategory,
            if (years > 0) '${years}y exp',
          ].join(' · '),
          skillEntries: skillEntries,
          experience: const [],
          education: const [],
          matchScore: 0,
          profileStrength: (map['profileCompleted'] as bool? ?? false) ? 100 : 40,
          pendingTests: 0,
          activeApplications: 0,
          primaryCategoryId: primaryCategoryId,
          avatarUrl: map['profilePhotoUrl'] as String?,
          location: null,
          bio: null,
          githubUrl: map['githubLink'] as String?,
          linkedinUrl: map['linkedinUrl'] as String?,
          seniority: seniority.isNotEmpty ? seniority : null,
          englishLevel: map['englishLevel'] as String?,
          experienceYears: years > 0 ? years : null,
        ));
      },
    );
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
    final result = await _client.put(
      ApiConstants.candidateProfile,
      body: {
        if (experienceYears != null) 'experienceYears': experienceYears,
        if (seniority != null) 'seniority': seniority,
        if (englishLevel != null) 'englishLevel': englishLevel,
        if (githubLink != null) 'githubLink': githubLink,
        if (linkedinUrl != null) 'linkedinUrl': linkedinUrl,
        if (profilePhotoUrl != null) 'profilePhotoUrl': profilePhotoUrl,
        'categoryIds': categoryIds,
        'skills': skills,
      },
    );
    return result.fold(
      (f) => Left(f),
      (data) {
        if (data == null) {
          return const Left(ServerFailure(message: 'Error al actualizar perfil'));
        }
        final map = data as Map<String, dynamic>;
        final rawSkillsU = map['skills'] as List<dynamic>? ?? [];
        final skillEntriesU = rawSkillsU.map((s) {
          final m = s as Map<String, dynamic>;
          return SkillEntry(
            id: m['skillId'] as int? ?? m['id'] as int? ?? 0,
            name: m['skillName'] as String? ?? '',
            level: m['level'] as int? ?? 3,
          );
        }).where((e) => e.id > 0).toList();
        final rawCatsU = map['categories'] as List<dynamic>? ?? [];
        final firstCatU = rawCatsU.firstOrNull as Map<String, dynamic>?;
        final firstCategoryU = firstCatU?['name'] as String?;
        final primaryCategoryIdU = firstCatU?['id'] as int?;
        final sen = map['seniority'] as String? ?? '';
        final years = map['experienceYears'] as int? ?? 0;
        return Right(CandidateProfile(
          userId: map['userId'].toString(),
          name: map['fullName'] as String,
          email: map['email'] as String,
          headline: [
            if (sen.isNotEmpty) _capitalize(sen),
            if (firstCategoryU != null) firstCategoryU,
            if (years > 0) '${years}y exp',
          ].join(' · '),
          skillEntries: skillEntriesU,
          experience: const [],
          education: const [],
          matchScore: 0,
          profileStrength: (map['profileCompleted'] as bool? ?? false) ? 100 : 40,
          pendingTests: 0,
          activeApplications: 0,
          primaryCategoryId: primaryCategoryIdU,
          avatarUrl: map['profilePhotoUrl'] as String?,
          location: null,
          bio: null,
          githubUrl: map['githubLink'] as String?,
          linkedinUrl: map['linkedinUrl'] as String?,
          seniority: sen.isNotEmpty ? sen : null,
          englishLevel: map['englishLevel'] as String?,
          experienceYears: years > 0 ? years : null,
        ));
      },
    );
  }

  @override
  ResultFuture<List<JobOffer>> getCandidateMatches() async =>
      const Right([]);

  @override
  ResultFuture<List<JobOffer>> getJobOffers() async => const Right([]);

  @override
  ResultFuture<List<TechnicalTest>> getPendingTests() async {
    final result = await _client.get(ApiConstants.candidateTests);
    return result.fold(
      (f) => Left(f),
      (data) {
        final list = data as List<dynamic>? ?? [];
        return Right(list
            .map((t) => _parseCandidateTest(t as Map<String, dynamic>))
            .toList());
      },
    );
  }

  TechnicalTest _parseCandidateTest(Map<String, dynamic> t) {
    final startedAt = t['startedAt'];
    final statusStr = t['status'] as String? ?? 'Pending';
    final status = switch (statusStr) {
      'Pending' =>
        startedAt != null ? TestStatus.inProgress : TestStatus.pending,
      'Evaluated' => TestStatus.completed,
      'Expired' => TestStatus.expired,
      _ => TestStatus.pending,
    };
    final deadline = t['deadline'] != null
        ? DateTime.tryParse(t['deadline'] as String) ??
            DateTime.now().add(const Duration(days: 7))
        : DateTime.now().add(const Duration(days: 7));
    final scoreRaw = t['score'];
    return TechnicalTest(
      id: (t['testId'] ?? '0').toString(),
      title: t['testTitle'] as String? ??
          t['offerTitle'] as String? ??
          'Technical Assessment',
      durationMinutes: t['timeLimitMinutes'] as int? ?? 60,
      dueDate: deadline,
      status: status,
      iconType: 'terminal',
      offerId: t['offerId'] as int?,
      score: scoreRaw != null ? (scoreRaw as num).round() : null,
    );
  }

  @override
  ResultFuture<List<ActivityItem>> getActivityTimeline() async =>
      const Right([]);

  @override
  ResultFuture<TestPreview> getTestPreview(int offerId) async {
    final result =
        await _client.get('/api/tests/$offerId/candidate/preview');
    return result.fold(
      (f) => Left(f),
      (data) {
        if (data == null) {
          return const Left(ServerFailure(message: 'Preview no disponible'));
        }
        final map = data as Map<String, dynamic>;
        return Right(TestPreview(
          testId: map['testId'] as int? ?? 0,
          title: map['title'] as String? ?? 'Technical Assessment',
          timeLimitMinutes: map['timeLimitMinutes'] as int? ?? 60,
          totalQuestions: map['totalQuestions'] as int? ?? 0,
          multipleChoiceCount: map['multipleChoiceCount'] as int? ?? 0,
          codeChallengeCount: map['codeChallengeCount'] as int? ?? 0,
        ));
      },
    );
  }

  @override
  ResultFuture<TestSession> startCandidateTest(int offerId) async {
    final result = await _client.post('/api/tests/$offerId/candidate/start');
    return result.fold(
      (f) => Left(f),
      (data) {
        if (data == null) {
          return const Left(ServerFailure(message: 'No se pudo iniciar el test'));
        }
        final map = data as Map<String, dynamic>;
        // Response now wraps the test under 'test' and exposes 'submissionId' at root
        final submissionId = map['submissionId'] as int? ?? 0;
        final testMap = (map['test'] as Map<String, dynamic>?) ?? map;
        final questions = (testMap['questions'] as List<dynamic>? ?? [])
            .map((q) => _parseQuestion(q as Map<String, dynamic>))
            .toList();
        return Right(TestSession(
          testId: testMap['id'] as int,
          offerId: testMap['offerId'] as int,
          title: testMap['title'] as String,
          timeLimitMinutes: testMap['timeLimitMinutes'] as int? ?? 60,
          submissionId: submissionId,
          questions: questions,
        ));
      },
    );
  }

  @override
  ResultFuture<TestResult> submitCandidateTest(
    int testId,
    List<AnswerItem> answers,
  ) async {
    final result = await _client.post(
      '/api/tests/$testId/submit',
      body: {'answers': answers.map((a) => a.toJson()).toList()},
    );
    return result.fold(
      (f) => Left(f),
      (data) {
        if (data == null) {
          return const Left(ServerFailure(message: 'Error al enviar respuestas'));
        }
        final map = data as Map<String, dynamic>;
        return Right(TestResult(
          score: (map['score'] as num?)?.toDouble(),
          feedback: map['feedback'] as String?,
          status: map['status'] as String? ?? 'Submitted',
          submittedAt: map['submittedAt'] != null
              ? DateTime.tryParse(map['submittedAt'] as String)
              : null,
        ));
      },
    );
  }

  @override
  ResultFuture<TestResult> getTestResult(int testId) async {
    final result = await _client.get(ApiConstants.testResult(testId));
    return result.fold(
      (f) => Left(f),
      (data) {
        if (data == null) {
          return const Left(ServerFailure(message: 'Resultado no disponible'));
        }
        final map = data as Map<String, dynamic>;
        return Right(TestResult(
          score: (map['score'] as num?)?.toDouble(),
          feedback: map['feedback'] as String?,
          status: map['status'] as String? ?? 'Evaluated',
          submittedAt: map['submittedAt'] != null
              ? DateTime.tryParse(map['submittedAt'] as String)
              : null,
        ));
      },
    );
  }

  TestQuestion _parseQuestion(Map<String, dynamic> q) {
    Map<String, String>? options;
    final rawOptions = q['options'] as Map<String, dynamic>?;
    if (rawOptions != null) {
      options = rawOptions.map((k, v) => MapEntry(k, v.toString()));
    }
    return TestQuestion(
      id: q['id'] as int,
      orderIndex: q['orderIndex'] as int? ?? 0,
      questionType: q['questionType'] as String? ?? 'MultipleChoice',
      questionText: q['questionText'] as String,
      options: options,
      language: q['language'] as String?,
      functionSignature: q['functionSignature'] as String?,
      exampleInput: q['exampleInput'] as String?,
      expectedBehavior: q['expectedBehavior'] as String?,
      correctAnswer: q['correctAnswer'] as String?,
      explanation: q['explanation'] as String?,
      isGorilla: q['isGorilla'] as bool? ?? false,
      gorillaHint: q['gorillaHint'] as String?,
    );
  }

  // ─── Company Dashboard ────────────────────────────────────────────────────

  @override
  ResultFuture<CompanyDashboardStats> getCompanyDashboard() async {
    final result = await _client.get(ApiConstants.companyDashboard);
    return result.fold(
      (f) => Left(f),
      (data) {
        if (data == null) {
          return const Left(
              ServerFailure(message: 'Dashboard no disponible'));
        }
        final map = data as Map<String, dynamic>;

        final o = map['offers'] as Map<String, dynamic>? ?? {};
        final m = map['matches'] as Map<String, dynamic>? ?? {};
        final t = map['tests'] as Map<String, dynamic>? ?? {};

        return Right(CompanyDashboardStats(
          offers: CompanyDashboardOffers(
            total: o['total'] as int? ?? 0,
            open: o['open'] as int? ?? 0,
            testSent: o['testSent'] as int? ?? 0,
            completed: o['completed'] as int? ?? 0,
            cancelled: o['cancelled'] as int? ?? 0,
            expired: o['expired'] as int? ?? 0,
            pendingPayment: o['pendingPayment'] as int? ?? 0,
          ),
          matches: CompanyDashboardMatches(
            total: m['total'] as int? ?? 0,
            testSent: m['testSent'] as int? ?? 0,
            testCompleted: m['testCompleted'] as int? ?? 0,
            selected: m['selected'] as int? ?? 0,
            rejected: m['rejected'] as int? ?? 0,
            selectionRate:
                (m['selectionRate'] as num?)?.toDouble() ?? 0.0,
          ),
          tests: CompanyDashboardTests(
            sent: t['sent'] as int? ?? 0,
            completed: t['completed'] as int? ?? 0,
            evaluated: t['evaluated'] as int? ?? 0,
            expired: t['expired'] as int? ?? 0,
            completionRate:
                (t['completionRate'] as num?)?.toDouble() ?? 0.0,
            averageScore: (t['averageScore'] as num?)?.toDouble(),
          ),
        ));
      },
    );
  }

  // ─── Company Profile ──────────────────────────────────────────────────────

  @override
  ResultFuture<CompanyProfile> getCompanyProfile() async {
    final result = await _client.get(ApiConstants.companyProfile);
    return result.fold(
      (f) => Left(f),
      (data) {
        if (data == null) {
          return const Left(ServerFailure(message: 'Perfil de empresa no encontrado'));
        }
        return Right(_parseCompanyProfile(data as Map<String, dynamic>));
      },
    );
  }

  @override
  ResultVoid updateCompanyProfile(String companyName) async {
    final result = await _client.put(
      ApiConstants.companyProfile,
      body: {'companyName': companyName},
    );
    return result.fold((f) => Left(f), (_) => const Right(null));
  }

  CompanyProfile _parseCompanyProfile(Map<String, dynamic> map) {
    return CompanyProfile(
      userId: map['userId'].toString(),
      companyName: map['companyName'] as String? ??
          map['fullName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      profileCompleted: map['profileCompleted'] as bool? ?? false,
    );
  }

  // ─── Company Offers ───────────────────────────────────────────────────────

  @override
  ResultFuture<List<OfferTier>> getOfferTiers() async {
    final result = await _client.get(ApiConstants.offerTiers);
    return result.fold(
      (f) => Left(f),
      (data) {
        final list = data as List<dynamic>? ?? [];
        return Right(list
            .map((t) => OfferTier(
                  id: t['id'] as int,
                  name: t['name'] as String,
                  minCandidates: t['minCandidates'] as int,
                  maxCandidates: t['maxCandidates'] as int,
                  priceCop: t['priceCop'] as int,
                ))
            .toList());
      },
    );
  }

  @override
  ResultFuture<AiParseResult> parseOfferDescription(
      String rawDescription) async {
    final result = await _client.post(
      ApiConstants.parseDescription,
      body: {'rawDescription': rawDescription},
    );
    return result.fold(
      (f) => Left(f),
      (data) {
        if (data == null) {
          return const Left(
              ServerFailure(message: 'Could not parse the description'));
        }
        final map = data as Map<String, dynamic>;
        return Right(AiParseResult(
          title: map['title'] as String?,
          modality: map['modality'] as String?,
          salary: map['salary'] != null ? (map['salary'] as num).toInt() : null,
          minExperienceYears: map['minExperienceYears'] as int?,
          requiredEnglishLevel: map['requiredEnglishLevel'] as String?,
          suggestedCategoryIds: (map['suggestedCategoryIds'] as List<dynamic>? ?? [])
              .cast<int>(),
          suggestedSkillIds: (map['suggestedSkillIds'] as List<dynamic>? ?? [])
              .cast<int>(),
          confidenceNote: map['confidenceNote'] as String?,
        ));
      },
    );
  }

  @override
  ResultFuture<JobOffer> createOffer(CreateOfferInput input) async {
    final result = await _client.post(
      ApiConstants.offers,
      body: {
        'title': input.title,
        'description': input.description,
        if (input.salary != null) 'salary': input.salary,
        'modality': input.modality,
        if (input.minExperienceYears != null)
          'minExperienceYears': input.minExperienceYears,
        if (input.requiredEnglishLevel != null)
          'requiredEnglishLevel': input.requiredEnglishLevel,
        'positionsAvailable': input.positionsAvailable,
        'tierId': input.tierId,
        'testDeadlineDays': input.testDeadlineDays,
        'categoryIds': input.categoryIds,
        'skillIds': input.skillIds,
      },
    );
    return result.fold(
      (f) => Left(f),
      (data) {
        if (data == null) {
          return const Left(ServerFailure(message: 'Error al crear la oferta'));
        }
        return Right(_parseOffer(data as Map<String, dynamic>));
      },
    );
  }

  @override
  ResultFuture<List<JobOffer>> getCompanyOffers() async {
    final result = await _client.get(ApiConstants.offers);
    return result.fold(
      (f) => Left(f),
      (data) {
        final list = data as List<dynamic>? ?? [];
        return Right(list
            .map((o) => _parseOffer(o as Map<String, dynamic>))
            .toList());
      },
    );
  }

  @override
  ResultFuture<JobOffer> getOfferById(int offerId) async {
    final result = await _client.get(ApiConstants.offerById(offerId));
    return result.fold(
      (f) => Left(f),
      (data) {
        if (data == null) {
          return const Left(ServerFailure(message: 'Oferta no encontrada'));
        }
        return Right(_parseOffer(data as Map<String, dynamic>));
      },
    );
  }

  @override
  ResultFuture<CheckoutResult> createCheckout(int offerId) async {
    final result = await _client
        .post('${ApiConstants.createCheckout}?offerId=$offerId');
    return result.fold(
      (f) => Left(f),
      (data) {
        if (data == null) {
          return const Left(ServerFailure(message: 'No se pudo crear el link de pago'));
        }
        // ApiClient already extracts body['data'], so 'data' is { url, activated }
        final map = data as Map<String, dynamic>;
        final activated = map['activated'] as bool? ?? false;
        final url = map['url'] as String?;
        return Right(CheckoutResult(url: url, activated: activated));
      },
    );
  }

  @override
  ResultFuture<bool> verifySession(String sessionId) async {
    final result = await _client
        .post('${ApiConstants.verifySession}?sessionId=$sessionId');
    return result.fold(
      (f) => Left(f),
      (data) {
        if (data == null) return const Right(false);
        // ApiClient already extracts body['data'], so 'data' is { activated }
        final map = data as Map<String, dynamic>;
        final activated = map['activated'] as bool? ?? false;
        return Right(activated);
      },
    );
  }

  JobOffer _parseOffer(Map<String, dynamic> m) {
    final salaryRaw = m['salary'];
    final skills = (m['skills'] as List<dynamic>? ?? [])
        .map((s) => s['name'] as String)
        .toList();
    final categoryIds = (m['categories'] as List<dynamic>? ?? [])
        .map((c) => c['id'] as int)
        .toList();
    final skillIds = (m['skills'] as List<dynamic>? ?? [])
        .map((s) => s['id'] as int)
        .toList();
    return JobOffer(
      id: m['id'].toString(),
      title: m['title'] as String,
      companyName: m['companyName'] as String? ?? '',
      companyLogoUrl: '',
      salary: salaryRaw != null
          ? '\$${(salaryRaw as num).toStringAsFixed(0)}'
          : 'No especificado',
      type: OfferType.fullTime,
      mode: _parseModality(m['modality'] as String? ?? 'remote'),
      skills: skills,
      description: m['description'] as String? ?? '',
      postedAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ??
          DateTime.now(),
      isActive: m['status'] == 'Open' || m['status'] == 'TestSent',
      status: m['status'] as String?,
      tierId: m['tierId'] as int?,
      tierName: m['tierName'] as String?,
      tierPriceCop: m['tierPriceCop'] != null
          ? (m['tierPriceCop'] as num).toInt()
          : null,
      checkoutUrl: m['checkoutUrl'] as String?,
      minExperienceYears: m['minExperienceYears'] as int?,
      requiredEnglishLevel: m['requiredEnglishLevel'] as String?,
      positionsAvailable: m['positionsAvailable'] as int? ?? 1,
      categoryIds: categoryIds,
      skillIds: skillIds,
      testDeadlineDays: m['testDeadlineDays'] as int?,
    );
  }

  // ─── Company Matching ─────────────────────────────────────────────────────

  @override
  ResultFuture<List<CandidateMatch>> getCompanyMatches() async {
    final offersResult = await _client.get(ApiConstants.offers);
    return offersResult.fold(
      (f) => Left(f),
      (data) async {
        final offersList = data as List<dynamic>? ?? [];
        if (offersList.isEmpty) return const Right([]);

        final firstActiveOffer = offersList.firstWhere(
          (o) => o['status'] == 'Open' || o['status'] == 'TestSent',
          orElse: () => offersList.first,
        );
        final offerId = firstActiveOffer['id'] as int;
        final offerTitle = firstActiveOffer['title'] as String;

        final matchesResult =
            await _client.get(ApiConstants.matchingByOffer(offerId));
        return matchesResult.fold(
          (f) => const Right(<CandidateMatch>[]),
          (matchData) {
            final matchList = matchData as List<dynamic>? ?? [];
            return Right(matchList
                .map((m) => _parseMatch(
                    m as Map<String, dynamic>, offerId.toString(), offerTitle))
                .toList());
          },
        );
      },
    );
  }

  @override
  ResultFuture<List<CandidateMatch>> getMatchesByOffer(int offerId) async {
    final offerTitle = await _fetchOfferTitle(offerId);
    final result = await _client.get(ApiConstants.matchingByOffer(offerId));
    return result.fold(
      (f) => Left(f),
      (data) {
        final list = data as List<dynamic>? ?? [];
        return Right(list
            .map((m) =>
                _parseMatch(m as Map<String, dynamic>, offerId.toString(), offerTitle))
            .toList());
      },
    );
  }

  CandidateMatch _parseMatch(
    Map<String, dynamic> m,
    String offerId,
    String offerTitle,
  ) {
    final skills =
        (m['matchedSkills'] as List<dynamic>? ?? []).cast<String>();
    final stage = m['stage'] as String? ?? 'Matched';
    final experienceYears = m['experienceYears'] as int? ?? 0;
    final englishLevel = m['englishLevel'] as String? ?? '';
    return CandidateMatch(
      matchId: m['matchId'] as int? ?? 0,
      candidateId: m['candidateId'].toString(),
      candidateName: m['fullName'] as String? ?? 'Unknown',
      headline: [
        if (englishLevel.isNotEmpty) englishLevel,
        if (experienceYears > 0) '${experienceYears}y exp',
      ].join(' · '),
      matchScore: (m['matchPercentage'] as num? ?? 0).round(),
      adjustedScore: m['adjustedScore'] != null
          ? (m['adjustedScore'] as num).toDouble()
          : null,
      skills: skills,
      offerId: offerId,
      offerTitle: offerTitle,
      email: m['email'] as String?,
      testScore: m['testScore'] != null
          ? (m['testScore'] as num).round()
          : null,
      testFeedback: m['testFeedback'] as String?,
      aiInsight: m['aiInsight'] as String?,
      aiStrengths: (m['aiStrengths'] as List<dynamic>? ?? []).cast<String>(),
      aiOpportunities:
          (m['aiOpportunities'] as List<dynamic>? ?? []).cast<String>(),
      aiRecommendation: m['aiRecommendation'] as String?,
      status: _parseStage(stage),
    );
  }

  @override
  ResultFuture<List<CandidateMatch>> runMatching(int offerId) async {
    final offerTitle = await _fetchOfferTitle(offerId);
    final result = await _client.post(ApiConstants.runMatching(offerId));
    return result.fold(
      (f) => Left(f),
      (data) {
        final list = data as List<dynamic>? ?? [];
        return Right(list
            .map((m) => _parseMatch(m as Map<String, dynamic>, offerId.toString(), offerTitle))
            .toList());
      },
    );
  }

  @override
  ResultFuture<List<CandidateMatch>> reevaluateMatching(int offerId) async {
    final offerTitle = await _fetchOfferTitle(offerId);
    final result = await _client.post(ApiConstants.reevaluateMatching(offerId));
    return result.fold(
      (f) => Left(f),
      (data) {
        final list = data as List<dynamic>? ?? [];
        return Right(list
            .map((m) => _parseMatch(m as Map<String, dynamic>, offerId.toString(), offerTitle))
            .toList());
      },
    );
  }

  Future<String> _fetchOfferTitle(int offerId) async {
    final r = await _client.get(ApiConstants.offerById(offerId));
    return r.fold(
      (_) => 'Offer #$offerId',
      (data) => (data as Map<String, dynamic>?)?['title'] as String? ?? 'Offer #$offerId',
    );
  }

  @override
  ResultVoid sendTests(List<int> matchIds) async {
    final result = await _client.post(
      ApiConstants.sendTest,
      body: {'matchIds': matchIds},
    );
    return result.fold((f) => Left(f), (_) => const Right(null));
  }

  @override
  ResultFuture<CandidateMatch> selectCandidate(int matchId) async {
    final result =
        await _client.post(ApiConstants.selectCandidate(matchId));
    return result.fold(
      (f) => Left(f),
      (data) {
        if (data == null) {
          return const Left(ServerFailure(message: 'Error al seleccionar candidato'));
        }
        final map = data as Map<String, dynamic>;
        // The response is the updated match object
        return Right(_parseMatch(map, '', ''));
      },
    );
  }

  @override
  ResultVoid rejectCandidate(int matchId) async {
    final result =
        await _client.post(ApiConstants.rejectCandidate(matchId));
    return result.fold((f) => Left(f), (_) => const Right(null));
  }

  // ─── Company Tests ────────────────────────────────────────────────────────

  @override
  ResultFuture<MatchTestSubmission> getTestSubmission(int matchId) async {
    final result =
        await _client.get(ApiConstants.testSubmissionsByMatch(matchId));
    return result.fold(
      (f) => Left(f),
      (data) {
        if (data == null) {
          return const Left(
              ServerFailure(message: 'Submission no encontrada'));
        }
        final map = data as Map<String, dynamic>;
        final questions = (map['questions'] as List<dynamic>? ?? [])
            .map((q) => _parseSubmissionQuestion(q as Map<String, dynamic>))
            .toList();
        return Right(MatchTestSubmission(
          matchId: map['matchId'] as int? ?? matchId,
          candidateName: map['candidateFullName'] as String? ??
              map['candidateName'] as String? ?? 'Candidato',
          status: map['status'] as String? ?? 'Evaluated',
          score: (map['score'] as num?)?.toDouble(),
          globalFeedback: map['globalFeedback'] as String?,
          submittedAt: map['submittedAt'] != null
              ? DateTime.tryParse(map['submittedAt'] as String)
              : null,
          aiEvaluatedAt: map['aiEvaluatedAt'] != null
              ? DateTime.tryParse(map['aiEvaluatedAt'] as String)
              : null,
          questions: questions,
        ));
      },
    );
  }

  SubmissionQuestion _parseSubmissionQuestion(Map<String, dynamic> q) {
    Map<String, String>? options;
    final rawOptions = q['options'] as Map<String, dynamic>?;
    if (rawOptions != null) {
      options = rawOptions.map((k, v) => MapEntry(k, v.toString()));
    }
    return SubmissionQuestion(
      id: q['questionId'] as int? ?? q['id'] as int? ?? 0,
      orderIndex: q['orderIndex'] as int? ?? 0,
      questionType: q['questionType'] as String? ?? 'MultipleChoice',
      questionText: q['questionText'] as String? ?? '',
      options: options,
      functionSignature: q['functionSignature'] as String?,
      expectedBehavior: q['expectedBehavior'] as String?,
      correctAnswer: q['correctAnswer'] as String?,
      selectedOption: q['selectedOption'] as String?,
      codeSubmitted: q['codeSubmitted'] as String?,
      isCorrect: q['isCorrect'] as bool?,
      aiFeedback: q['aiFeedback'] as String?,
    );
  }

  @override
  ResultFuture<Uint8List> downloadCompanyReport() async {
    final result = await _client.getBytes(ApiConstants.companyReport);
    return result.fold((f) => Left(f), (bytes) => Right(bytes));
  }

  @override
  ResultFuture<ProctoringReport> getProctoringReport(int matchId) async {
    final result =
        await _client.get(ApiConstants.proctoringReportByMatch(matchId));
    return result.fold(
      (f) => Left(f),
      (data) {
        if (data == null) {
          return const Left(
              ServerFailure(message: 'Reporte de proctoring no encontrado'));
        }
        final map = data as Map<String, dynamic>;
        final eventos = (map['eventos'] as List<dynamic>? ?? [])
            .map((e) {
              final ev = e as Map<String, dynamic>;
              return ProctoringEvent(
                tipo: ev['tipo'] as String? ?? '',
                detalle: ev['detalle'] as String?,
                evidencia: ev['evidencia'] as String?,
                timestamp: DateTime.tryParse(ev['timestamp'] as String? ?? '') ??
                    DateTime.now(),
              );
            })
            .toList();
        return Right(ProctoringReport(
          sessionId: map['sessionId'] as String? ?? '',
          inicio: DateTime.tryParse(map['inicio'] as String? ?? '') ??
              DateTime.now(),
          fin: DateTime.tryParse(map['fin'] as String? ?? '') ?? DateTime.now(),
          totalFramesProcesados: map['totalFramesProcesados'] as int? ?? 0,
          totalEventos: map['totalEventos'] as int? ?? 0,
          integrityScore: (map['integrityScore'] as num?)?.toDouble() ?? 100.0,
          integritySummary: map['integritySummary'] as String?,
          eventos: eventos,
        ));
      },
    );
  }

  @override
  ResultFuture<TestSession> generateTest(int offerId, int timeLimitMinutes) async {
    final result = await _client.post(
      ApiConstants.generateTest(offerId),
      body: {'timeLimitMinutes': timeLimitMinutes},
    );
    return result.fold(
      (f) => Left(f),
      (data) {
        if (data == null) {
          return const Left(ServerFailure(message: 'Error al generar test'));
        }
        final map = data as Map<String, dynamic>;
        final questions = (map['questions'] as List<dynamic>? ?? [])
            .map((q) => _parseQuestion(q as Map<String, dynamic>))
            .toList();
        return Right(TestSession(
          testId: map['id'] as int,
          offerId: map['offerId'] as int,
          title: map['title'] as String? ?? 'Technical Test',
          timeLimitMinutes: map['timeLimitMinutes'] as int? ?? 60,
          questions: questions,
        ));
      },
    );
  }

  @override
  ResultFuture<TestSession?> getTestByOffer(int offerId) async {
    final result = await _client.get(ApiConstants.testByOffer(offerId));
    return result.fold(
      (f) {
        if (f is ServerFailure && f.statusCode == 404) {
          return const Right(null);
        }
        return Left(f);
      },
      (data) {
        if (data == null) return const Right(null);
        final map = data as Map<String, dynamic>;
        final questions = (map['questions'] as List<dynamic>? ?? [])
            .map((q) => _parseQuestion(q as Map<String, dynamic>))
            .toList();
        return Right(TestSession(
          testId: map['id'] as int,
          offerId: map['offerId'] as int,
          title: map['title'] as String? ?? 'Technical Test',
          timeLimitMinutes: map['timeLimitMinutes'] as int? ?? 60,
          questions: questions,
        ));
      },
    );
  }

  @override
  ResultFuture<TestSession> regenerateTest(int offerId, int timeLimitMinutes) async {
    final result = await _client.post(
      ApiConstants.regenerateTest(offerId),
      body: {'timeLimitMinutes': timeLimitMinutes},
    );
    return result.fold(
      (f) => Left(f),
      (data) {
        if (data == null) {
          return const Left(ServerFailure(message: 'Error al regenerar test'));
        }
        final map = data as Map<String, dynamic>;
        final questions = (map['questions'] as List<dynamic>? ?? [])
            .map((q) => _parseQuestion(q as Map<String, dynamic>))
            .toList();
        return Right(TestSession(
          testId: map['id'] as int,
          offerId: map['offerId'] as int,
          title: map['title'] as String? ?? 'Technical Test',
          timeLimitMinutes: map['timeLimitMinutes'] as int? ?? 60,
          questions: questions,
        ));
      },
    );
  }

  @override
  ResultFuture<ChatResult> chatWithQuestion(int questionId, String message) async {
    final result = await _client.post(
      ApiConstants.questionChat(questionId),
      body: {'message': message},
    );
    return result.fold(
      (f) => Left(f),
      (data) {
        if (data == null) {
          return const Left(ServerFailure(message: 'Empty response'));
        }
        final map = data as Map<String, dynamic>;
        final updatedQ =
            _parseQuestion(map['updatedQuestion'] as Map<String, dynamic>);
        return Right(ChatResult(
          updatedQuestion: updatedQ,
          assistantMessage: map['assistantMessage'] as String? ?? '',
        ));
      },
    );
  }

  @override
  ResultFuture<JobOffer> updateOffer(
      int offerId, Map<String, dynamic> fields) async {
    final result =
        await _client.put(ApiConstants.offerById(offerId), body: fields);
    return result.fold(
      (f) => Left(f),
      (data) {
        if (data == null) {
          return const Left(
              ServerFailure(message: 'Error al actualizar oferta'));
        }
        return Right(_parseOffer(data as Map<String, dynamic>));
      },
    );
  }

  // ─── Admin ────────────────────────────────────────────────────────────────

  @override
  ResultFuture<AdminStats> getAdminStats() async {
    final result = await _client.get(ApiConstants.adminStats);
    return result.fold(
      (f) => Left(f),
      (data) {
        if (data == null) {
          return const Left(ServerFailure(message: 'Statistics not available'));
        }
        final m = data as Map<String, dynamic>;
        final byStatus =
            (m['offersByStatus'] as Map<String, dynamic>? ?? {})
                .map((k, v) => MapEntry(k, (v as num).toInt()));
        return Right(AdminStats(
          totalCandidates: m['totalCandidates'] as int? ?? 0,
          totalCompanies: m['totalCompanies'] as int? ?? 0,
          usersRegisteredLast30Days: m['usersRegisteredLast30Days'] as int? ?? 0,
          totalOffers: m['totalOffers'] as int? ?? 0,
          offersCreatedLast30Days: m['offersCreatedLast30Days'] as int? ?? 0,
          offersActive: m['offersActive'] as int? ?? 0,
          offersCompleted: m['offersCompleted'] as int? ?? 0,
          offersCancelled: m['offersCancelled'] as int? ?? 0,
          offersExpired: m['offersExpired'] as int? ?? 0,
          offersPendingPayment: m['offersPendingPayment'] as int? ?? 0,
          offersByStatus: byStatus,
          totalMatches: m['totalMatches'] as int? ?? 0,
          matchesSelected: m['matchesSelected'] as int? ?? 0,
          matchesRejected: m['matchesRejected'] as int? ?? 0,
          matchesTestSent: m['matchesTestSent'] as int? ?? 0,
          matchesTestCompleted: m['matchesTestCompleted'] as int? ?? 0,
          activeTests: m['activeTests'] as int? ?? 0,
          pendingSubmissions: m['pendingSubmissions'] as int? ?? 0,
          submissionsEvaluated: m['submissionsEvaluated'] as int? ?? 0,
          submissionsExpired: m['submissionsExpired'] as int? ?? 0,
          averageTestScore: (m['averageTestScore'] as num? ?? 0).toDouble(),
          totalRevenueCop: (m['totalRevenueCop'] as num? ?? 0).toDouble(),
          paymentsCompleted: m['paymentsCompleted'] as int? ?? 0,
          paymentsPending: m['paymentsPending'] as int? ?? 0,
          testCompletionRate: (m['testCompletionRate'] as num? ?? 0).toDouble(),
          selectionRate: (m['selectionRate'] as num? ?? 0).toDouble(),
        ));
      },
    );
  }

  @override
  ResultFuture<List<AdminUser>> getAdminUsers(
      {String? role, bool? isActive}) async {
    final params = <String, String>{};
    if (role != null) params['role'] = role;
    if (isActive != null) params['isActive'] = isActive.toString();
    final query =
        params.isEmpty ? '' : '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    final result =
        await _client.get('${ApiConstants.adminUsers}$query');
    return result.fold(
      (f) => Left(f),
      (data) {
        final list = data as List<dynamic>? ?? [];
        return Right(list
            .map((u) => _parseAdminUser(u as Map<String, dynamic>))
            .toList());
      },
    );
  }

  @override
  ResultFuture<AdminUser> getAdminUserById(int userId) async {
    final result = await _client.get(ApiConstants.adminUserById(userId));
    return result.fold(
      (f) => Left(f),
      (data) {
        if (data == null) {
          return Left(ServerFailure(message: 'Usuario $userId no encontrado.'));
        }
        return Right(_parseAdminUser(data as Map<String, dynamic>));
      },
    );
  }

  @override
  ResultVoid createAdminUser({
    required String fullName,
    required String email,
    required String cedula,
    required String password,
    required String confirmPassword,
  }) async {
    final result = await _client.post(ApiConstants.adminUsers, body: {
      'fullName': fullName,
      'email': email,
      'cedula': cedula,
      'password': password,
      'confirmPassword': confirmPassword,
    });
    return result.fold((f) => Left(f), (_) => const Right(null));
  }

  @override
  ResultFuture<AdminUser> toggleUserStatus(int userId) async {
    final result =
        await _client.patch(ApiConstants.toggleUserStatus(userId));
    return result.fold(
      (f) => Left(f),
      (data) {
        if (data == null) {
          return const Left(ServerFailure(message: 'Error al cambiar estado'));
        }
        return Right(_parseAdminUser(data as Map<String, dynamic>));
      },
    );
  }

  @override
  ResultVoid deleteUser(int userId) async {
    final result = await _client.delete(ApiConstants.deleteUser(userId));
    return result.fold((f) => Left(f), (_) => const Right(null));
  }

  @override
  ResultFuture<List<int>> downloadAdminReport() async {
    final result = await _client.getBytes(ApiConstants.adminReport);
    return result.fold(
      (f) => Left(f),
      (bytes) => Right(bytes.toList()),
    );
  }

  AdminUser _parseAdminUser(Map<String, dynamic> m) {
    return AdminUser(
      id: m['id'] as int,
      email: m['email'] as String? ?? '',
      fullName: m['fullName'] as String? ?? '',
      cedula: m['cedula'] as String? ?? '',
      role: m['role'] as String,
      isActive: m['isActive'] as bool? ?? true,
      emailVerified: m['emailVerified'] as bool? ?? false,
      createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ??
          DateTime.now(),
      profileName: m['profileName'] as String?,
    );
  }

  // ─── Analytics ────────────────────────────────────────────────────────────

  @override
  ResultFuture<MarketAnalytics> getMarketAnalytics() async {
    final result = await _client.get(ApiConstants.analyticsMarket, skipAuth: true);
    return result.fold((f) => Left(f), (data) => Right(_parseMarketAnalytics(data)));
  }

  @override
  ResultFuture<MarketAnalytics> getCandidateInsights() async {
    final result = await _client.get(ApiConstants.analyticsMyInsights);
    return result.fold((f) => Left(f), (data) => Right(_parseMarketAnalytics(data)));
  }

  MarketAnalytics _parseMarketAnalytics(dynamic raw) {
    final map = raw as Map<String, dynamic>;

    final demand = (map['topDemand'] as List<dynamic>? ?? []).map((e) {
      final m = e as Map<String, dynamic>;
      return MarketSkillDemand(
        skillName: m['skillName'] as String,
        categoryName: m['categoryName'] as String,
        offerCount: m['offerCount'] as int,
        candidateHasSkill: m['candidateHasSkill'] as bool?,
        candidateLevel: m['candidateLevel'] as int?,
      );
    }).toList();

    final supply = (map['topSupply'] as List<dynamic>? ?? []).map((e) {
      final m = e as Map<String, dynamic>;
      return MarketSkillSupply(
        skillName: m['skillName'] as String,
        categoryName: m['categoryName'] as String,
        candidateCount: m['candidateCount'] as int,
      );
    }).toList();

    final combinations = (map['topCombinations'] as List<dynamic>? ?? []).map((e) {
      final m = e as Map<String, dynamic>;
      return MarketSkillCombination(
        skillA: m['skillA'] as String,
        skillB: m['skillB'] as String,
        offerCount: m['offerCount'] as int,
        candidateHasA: m['candidateHasA'] as bool?,
        candidateHasB: m['candidateHasB'] as bool?,
        candidateHasBoth: m['candidateHasBoth'] as bool?,
      );
    }).toList();

    final skillsInDemand = (map['skillsInDemand'] as List<dynamic>? ?? [])
        .map((e) => e as String)
        .toList();
    final skillGaps = (map['skillGaps'] as List<dynamic>? ?? [])
        .map((e) => e as String)
        .toList();

    return MarketAnalytics(
      topDemand: demand,
      topSupply: supply,
      topCombinations: combinations,
      skillsInDemand: skillsInDemand,
      skillGaps: skillGaps,
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  OfferMode _parseModality(String modality) => switch (modality) {
        'remote' => OfferMode.remote,
        'hybrid' => OfferMode.hybrid,
        'onsite' => OfferMode.onSite,
        _ => OfferMode.remote,
      };

  MatchStatus _parseStage(String stage) => switch (stage) {
        'Matched' => MatchStatus.new_,
        'TestSent' => MatchStatus.testSent,
        'TestCompleted' => MatchStatus.testCompleted,
        'Selected' => MatchStatus.shortlisted,
        'Rejected' => MatchStatus.rejected,
        _ => MatchStatus.new_,
      };

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
