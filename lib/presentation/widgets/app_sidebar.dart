// lib/presentation/widgets/app_sidebar.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_viewmodel.dart';
import '../issues/issue_viewmodel.dart';
import 'app_image.dart';

enum SidebarPage {
  // Role dashboards
  userDashboard,
  adminDashboard,
  superAdminDashboard,
  // Shared pages
  dashboard,
  issues,
  create,
  history,
  projects,
  admin,
  settings,
  reports,
}

class AppSidebar extends StatelessWidget {
  final SidebarPage activePage;
  final bool inDrawer;

  const AppSidebar({super.key, required this.activePage, this.inDrawer = false});

  @override
  Widget build(BuildContext context) {
    final authVm  = context.watch<AuthViewModel>();
    final issueVm = context.watch<IssueViewModel>();
    final user    = authVm.currentUser;
    final isAdmin      = user?.isAdmin       ?? false;
    final isManager    = user?.isManager     ?? false;
    final isSuperAdmin = user?.isSuperAdmin  ?? false;

    return Container(
      width: inDrawer ? double.infinity : 230,
      decoration: BoxDecoration(
        color: AppTheme.inkSoft,
        border: inDrawer ? null
            : const Border(right: BorderSide(color: AppTheme.border)),
      ),
      child: SafeArea(
        right: false,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Logo ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 4),
            child: Row(children: [
              const AppImage.asset('assets/images/td_logo.png',
                  width: 36, height: 36,
                  shape: AppImageShape.rectangle, fit: BoxFit.contain),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TD INTERNAL',
                      style: GoogleFonts.cabin(
                          fontWeight: FontWeight.w800, fontSize: 12.5,
                          color: AppTheme.textColor)),
                  const Text('TRACKER',
                      style: TextStyle(fontSize: 8.5, color: AppTheme.textDim,
                          letterSpacing: 1.2)),
                ],
              )),
              if (inDrawer)
                GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                            color: AppTheme.border.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(6)),
                        child: const Icon(Icons.close_rounded,
                            size: 16, color: AppTheme.textDim))),
            ]),
          ),
          const SizedBox(height: 8),

          // ── Scrollable nav ─────────────────────────────────────────────
          Expanded(child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              _sectionLabel('MAIN'),

              // ── Super Admin nav ────────────────────────────────────────
              if (isSuperAdmin) ...[
                _NavItem(
                  icon: '🏠', label: 'Dashboard',
                  active: activePage == SidebarPage.superAdminDashboard ||
                      activePage == SidebarPage.dashboard,
                  onTap: () => _nav(context, SidebarPage.superAdminDashboard),
                ),
                _NavItem(
                  icon: '📁', label: 'Projects',
                  active: activePage == SidebarPage.projects,
                  onTap: () => _nav(context, SidebarPage.projects),
                ),
                _NavItem(
                  icon: '🐛', label: 'All Issues',
                  badge: issueVm.allIssues.length.toString(),
                  active: activePage == SidebarPage.issues,
                  onTap: () => _nav(context, SidebarPage.issues),
                ),
                _NavItem(
                  icon: '➕', label: 'Create Issue',
                  active: activePage == SidebarPage.create,
                  onTap: () => _nav(context, SidebarPage.create),
                ),
                _NavItem(
                  icon: '📋', label: 'History',
                  active: activePage == SidebarPage.history,
                  onTap: () => _nav(context, SidebarPage.history),
                ),
                const SizedBox(height: 8),
                _sectionLabel('MANAGEMENT'),
                _NavItem(
                  icon: '⚙️', label: 'Admin Panel',
                  active: activePage == SidebarPage.admin,
                  onTap: () => _nav(context, SidebarPage.admin),
                ),
                _NavItem(
                  icon: '🔧', label: 'Settings',
                  active: activePage == SidebarPage.settings,
                  onTap: () => _nav(context, SidebarPage.settings),
                ),
                _NavItem(
                  icon: '📥', label: 'Download Report',
                  active: activePage == SidebarPage.reports,
                  onTap: () => _nav(context, SidebarPage.reports),
                ),
              ]

              // ── Admin / Manager nav ────────────────────────────────────
              else if (isAdmin || isManager) ...[
                _NavItem(
                  icon: '🏠', label: 'Dashboard',
                  active: activePage == SidebarPage.adminDashboard ||
                      activePage == SidebarPage.dashboard,
                  onTap: () => _nav(context, SidebarPage.adminDashboard),
                ),
                _NavItem(
                  icon: '📁', label: 'Projects',
                  active: activePage == SidebarPage.projects,
                  onTap: () => _nav(context, SidebarPage.projects),
                ),
                _NavItem(
                  icon: '🐛', label: 'All Issues',
                  badge: issueVm.allIssues.length.toString(),
                  active: activePage == SidebarPage.issues,
                  onTap: () => _nav(context, SidebarPage.issues),
                ),
                _NavItem(
                  icon: '➕', label: 'Create Issue',
                  active: activePage == SidebarPage.create,
                  onTap: () => _nav(context, SidebarPage.create),
                ),
                _NavItem(
                  icon: '📋', label: 'History',
                  active: activePage == SidebarPage.history,
                  onTap: () => _nav(context, SidebarPage.history),
                ),
                if (isAdmin) ...[
                  const SizedBox(height: 8),
                  _sectionLabel('MANAGEMENT'),
                  _NavItem(
                    icon: '⚙️', label: 'Admin Panel',
                    active: activePage == SidebarPage.admin,
                    onTap: () => _nav(context, SidebarPage.admin),
                  ),
                  _NavItem(
                    icon: '🔧', label: 'Settings',
                    active: activePage == SidebarPage.settings,
                    onTap: () => _nav(context, SidebarPage.settings),
                  ),
                  _NavItem(
                    icon: '📥', label: 'Download Report',
                    active: activePage == SidebarPage.reports,
                    onTap: () => _nav(context, SidebarPage.reports),
                  ),
                ],
              ]

              // ── Regular User nav ───────────────────────────────────────
              else ...[
                _NavItem(
                  icon: '🏠', label: 'My Dashboard',
                  active: activePage == SidebarPage.userDashboard ||
                      activePage == SidebarPage.dashboard,
                  onTap: () => _nav(context, SidebarPage.userDashboard),
                ),
                _NavItem(
                  icon: '📁', label: 'My Projects',
                  active: activePage == SidebarPage.projects,
                  onTap: () => _nav(context, SidebarPage.projects),
                ),
                _NavItem(
                  icon: '🐛', label: 'Issues',
                  badge: issueVm.allIssues.length.toString(),
                  active: activePage == SidebarPage.issues,
                  onTap: () => _nav(context, SidebarPage.issues),
                ),
              ],

              // ── Issue status counters (visible to all) ─────────────────
              const SizedBox(height: 8),
              _sectionLabel('BY STATUS'),
              _NavItem(icon: '🔵', label: 'Open',
                  badge: issueVm.openIssues.toString(),
                  badgeColor: AppTheme.orange,
                  onTap: () => _nav(context, SidebarPage.issues)),
              _NavItem(icon: '🟣', label: 'In Progress',
                  badge: issueVm.inProgressIssues.toString(),
                  badgeColor: AppTheme.purple,
                  onTap: () => _nav(context, SidebarPage.issues)),
              _NavItem(icon: '✅', label: 'Resolved',
                  badge: issueVm.resolvedIssues.toString(),
                  badgeColor: AppTheme.green,
                  onTap: () => _nav(context, SidebarPage.issues)),
              _NavItem(icon: '🔴', label: 'Critical',
                  badge: issueVm.criticalIssues.toString(),
                  badgeColor: AppTheme.red,
                  onTap: () => _nav(context, SidebarPage.issues)),

              const SizedBox(height: 16),
            ]),
          )),

          // ── User card ──────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: AppTheme.border.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border.withOpacity(0.5))),
            child: Row(children: [
              Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppTheme.accentBg,
                      border: Border.all(color: AppTheme.accent.withOpacity(0.3))),
                  child: Center(child: Text(
                      user?.displayName.isNotEmpty == true
                          ? user!.displayName[0].toUpperCase() : 'U',
                      style: const TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w700, color: AppTheme.accent)))),
              const SizedBox(width: 8),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user?.displayName ?? 'User',
                      style: const TextStyle(fontSize: 12.5,
                          fontWeight: FontWeight.w600, color: AppTheme.textColor),
                      overflow: TextOverflow.ellipsis),
                  Text(user?.roleLabel ?? '',
                      style: const TextStyle(fontSize: 10.5, color: AppTheme.textDim)),
                ],
              )),
              GestureDetector(
                  onTap: () => authVm.signOut(),
                  child: const Icon(Icons.logout_rounded,
                      size: 16, color: AppTheme.textDim)),
            ]),
          ),
        ]),
      ),
    );
  }

  static Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 10, 0, 4),
    child: Text(text,
        style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700,
            color: AppTheme.textDim, letterSpacing: 1.2)),
  );

  void _nav(BuildContext context, SidebarPage page) {
    if (inDrawer) Navigator.pop(context);
    switch (page) {
      case SidebarPage.superAdminDashboard:
        Navigator.pushNamedAndRemoveUntil(context, '/super-dashboard', (_) => false);
      case SidebarPage.adminDashboard:
        Navigator.pushNamedAndRemoveUntil(context, '/admin-dashboard', (_) => false);
      case SidebarPage.userDashboard:
        Navigator.pushNamedAndRemoveUntil(context, '/user-dashboard',  (_) => false);
      case SidebarPage.dashboard:
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard',       (_) => false);
      case SidebarPage.issues:
        Navigator.pushNamedAndRemoveUntil(context, '/issues',          (_) => false);
      case SidebarPage.create:
        Navigator.pushNamedAndRemoveUntil(context, '/create',          (_) => false);
      case SidebarPage.history:
        Navigator.pushNamedAndRemoveUntil(context, '/history',         (_) => false);
      case SidebarPage.projects:
        Navigator.pushNamedAndRemoveUntil(context, '/projects',        (_) => false);
      case SidebarPage.admin:
        Navigator.pushNamedAndRemoveUntil(context, '/admin',           (_) => false);
      case SidebarPage.settings:
        Navigator.pushNamedAndRemoveUntil(context, '/settings',        (_) => false);
      case SidebarPage.reports:
        Navigator.pushNamedAndRemoveUntil(context, '/reports',         (_) => false);
    }
  }
}

// ── Nav item ──────────────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final String icon, label;
  final bool active;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback? onTap;

  const _NavItem({
    required this.icon, required this.label,
    this.active = false, this.badge, this.badgeColor, this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
            color: active ? AppTheme.accent.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: active ? Border.all(color: AppTheme.accent.withOpacity(0.2))
                : null),
        child: Row(children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 9),
          Expanded(child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: active ? AppTheme.accent : AppTheme.textMuted))),
          if (badge != null && badge != '0')
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                    color: (badgeColor ?? AppTheme.textDim).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10)),
                child: Text(badge!,
                    style: TextStyle(
                        fontSize: 10.5, fontWeight: FontWeight.w700,
                        color: badgeColor ?? AppTheme.textDim))),
        ]),
      ),
    );
  }
}
