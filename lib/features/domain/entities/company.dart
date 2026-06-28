import 'package:equatable/equatable.dart';

class CompanyProfile extends Equatable {
  const CompanyProfile({
    required this.userId,
    required this.companyName,
    required this.email,
    required this.fullName,
    required this.profileCompleted,
    this.activeOffers = 0,
    this.totalCandidates = 0,
    this.pendingMatches = 0,
  });

  final String userId;
  final String companyName;
  final String email;
  final String fullName;
  final bool profileCompleted;
  final int activeOffers;
  final int totalCandidates;
  final int pendingMatches;

  String get name => companyName;

  @override
  List<Object?> get props => [userId];
}

class CandidateMatch extends Equatable {
  const CandidateMatch({
    required this.matchId,
    required this.candidateId,
    required this.candidateName,
    required this.headline,
    required this.matchScore,
    required this.skills,
    required this.offerId,
    required this.offerTitle,
    this.avatarUrl,
    this.email,
    this.adjustedScore,
    this.testScore,
    this.testFeedback,
    this.aiInsight,
    this.aiStrengths = const [],
    this.aiOpportunities = const [],
    this.aiRecommendation,
    this.status = MatchStatus.new_,
  });

  final int matchId;
  final String candidateId;
  final String candidateName;
  final String headline;
  final int matchScore;
  final List<String> skills;
  final String offerId;
  final String offerTitle;
  final String? avatarUrl;
  final String? email;
  final double? adjustedScore;
  final int? testScore;
  final String? testFeedback;
  final String? aiInsight;
  final List<String> aiStrengths;
  final List<String> aiOpportunities;
  final String? aiRecommendation;
  final MatchStatus status;

  bool get canSendTest => status == MatchStatus.new_;
  bool get canSelect => status == MatchStatus.testCompleted && testScore != null;
  bool get canReject =>
      status == MatchStatus.new_ ||
      status == MatchStatus.testSent ||
      status == MatchStatus.testCompleted;

  @override
  List<Object?> get props => [matchId, candidateId, offerId];
}

enum MatchStatus { new_, testSent, testCompleted, shortlisted, rejected }
