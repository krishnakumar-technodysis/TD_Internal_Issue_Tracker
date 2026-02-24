// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/issue_repository_impl.dart';
import 'presentation/auth/auth_viewmodel.dart';
import 'presentation/auth/login_screen.dart';
import 'presentation/auth/register_screen.dart';
import 'presentation/dashboard/dashboard_screen.dart';
import 'presentation/issues/issue_viewmodel.dart';
import 'presentation/issues/issue_list_screen.dart';
import 'presentation/issues/create_issue_screen.dart';
import 'presentation/issues/history_screen.dart';
import 'domain/entities/issue_entity.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform);
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
        title: 'Technodysis — Issue Tracker',
        theme: AppTheme.theme,
        debugShowCheckedModeBanner: false,
        home: const _AppRouter(),
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/login':
              return _r(settings, const LoginScreen());
            case '/register':
              return _r(settings, const RegisterScreen());
            case '/dashboard':
              return _r(settings, const DashboardScreen());
            case '/issues':
              return _r(settings, const IssueListScreen());
            case '/create':
              return _r(settings, const CreateIssueScreen());
            case '/edit':
              final issue = settings.arguments as IssueEntity?;
              return _r(settings, CreateIssueScreen(existing: issue));
            case '/history':
              return _r(settings, const HistoryScreen());
            default:
              return null;
          }
        },
      ),
    );
  }

  PageRoute _r(RouteSettings s, Widget w) =>
      PageRouteBuilder(
        settings: s,
        pageBuilder: (_, __, ___) => w,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 200),
      );
}

class _AppRouter extends StatelessWidget {
  const _AppRouter();

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    switch (authVm.state) {
      case AuthState.initial:
        return const Scaffold(
            backgroundColor: AppTheme.ink,
            body: Center(child: CircularProgressIndicator(color: AppTheme.accent)));
      case AuthState.authenticated:
        return const DashboardScreen();
      default:
        return const LoginScreen();
    }
  }
}
