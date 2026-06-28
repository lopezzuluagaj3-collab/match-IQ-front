import 'package:equatable/equatable.dart';

enum OfferType { fullTime, partTime, contract, internship }
enum OfferMode { remote, hybrid, onSite }

class JobOffer extends Equatable {
  const JobOffer({
    required this.id,
    required this.title,
    required this.companyName,
    required this.companyLogoUrl,
    required this.salary,
    required this.type,
    required this.mode,
    required this.skills,
    required this.description,
    required this.postedAt,
    this.matchScore,
    this.isActive = true,
    // API fields
    this.status,
    this.tierId,
    this.tierName,
    this.tierPriceCop,
    this.checkoutUrl,
    this.minExperienceYears,
    this.requiredEnglishLevel,
    this.positionsAvailable = 1,
    this.categoryIds = const [],
    this.skillIds = const [],
    this.testDeadlineDays,
  });

  final String id;
  final String title;
  final String companyName;
  final String companyLogoUrl;
  final String salary;
  final OfferType type;
  final OfferMode mode;
  final List<String> skills;
  final String description;
  final DateTime postedAt;
  final int? matchScore;
  final bool isActive;

  // Extended API fields
  final String? status;
  final int? tierId;
  final String? tierName;
  final int? tierPriceCop;
  final String? checkoutUrl;
  final int? minExperienceYears;
  final String? requiredEnglishLevel;
  final int positionsAvailable;
  final List<int> categoryIds;
  final List<int> skillIds;
  final int? testDeadlineDays;

  bool get isPendingPayment => status == 'PendingPayment';
  bool get isOpen => status == 'Open';

  String get typeLabel => switch (type) {
        OfferType.fullTime => 'Full-time',
        OfferType.partTime => 'Part-time',
        OfferType.contract => 'Contract',
        OfferType.internship => 'Internship',
      };

  String get modeLabel => switch (mode) {
        OfferMode.remote => 'Remote',
        OfferMode.hybrid => 'Hybrid',
        OfferMode.onSite => 'On-site',
      };

  String get statusLabel => switch (status) {
        'PendingPayment' => 'Pending Payment',
        'Open' => 'Open',
        'TestSent' => 'Test Sent',
        'Completed' => 'Completed',
        'Cancelled' => 'Cancelled',
        'Expired' => 'Expired',
        _ => 'Active',
      };

  @override
  List<Object?> get props => [id, title, companyName];
}

// ─── Input for creating an offer ─────────────────────────────────────────────

class CreateOfferInput {
  const CreateOfferInput({
    required this.title,
    required this.modality,
    required this.tierId,
    required this.testDeadlineDays,
    this.description = '',
    this.salary,
    this.minExperienceYears,
    this.requiredEnglishLevel,
    this.positionsAvailable = 1,
    this.categoryIds = const [],
    this.skillIds = const [],
  });

  final String title;
  final String modality; // 'remote'|'hybrid'|'onsite'
  final int tierId;
  final int testDeadlineDays; // 1–90
  final String description;
  final int? salary;
  final int? minExperienceYears;
  final String? requiredEnglishLevel;
  final int positionsAvailable;
  final List<int> categoryIds;
  final List<int> skillIds;
}

// ─── AI parse result ──────────────────────────────────────────────────────────

class AiParseResult extends Equatable {
  const AiParseResult({
    this.title,
    this.modality,
    this.salary,
    this.minExperienceYears,
    this.requiredEnglishLevel,
    this.suggestedCategoryIds = const [],
    this.suggestedSkillIds = const [],
    this.confidenceNote,
  });

  final String? title;
  final String? modality;
  final int? salary;
  final int? minExperienceYears;
  final String? requiredEnglishLevel;
  final List<int> suggestedCategoryIds;
  final List<int> suggestedSkillIds;
  final String? confidenceNote;

  @override
  List<Object?> get props => [title, modality, salary];
}
