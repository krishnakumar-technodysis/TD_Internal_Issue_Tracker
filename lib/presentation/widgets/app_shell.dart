// lib/presentation/widgets/app_shell.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'app_sidebar.dart';

/// Below this width the sidebar collapses into a hamburger drawer
const double kSidebarBreakpoint = 720;

class AppShell extends StatelessWidget {
  final SidebarPage activePage;
  final Widget child;

  const AppShell({super.key, required this.activePage, required this.child});

  @override
  Widget build(BuildContext context) {
    final width    = MediaQuery.of(context).size.width;
    final showSide = width >= kSidebarBreakpoint;

    if (showSide) {
      // ── Desktop / wide tablet: persistent sidebar ──────────────────
      return Scaffold(
        backgroundColor: AppTheme.ink,
        body: Row(children: [
          AppSidebar(activePage: activePage),
          Expanded(child: child),
        ]),
      );
    }

    // ── Mobile / narrow: hamburger + drawer ────────────────────────────
    return Scaffold(
      backgroundColor: AppTheme.ink,
      appBar: _MobileAppBar(activePage: activePage),
      drawer: Drawer(
        width:           240,
        backgroundColor: AppTheme.inkSoft,
        shape: const RoundedRectangleBorder(), // square edges for full-bleed
        child: AppSidebar(activePage: activePage, inDrawer: true),
      ),
      body: child,
    );
  }
}

// ── Thin mobile top bar ────────────────────────────────────────────────
class _MobileAppBar extends StatelessWidget implements PreferredSizeWidget {
  final SidebarPage activePage;
  const _MobileAppBar({required this.activePage});

  static const _titles = {
    SidebarPage.userDashboard:       'My Dashboard',
    SidebarPage.adminDashboard:      'Dashboard',
    SidebarPage.superAdminDashboard: 'Dashboard',
    SidebarPage.dashboard:           'Dashboard',
    SidebarPage.issues:              'All Issues',
    SidebarPage.create:              'Create Issue',
    SidebarPage.history:             'History',
    SidebarPage.projects:            'Projects',
    SidebarPage.admin:               'Admin Panel',
    SidebarPage.settings:            'Settings',
  };

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor:  AppTheme.card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: Builder(builder: (ctx) => IconButton(
        icon: const Icon(Icons.menu_rounded,
            size: 22, color: AppTheme.textMuted),
        onPressed: () => Scaffold.of(ctx).openDrawer(),
      )),
      title: Text(
        _titles[activePage] ?? '',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppTheme.textColor,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppTheme.border),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);
}