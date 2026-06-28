import 'package:equatable/equatable.dart';

class AdminUser extends Equatable {
  const AdminUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.cedula,
    required this.role,
    required this.isActive,
    required this.emailVerified,
    required this.createdAt,
    this.profileName,
  });

  final int id;
  final String email;
  final String fullName;
  final String cedula;
  final String role; // 'Candidate' | 'Company' | 'Admin'
  final bool isActive;
  final bool emailVerified;
  final DateTime createdAt;
  final String? profileName; // nombre empresa para Company, null para Candidate

  String get displayName => profileName ?? fullName;

  @override
  List<Object?> get props => [id];
}
