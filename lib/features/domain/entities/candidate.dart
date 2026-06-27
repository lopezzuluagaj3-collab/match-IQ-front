import 'package:equatable/equatable.dart';

class CandidateProfile extends Equatable {
  const CandidateProfile({
    required this.userId,
    required this.name,
    required this.email,
    required this.headline,
    required this.skills,
    required this.experience,
    required this.education,
    required this.matchScore,
    required this.profileStrength,
    required this.pendingTests,
    required this.activeApplications,
    this.avatarUrl,
    this.location,
    this.bio,
    this.githubUrl,
    this.linkedinUrl,
    this.seniority,
    this.englishLevel,
    this.experienceYears,
  });

  final String userId;
  final String name;
  final String email;
  final String headline;
  final List<String> skills;
  final List<ExperienceItem> experience;
  final List<EducationItem> education;
  final int matchScore;
  final int profileStrength;
  final int pendingTests;
  final int activeApplications;
  final String? avatarUrl;
  final String? location;
  final String? bio;
  final String? githubUrl;
  final String? linkedinUrl;
  final String? seniority;
  final String? englishLevel;
  final int? experienceYears;

  @override
  List<Object?> get props => [userId];
}

class ExperienceItem extends Equatable {
  const ExperienceItem({
    required this.title,
    required this.company,
    required this.startDate,
    this.endDate,
    this.isCurrent = false,
  });
  final String title;
  final String company;
  final String startDate;
  final String? endDate;
  final bool isCurrent;

  @override
  List<Object?> get props => [title, company, startDate];
}

class EducationItem extends Equatable {
  const EducationItem({
    required this.degree,
    required this.institution,
    required this.year,
  });
  final String degree;
  final String institution;
  final String year;

  @override
  List<Object?> get props => [degree, institution, year];
}
