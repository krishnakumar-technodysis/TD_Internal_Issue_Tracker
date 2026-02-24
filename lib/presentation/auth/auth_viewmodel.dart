// lib/presentation/auth/auth_viewmodel.dart
import 'package:flutter/material.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepo;
  AuthViewModel(this._authRepo) { _init(); }

  AuthState   _state        = AuthState.initial;
  UserEntity? _currentUser;
  String?     _errorMessage;

  AuthState   get state        => _state;
  UserEntity? get currentUser  => _currentUser;
  String?     get errorMessage => _errorMessage;
  bool        get isAuthenticated => _currentUser != null;
  bool        get isAdmin         => _currentUser?.isAdmin ?? false;

  void _init() {
    _authRepo.authStateChanges.listen((user) {
      _currentUser = user;
      _state = user != null
          ? AuthState.authenticated
          : AuthState.unauthenticated;
      notifyListeners();
    });
  }

  Future<bool> signIn(String email, String password) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _currentUser = await _authRepo.signIn(email, password);
      _state = AuthState.authenticated;
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
    _currentUser = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  String _parseError(String e) {
    if (e.contains('user-not-found'))    return 'No account found for this email.';
    if (e.contains('wrong-password'))    return 'Incorrect password.';
    if (e.contains('invalid-email'))     return 'Invalid email format.';
    if (e.contains('user-disabled'))     return 'Account has been disabled.';
    if (e.contains('too-many-requests')) return 'Too many attempts. Try again later.';
    if (e.contains('invalid-credential')) return 'Invalid credentials. Check email & password.';
    return 'Login failed. Please check your credentials.';
  }
}
