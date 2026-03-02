// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:issue_tracker/presentation/admin/admin_screen.dart';
import 'package:issue_tracker/presentation/auth/admin_approval_screen.dart';
import 'package:issue_tracker/presentation/auth/login_screen.dart';
import 'package:issue_tracker/presentation/auth/pending_approval_screen.dart';
import 'package:issue_tracker/presentation/dashboard/dashboard_screen.dart';
import 'package:issue_tracker/presentation/issues/create_issue_screen.dart';
import 'package:issue_tracker/presentation/issues/history_screen.dart';
import 'package:issue_tracker/presentation/issues/issue_list_screen.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/issue_repository_impl.dart';
import 'firebase_options.dart';
import 'presentation/auth/auth_viewmodel.dart';
import 'presentation/issues/issue_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const TechnodysisApp());
}

class TechnodysisApp extends StatelessWidget {
  const TechnodysisApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepo  = AuthRepositoryImpl();
    final issueRepo = IssueRepositoryImpl();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel(authRepo)),
        ChangeNotifierProvider(create: (_) {
          final vm = IssueViewModel(issueRepo);
          vm.listenToIssues();
          return vm;
        }),
      ],
      child: MaterialApp(
        title:                     'Technodysis — Issue Tracker',
        theme:                     AppTheme.theme,
        debugShowCheckedModeBanner: false,
        // AppRouter handles all auth state & screen selection
        home: const AppRouter(),
        onGenerateRoute: (settings) {
          final page = AppRouter(routeName: settings.name);
          return PageRouteBuilder(
            settings: settings,
            pageBuilder: (_, __, ___) => page,
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 200),
          );
        },
      ),
    );
  }
}

class AppRouter extends StatelessWidget {
  final String? routeName;
  const AppRouter({super.key, this.routeName});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();

    // ── Loading ───────────────────────────────────────────
    if (authVm.state == AuthState.initial ||
        authVm.state == AuthState.loading) {
      return const Scaffold(
        backgroundColor: AppTheme.ink,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.accent),
        ),
      );
    }

    // ── Not logged in ─────────────────────────────────────
    if (authVm.state == AuthState.unauthenticated ||
        authVm.state == AuthState.error ||
        !authVm.isAuthenticated) {
      return const LoginScreen();
    }

    // ── Logged in but awaiting admin approval ─────────────
    if (authVm.state == AuthState.pendingApproval) {
      return const PendingApprovalScreen();
    }

    // ── Authenticated — restore correct page ──────────────
    switch (routeName) {
      case '/issues':
        return const IssueListScreen();
      case '/create':
        return const CreateIssueScreen();
      case '/history':
        return const HistoryScreen();
      case '/approvals':
        if (authVm.isAdmin) return const AdminApprovalScreen();
        return const DashboardScreen();
      case '/admin':
        if (authVm.isAdmin) return const AdminScreen();
        return const DashboardScreen();
      case '/dashboard':
      default:
        return const DashboardScreen();
    }
  }
}