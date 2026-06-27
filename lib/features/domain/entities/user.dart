import 'package:equatable/equatable.dart';

enum UserRole { candidate, company, admin }

class User extends Equatable {
  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.avatarUrl,
  });

  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? avatarUrl;

  @override
  List<Object?> get props => [id, email, name, role, avatarUrl];
}
