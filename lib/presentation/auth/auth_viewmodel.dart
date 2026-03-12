// lib/presentation/auth/auth_viewmodel.dart
import 'package:flutter/material.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

enum AuthState { initial, loading, authenticated, pendingApproval, unauthenticated, error }

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepo;
  AuthViewModel(this._authRepo) { _init(); }

  AuthState        _state             = AuthState.initial;
  UserEntity?      _currentUser;
  String?          _errorMessage;
  bool             _registeredJustNow = false;
  List<UserEntity> _allUsers          = [];

  /// Sync list of all users, kept up-to-date via allUsersStream.
  List<UserEntity> get allUsers => _allUsers;

  AuthState   get state          => _state;
  UserEntity? get currentUser    => _currentUser;
  String?     get errorMessage   => _errorMessage;
  bool        get isAuthenticated  => _state == AuthState.authenticated;
  bool        get isAdmin          => _currentUser?.isAdmin ?? false;
  bool        get registeredJustNow => _registeredJustNow;

  void _init() {
    // Keep allUsers in sync
    _authRepo.allUsersStream.listen((users) {
      _allUsers = users;
      notifyListeners();
    });
    _authRepo.authStateChanges.listen((user) {
      if (user == null) {
        _currentUser = null;
        // Don't override pendingApproval state set right after signup
        if (_state != AuthState.pendingApproval) {
          _state = AuthState.unauthenticated;
        }
      } else {
        _currentUser = user;
        _state = user.isApproved || user.isAdmin
            ? AuthState.authenticated
            : AuthState.pendingApproval;
      }
      notifyListeners();
    });
  }

  // ── Sign up ───────────────────────────────────────────
  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
    required String department,
  }) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _currentUser = await _authRepo.signUp(
        email: email, password: password,
        displayName: displayName, department: department,
      );
      _registeredJustNow = true;
      _state = AuthState.pendingApproval;
      notifyListeners();
      return true;
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = _parseError(e.toString());
      notifyListeners();
      return false;
    }
  }

  // ── Sign in ───────────────────────────────────────────
  Future<bool> signIn(String email, String password) async {
    _state = AuthState.loading;
    _errorMessage = null;
    _registeredJustNow = false;
    notifyListeners();
    try {
      _currentUser = await _authRepo.signIn(email, password);
      if (_currentUser!.isDisabled) {
        _state = AuthState.error;
        _errorMessage = 'Your account has been disabled. Contact your administrator.';
        await _authRepo.signOut();
        notifyListeners();
        return false;
      }
      if (_currentUser!.isRejected) {
        _state = AuthState.error;
        _errorMessage = 'Your account request was rejected. Contact your administrator.';
        await _authRepo.signOut();
        notifyListeners();
        return false;
      }
      _state = _currentUser!.canLogin
          ? AuthState.authenticated
          : AuthState.pendingApproval;
      notifyListeners();
      return true;
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = _parseError(e.toString());
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authRepo.signOut();
    _currentUser       = null;
    _registeredJustNow = false;
    _state             = AuthState.unauthenticated;
    notifyListeners();
  }

  // ── Refresh status (re-fetch from Firestore) ────────
  Future<void> refreshStatus() async {
    try {
      final user = await _authRepo.getCurrentUser();
      if (user == null) { await signOut(); return; }
      _currentUser = user;
      _state = user.canLogin
          ? AuthState.authenticated
          : AuthState.pendingApproval;
      notifyListeners();
    } catch (_) {}
  }

  // ── Pending users stream (admin) ──────────────────────
  Stream<List<UserEntity>> get pendingUsersStream =>
      _authRepo.pendingUsersStream;

  Future<void> approveUser(String uid) => _authRepo.approveUser(uid);
  Future<void> rejectUser(String uid)  => _authRepo.rejectUser(uid);

  // ── Admin — user management ───────────────────────────
  Stream<List<UserEntity>> get allUsersStream => _authRepo.allUsersStream;

  Future<void> createUser({
    required String email,
    required String password,
    required String displayName,
    required String role,
    required String department,
  }) => _authRepo.createUser(
      email: email, password: password,
      displayName: displayName, role: role, department: department);

  Future<void> updateUserRole(String uid, String role) =>
      _authRepo.updateUserRole(uid, role);
  Future<void> disableUser(String uid) => _authRepo.disableUser(uid);
  Future<void> enableUser(String uid)  => _authRepo.enableUser(uid);

  Future<void> deleteUser(String uid) => _authRepo.deleteUser(uid);

  // ── Password reset ────────────────────────────────────
  Future<void> sendPasswordReset(String email) =>
      _authRepo.sendPasswordReset(email);

  String _parseError(String e) {
    if (e.contains('removed') || e.contains('user-deleted')) return e.replaceAll('Exception: ', '');
    if (e.contains('user-not-found'))        return 'No account found for this email.';
    if (e.contains('wrong-password'))        return 'Incorrect password.';
    if (e.contains('invalid-email'))         return 'Invalid email format.';
    if (e.contains('user-disabled'))         return 'Account has been disabled.';
    if (e.contains('too-many-requests'))     return 'Too many attempts. Try again later.';
    if (e.contains('invalid-credential'))    return 'Invalid credentials. Check email & password.';
    if (e.contains('email-already-in-use'))  return 'An account already exists for this email.';
    if (e.contains('weak-password'))         return 'Password is too weak. Use at least 6 characters.';
    if (e.contains('operation-not-allowed')) return 'Email/password accounts are not enabled.';
    if (e.contains('network-request-failed')) return 'No internet connection. Please try again.';
    return 'Something went wrong. Please try again.';
  }
}