// lib/domain/entities/user_entity.dart
import 'package:equatable/equatable.dart';
import '../../core/constants/app_constants.dart';

class UserEntity extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final String role;        // 'admin' | 'manager' | 'user'
  final String status;      // 'pending' | 'approved' | 'rejected' | 'disabled'
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

  bool get isAdmin    => role == AppConstants.roleAdmin || isSuperAdmin;
  bool get isManager  => role == AppConstants.roleManager;
  bool get isSuperAdmin => email == AppConstants.superAdminEmail;
  bool get isRegularUser => role == AppConstants.roleUser;

  // What the user can access
  bool get canViewDashboard  => isAdmin || isManager;
  bool get canViewAdmin      => isAdmin;
  bool get canViewApprovals  => isAdmin;
  bool get canViewSettings   => isAdmin;
  bool get canCreateProject  => isAdmin || isManager;
  bool get canManageIssues   => isAdmin || isManager;

  bool get isApproved => status == 'approved';
  bool get isPending  => status == 'pending';
  bool get isRejected => status == 'rejected';
  bool get isDisabled => status == 'disabled';
  bool get canLogin   => (isApproved || isAdmin) && !isDisabled;

  String get roleLabel => switch (role) {
    AppConstants.roleAdmin   => 'Admin',
    AppConstants.roleManager => 'Manager',
    _                        => 'User',
  };

  @override
  List<Object?> get props =>
      [uid, email, displayName, role, status, department, createdAt];
}