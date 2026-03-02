import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../presentation/auth/auth_viewmodel.dart';
import '../../presentation/auth/login_screen.dart';
import '../../presentation/dashboard/dashboard_screen.dart';
import '../../presentation/issues/issue_list_screen.dart';
import '../../presentation/issues/create_issue_screen.dart';
import '../../presentation/issues/history_screen.dart';
import '../../core/theme/app_theme.dart';

class AppRouter extends StatelessWidget {
  final String? routeName;
  const AppRouter({super.key, this.routeName});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();

    // 🔐 Loading state
    if (authVm.state == AuthState.initial) {
      return const Scaffold(
        backgroundColor: AppTheme.ink,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.accent),
        ),
      );
    }

    // 🔓 Not logged in
    if (!authVm.isAuthenticated) {
      return const LoginScreen();
    }

    // ✅ Logged in → restore correct page
    switch (routeName) {
      case '/issues':
        return const IssueListScreen();
      case '/create':
        return const CreateIssueScreen();
      case '/history':
        return const HistoryScreen();
      case '/dashboard':
      default:
        return const DashboardScreen();
    }
  }
}