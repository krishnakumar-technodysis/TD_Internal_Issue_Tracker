// lib/presentation/widgets/app_sidebar.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:issue_tracker/presentation/issues/issue_viewmodel.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_viewmodel.dart';
import 'app_image.dart';

enum SidebarPage { dashboard, issues, create, history, approvals, admin }

class AppSidebar extends StatelessWidget {
  final SidebarPage activePage;
  /// True when rendered inside a Drawer — shows a close button & safe area
  final bool inDrawer;

  const AppSidebar({
    super.key,
    required this.activePage,
    this.inDrawer = false,
  });

  @override
  Widget build(BuildContext context) {
    final authVm  = context.watch<AuthViewModel>();
    final issueVm = context.watch<IssueViewModel>();
    final user    = authVm.currentUser;

    return Container(
      width: inDrawer ? double.infinity : 230,
      decoration: BoxDecoration(
        color: AppTheme.inkSoft,
        border: inDrawer
            ? null
            : const Border(
            right: BorderSide(color: AppTheme.border)),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Logo row (+ close btn when in drawer) ─────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 4),
              child: Row(children: [
                const AppImage.asset(
                  'assets/images/td_logo.png',
                  width: 36, height: 36,
                  shape: AppImageShape.rectangle,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TECHNODYSIS',
                        style: GoogleFonts.cabin(
                            fontWeight: FontWeight.w800, fontSize: 12.5,
                            color: AppTheme.textColor)),
                    const Text('ISSUE TRACKER',
                        style: TextStyle(
                            fontSize: 8.5, color: AppTheme.textDim,
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
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 16, color: AppTheme.textDim),
                    ),
                  ),
              ]),
            ),
            const SizedBox(height: 18),

            // ── Main nav ──────────────────────────────────
            _sectionLabel('MAIN'),
            _NavItem(
                icon: '📊', label: 'Dashboard',
                active: activePage == SidebarPage.dashboard,
                onTap:  () => _nav(context, SidebarPage.dashboard)),
            _NavItem(
                icon: '🐛', label: 'All Issues',
                badge: issueVm.allIssues.length.toString(),
                active: activePage == SidebarPage.issues,
                onTap:  () => _nav(context, SidebarPage.issues)),
            _NavItem(
                icon: '➕', label: 'Create Issue',
                active: activePage == SidebarPage.create,
                onTap:  () => _nav(context, SidebarPage.create)),
            _NavItem(
                icon: '📋', label: 'History',
                active: activePage == SidebarPage.history,
                onTap:  () => _nav(context, SidebarPage.history)),
            if (authVm.isAdmin)
              // _NavItem(
              //     icon: '👤', label: 'Approvals',
              //     badgeColor: AppTheme.orange,
              //     badge: null,
              //     active: activePage == SidebarPage.approvals,
              //     onTap: () => _nav(context, SidebarPage.approvals)),
            if (authVm.isAdmin)
              _NavItem(
                  icon: '⚙️', label: 'Admin Panel',
                  active: activePage == SidebarPage.admin,
                  onTap: () => _nav(context, SidebarPage.admin)),


            const SizedBox(height: 8),

            // ── Status filters ────────────────────────────
            _sectionLabel('BY STATUS'),
            _NavItem(
                icon: '🔵', label: 'Open',
                badgeColor: AppTheme.orange,
                badge: issueVm.openIssues.toString(),
                onTap: () => _nav(context, SidebarPage.issues)),
            _NavItem(
                icon: '🟣', label: 'In Progress',
                badgeColor: AppTheme.purple,
                badge: issueVm.inProgressIssues.toString(),
                onTap: () => _nav(context, SidebarPage.issues)),
            _NavItem(
                icon: '✅', label: 'Resolved',
                badgeColor: AppTheme.green,
                badge: issueVm.resolvedIssues.toString(),
                onTap: () => _nav(context, SidebarPage.issues)),
            _NavItem(
                icon: '🔴', label: 'Critical',
                badgeColor: AppTheme.red,
                badge: issueVm.criticalIssues.toString(),
                onTap: () => _nav(context, SidebarPage.issues)),

            const Spacer(),

            // ── User card ─────────────────────────────────
            Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.border.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(children: [
                _Avatar(name: user?.displayName ?? 'U'),
                const SizedBox(width: 8),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? 'User',
                      style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w500,
                          color: AppTheme.textColor),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                        (user?.role ?? 'user').toUpperCase(),
                        style: const TextStyle(
                            fontSize: 9.5, color: AppTheme.textDim,
                            letterSpacing: 0.8)),
                  ],
                )),
                IconButton(
                  icon: const Icon(Icons.logout_rounded,
                      size: 16, color: AppTheme.textDim),
                  tooltip: 'Sign out',
                  onPressed: () => authVm.signOut(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String txt) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 6, 0, 4),
    child: Text(txt,
        style: const TextStyle(
            fontSize: 9.5, fontWeight: FontWeight.w600,
            color: AppTheme.textDim, letterSpacing: 1.4)),
  );

  void _nav(BuildContext context, SidebarPage page) {
    // Close drawer first if we're inside one
    if (inDrawer) Navigator.pop(context);
    if (page == activePage && !inDrawer) return;
    switch (page) {
      case SidebarPage.dashboard:
        Navigator.pushNamedAndRemoveUntil(
            context, '/dashboard', (_) => false);
        break;
      case SidebarPage.issues:
        Navigator.pushNamedAndRemoveUntil(
            context, '/issues', (_) => false);
        break;
      case SidebarPage.create:
        Navigator.pushNamed(context, '/create');
        break;
      case SidebarPage.history:
        Navigator.pushNamedAndRemoveUntil(
            context, '/history', (_) => false);
        break;
      case SidebarPage.approvals:
        Navigator.pushNamedAndRemoveUntil(
            context, '/approvals', (_) => false);
        break;
      case SidebarPage.admin:
        Navigator.pushNamedAndRemoveUntil(
            context, '/admin', (_) => false);
        break;
    }
  }
}

// ─────────────────────────────────────────────────────────
// Nav item
// ─────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final String icon;
  final String label;
  final bool active;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback? onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    this.active    = false,
    this.badge,
    this.badgeColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? AppTheme.accent.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
              color: active
                  ? AppTheme.accent.withOpacity(0.25)
                  : Colors.transparent),
        ),
        child: Row(children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 9),
          Expanded(child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: active ? AppTheme.accent : AppTheme.textMuted),
              overflow: TextOverflow.ellipsis)),
          if (badge != null && badge != '0')
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor ?? AppTheme.accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                  badge!,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: badgeColor != null
                          ? Colors.white
                          : AppTheme.ink)),
            ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Avatar
// ─────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : name.toUpperCase();
    return Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        gradient: const LinearGradient(
            colors: [AppTheme.accent, AppTheme.blue],
            begin: Alignment.topLeft,
            end:   Alignment.bottomRight),
      ),
      child: Center(child: Text(initials,
          style: GoogleFonts.dmSans(
              fontSize: 12, fontWeight: FontWeight.w700,
              color: AppTheme.ink))),
    );
  }
}