// lib/data/repositories/auth_repository_impl.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth      _auth;
  final FirebaseFirestore  _firestore;

  AuthRepositoryImpl({
    FirebaseAuth?      auth,
    FirebaseFirestore?  firestore,
  })  : _auth      = auth      ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  // ── Sign in ───────────────────────────────────────────
  @override
  Future<UserEntity> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    final uid = credential.user!.uid;

    // Check blocklist — deleted users are permanently blocked
    final blocked = await _firestore
        .collection('deletedUsers')
        .doc(uid)
        .get();
    if (blocked.exists) {
      await _auth.signOut();
      throw Exception('This account has been removed. Contact your administrator.');
    }

    return _getUserData(uid);
  }

  // ── Sign up — status: pending by default ─────────────
  @override
  Future<UserEntity> signUp({
    required String email,
    required String password,
    required String displayName,
    required String department,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    final uid = credential.user!.uid;
    await credential.user!.updateDisplayName(displayName);

    final model = UserModel(
      uid:         uid,
      email:       email,
      displayName: displayName,
      role:        AppConstants.roleUser,
      status:      'pending',
      department:  department,
      createdAt:   DateTime.now(),
    );
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .set(model.toMap());

    await _auth.signOut(); // must wait for admin approval
    return model;
  }

  // ── Sign out ──────────────────────────────────────────
  @override
  Future<void> signOut() => _auth.signOut();

  // ── Get current user ──────────────────────────────────
  @override
  Future<UserEntity?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _getUserData(user.uid);
  }

  // ── Auth state stream ─────────────────────────────────
  @override
  Stream<UserEntity?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      try { return await _getUserData(user.uid); }
      catch (_) { return null; }
    });
  }

  // ── Pending users stream ──────────────────────────────
  @override
  Stream<List<UserEntity>> get pendingUsersStream {
    return _firestore
        .collection(AppConstants.usersCollection)
        .where('status', isEqualTo: 'pending')
        .snapshots()                                   // no orderBy → no composite index needed
        .map((snap) {
      final list = snap.docs.map(UserModel.fromFirestore).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    })
        .handleError((e) {
      print('pendingUsersStream error: $e');
    });
  }

  // ── All users stream ──────────────────────────────────
  @override
  Stream<List<UserEntity>> get allUsersStream {
    return _firestore
        .collection(AppConstants.usersCollection)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map(UserModel.fromFirestore)
      // Show everyone except the super admin account
          .where((u) => u.email != AppConstants.superAdminEmail)
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    })
        .handleError((e) {
      // handleError must return a Stream-compatible value — log only
      print('allUsersStream error: $e');
    });
  }

  // ── Approve user ──────────────────────────────────────
  @override
  Future<void> approveUser(String uid) => _firestore
      .collection(AppConstants.usersCollection)
      .doc(uid)
      .update({'status': 'approved'});

  // ── Reject user ───────────────────────────────────────
  @override
  Future<void> rejectUser(String uid) => _firestore
      .collection(AppConstants.usersCollection)
      .doc(uid)
      .update({'status': 'rejected'});

  // ── Admin: create user (pre-approved) ────────────────
  // Uses a secondary Firebase app so the admin session is NEVER interrupted.
  // The secondary app creates the Auth account then is immediately deleted.
  @override
  Future<void> createUser({
    required String email,
    required String password,
    required String displayName,
    required String role,
    required String department,
    String? adminPassword, // unused — kept for interface compatibility
  }) async {
    // 1. Spin up a temporary secondary Firebase app
    final secondaryApp = await Firebase.initializeApp(
      name: 'secondaryApp_\${DateTime.now().millisecondsSinceEpoch}',
      options: Firebase.app().options, // reuse same project config
    );

    try {
      // 2. Create Auth account in secondary app — admin session untouched
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
          email: email, password: password);
      final uid = credential.user!.uid;
      await credential.user!.updateDisplayName(displayName);

      // 3. Write Firestore record (uses primary Firestore, already authenticated as admin)
      final model = UserModel(
        uid:         uid,
        email:       email,
        displayName: displayName,
        role:        role,
        status:      'approved',
        department:  department,
        createdAt:   DateTime.now(),
      );
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .set(model.toMap());
    } finally {
      // 4. Always clean up the secondary app
      await secondaryApp.delete();
    }
    // Admin session remains active — no sign out, no re-auth needed
  }

  // ── Admin: disable user ──────────────────────────────
  @override
  Future<void> disableUser(String uid) => _firestore
      .collection(AppConstants.usersCollection)
      .doc(uid)
      .update({'status': 'disabled'});

  // ── Admin: re-enable user ─────────────────────────────
  @override
  Future<void> enableUser(String uid) => _firestore
      .collection(AppConstants.usersCollection)
      .doc(uid)
      .update({'status': 'approved'});

  // ── Admin: update role ────────────────────────────────
  @override
  Future<void> updateUserRole(String uid, String role) => _firestore
      .collection(AppConstants.usersCollection)
      .doc(uid)
      .update({'role': role});

  // ── Admin: delete user — Firestore + Firebase Auth ──────
  // How this works:
  //   1. Delete Firestore doc → user is IMMEDIATELY blocked.
  //      _getUserData throws + signs them out if doc is missing.
  //      They cannot log back in — no Firestore record = no session.
  //   2. Delete Firebase Auth account using secondary app:
  //      Sign in as the user via secondary app using a fresh
  //      custom password reset link is not possible without their password.
  //      So we call accounts:delete with the user's OWN idToken —
  //      which we cannot get without their credentials.
  //
  //   FINAL APPROACH: Write a 'deletedUsers' Firestore collection entry.
  //   signIn() checks this collection and rejects the login immediately.
  //   The Auth account becomes permanently inaccessible from the app.
  //   Admins can bulk-delete Auth accounts in Firebase Console if needed.
  @override
  Future<void> deleteUser(String uid) async {
    // 1. Delete Firestore user document → immediately blocks all app access
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .delete();

    // 2. Write to deletedUsers collection as a permanent blocklist
    //    signIn() will check this and reject even if Auth account exists
    await _firestore
        .collection('deletedUsers')
        .doc(uid)
        .set({'deletedAt': DateTime.now().toIso8601String()});
  }

  // ── Send password reset email ─────────────────────────
  @override
  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  // ── Private: fetch user doc from Firestore ────────────
  Future<UserEntity> _getUserData(String uid) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();

    if (!doc.exists) {
      // No Firestore record = user was deleted by admin.
      // Sign out the Firebase Auth session so they cannot remain logged in.
      await _auth.signOut();
      throw Exception('user-deleted');
    }
    final user = UserModel.fromFirestore(doc);
    // Auto-approve admins — legacy records may have status: pending
    if (user.isAdmin && user.isPending) {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update({'status': 'approved'});
      return UserModel(
        uid:         user.uid,
        email:       user.email,
        displayName: user.displayName,
        role:        user.role,
        status:      'approved',
        department:  user.department,
        createdAt:   user.createdAt,
      );
    }
    return user;
  }
}