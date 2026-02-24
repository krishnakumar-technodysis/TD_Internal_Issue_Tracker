// lib/domain/entities/user_entity.dart
import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final String role; // 'admin' or 'user'
  final DateTime createdAt;

  const UserEntity({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.createdAt,
  });

  bool get isAdmin => role == 'admin';

  @override
  List<Object?> get props => [uid, email, displayName, role, createdAt];
}
