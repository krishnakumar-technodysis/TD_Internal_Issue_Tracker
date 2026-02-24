// lib/presentation/widgets/app_shell.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'app_sidebar.dart';

/// Wraps any app page with the persistent sidebar
class AppShell extends StatelessWidget {
  final SidebarPage activePage;
  final Widget child;

  const AppShell({super.key, required this.activePage, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.ink,
      body: Row(
        children: [
          AppSidebar(activePage: activePage),
          Expanded(
            child: Column(children: [
              Expanded(child: child),
            ]),
          ),
        ],
      ),
    );
  }
}
