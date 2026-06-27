import 'package:dartz/dartz.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/api/token_storage.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utils/typedef.dart';
import '../../domain/entities/activity.dart';
import '../../domain/entities/admin_stats.dart';
import '../../domain/entities/candidate.dart';
import '../../domain/entities/catalog.dart';
import '../../domain/entities/company.dart';
import '../../domain/entities/job_offer.dart';
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
        final skills = (map['skills'] as List<dynamic>? ?? [])
            .map((s) => s['skillName'] as String)
            .toList();
        final firstCategory = (map['categories'] as List<dynamic>? ?? [])
            .firstOrNull?['name'] as String?;
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
          skills: skills,
          experience: const [],
          education: const [],
          matchScore: 0,
          profileStrength: (map['profileCompleted'] as bool? ?? false) ? 100 : 40,
          pendingTests: 0,
          activeApplications: 0,
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
        final skillList = (map['skills'] as List<dynamic>? ?? [])
            .map((s) => s['skillName'] as String)
            .toList();
        final firstCategory = (map['categories'] as List<dynamic>? ?? [])
            .firstOrNull?['name'] as String?;
        final sen = map['seniority'] as String? ?? '';
        final years = map['experienceYears'] as int? ?? 0;
        return Right(CandidateProfile(
          userId: map['userId'].toString(),
          name: map['fullName'] as String,
          email: map['email'] as String,
          headline: [
            if (sen.isNotEmpty) _capitalize(sen),
            if (firstCategory != null) firstCategory,
            if (years > 0) '${years}y exp',
          ].join(' · '),
          skills: skillList,
          experience: const [],
          education: const [],
          matchScore: 0,
          profileStrength: (map['profileCompleted'] as bool? ?? false) ? 100 : 40,
          pendingTests: 0,
          activeApplications: 0,
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
        final questions = (map['questions'] as List<dynamic>? ?? [])
            .map((q) => _parseQuestion(q as Map<String, dynamic>))
            .toList();
        return Right(TestSession(
          testId: map['id'] as int,
          offerId: map['offerId'] as int,
          title: map['title'] as String,
          timeLimitMinutes: map['timeLimitMinutes'] as int? ?? 60,
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
              ServerFailure(message: 'No se pudo analizar la descripción'));
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
  ResultFuture<String> createCheckout(int offerId) async {
    final result = await _client
        .post('${ApiConstants.createCheckout}?offerId=$offerId');
    return result.fold(
      (f) => Left(f),
      (data) {
        if (data == null) {
          return const Left(ServerFailure(message: 'No se pudo crear el link de pago'));
        }
        final url = (data as Map<String, dynamic>)['url'] as String?;
        if (url == null) {
          return const Left(ServerFailure(message: 'URL de pago no disponible'));
        }
        return Right(url);
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
    // Get offer title first
    final offerResult = await _client.get(ApiConstants.offerById(offerId));
    String offerTitle = 'Offer #$offerId';
    if (offerResult.isRight()) {
      final offerData = offerResult.getOrElse(() => null);
      if (offerData != null) {
        offerTitle = (offerData as Map<String, dynamic>)['title'] as String? ??
            offerTitle;
      }
    }

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
      skills: skills,
      offerId: offerId,
      offerTitle: offerTitle,
      email: m['email'] as String?,
      testScore: m['adjustedScore'] != null
          ? (m['adjustedScore'] as num).round()
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
  ResultFuture<TestSession> generateTest(int offerId) async {
    final result =
        await _client.post(ApiConstants.generateTest(offerId));
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

  // ─── Admin ────────────────────────────────────────────────────────────────

  @override
  ResultFuture<AdminStats> getAdminStats() async {
    final result = await _client.get(ApiConstants.adminStats);
    return result.fold(
      (f) => Left(f),
      (data) {
        if (data == null) {
          return const Left(ServerFailure(message: 'Estadísticas no disponibles'));
        }
        final map = data as Map<String, dynamic>;
        return Right(AdminStats(
          totalCandidates: map['totalCandidates'] as int? ?? 0,
          totalCompanies: map['totalCompanies'] as int? ?? 0,
          totalOffers: map['totalOffers'] as int? ?? 0,
          totalMatches: map['totalMatches'] as int? ?? 0,
          activeTests: map['activeTests'] as int? ?? 0,
          pendingSubmissions: map['pendingSubmissions'] as int? ?? 0,
          usersLast30Days: map['usersRegisteredLast30Days'] as int? ?? 0,
          offersLast30Days: map['offersCreatedLast30Days'] as int? ?? 0,
        ));
      },
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
        'TestSent' => MatchStatus.reviewed,
        'TestCompleted' => MatchStatus.reviewed,
        'Selected' => MatchStatus.shortlisted,
        'Rejected' => MatchStatus.rejected,
        _ => MatchStatus.new_,
      };

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
