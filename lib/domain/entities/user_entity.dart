// lib/domain/entities/user_entity.dart
import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final String role;       // 'admin' | 'user'
  final String status;     // 'pending' | 'approved' | 'rejected' | 'disabled'
  final String department;
  final DateTime createdAt;

  const UserEntity({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.status,
    required this.department,
    required this.createdAt,
  });

  bool get isAdmin    => role   == 'admin';
  bool get isApproved => status == 'approved';
  bool get isPending  => status == 'pending';
  bool get isRejected => status == 'rejected';
  bool get isDisabled => status == 'disabled';

  // Can log in = approved OR admin (but NOT disabled)
  bool get canLogin   => (isApproved || isAdmin) && !isDisabled;

  @override
  List<Object?> get props =>
      [uid, email, displayName, role, status, department, createdAt];
}