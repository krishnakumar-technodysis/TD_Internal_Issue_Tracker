// lib/domain/repositories/auth_repository.dart
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> signIn(String email, String password);
  Future<UserEntity> signUp({
    required String email,
    required String password,
    required String displayName,
    required String department,
  });
  Future<void>        signOut();
  Future<UserEntity?> getCurrentUser();
  Stream<UserEntity?> get authStateChanges;

  // ── Admin — approval queue ─────────────────────────────
  Stream<List<UserEntity>> get pendingUsersStream;
  Future<void> approveUser(String uid);
  Future<void> rejectUser(String uid);

  // ── Admin — user management ───────────────────────────
  Stream<List<UserEntity>> get allUsersStream;
  Future<void> createUser({
    required String email,
    required String password,
    required String displayName,
    required String role,
    required String department,
  });
  Future<void> updateUserRole(String uid, String role);
  Future<void> disableUser(String uid);
  Future<void> enableUser(String uid);
  Future<void> deleteUser(String uid);
  Future<void> sendPasswordReset(String email);
}