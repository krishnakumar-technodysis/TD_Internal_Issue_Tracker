// lib/presentation/widgets/app_sidebar.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_viewmodel.dart';

enum SidebarPage { dashboard, issues, create, history }

class AppSidebar extends StatelessWidget {
  final SidebarPage activePage;
  const AppSidebar({super.key, required this.activePage});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final user   = authVm.currentUser;

    return Container(
      width: 230,
      decoration: const BoxDecoration(
        color: AppTheme.inkSoft,
        border: Border(right: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Logo ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
            child: Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    colors: [AppTheme.accent, AppTheme.blue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Text('⚡', style: TextStyle(fontSize: 15))),
              ),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('TECHNODYSIS',
                  style: GoogleFonts.syne(
                    fontWeight: FontWeight.w800, fontSize: 13,
                    color: AppTheme.textColor)),
                const Text('ISSUE TRACKER',
                  style: TextStyle(
                    fontSize: 9, color: AppTheme.textDim, letterSpacing: 1.2)),
              ]),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Main nav ─────────────────────────────────
          _sectionLabel('MAIN'),
          _NavItem(icon: '📊', label: 'Dashboard',
            active: activePage == SidebarPage.dashboard,
            onTap: () => _nav(context, SidebarPage.dashboard)),
          _NavItem(icon: '🐛', label: 'All Issues',
            badge: '24',
            active: activePage == SidebarPage.issues,
            onTap: () => _nav(context, SidebarPage.issues)),
          _NavItem(icon: '➕', label: 'Create Issue',
            active: activePage == SidebarPage.create,
            onTap: () => _nav(context, SidebarPage.create)),
          _NavItem(icon: '📋', label: 'History',
            active: activePage == SidebarPage.history,
            onTap: () => _nav(context, SidebarPage.history)),

          const SizedBox(height: 8),

          // ── Status filters ────────────────────────────
          _sectionLabel('BY STATUS'),
          _NavItem(icon: '🔵', label: 'Open',
            badgeColor: AppTheme.orange, badge: '8',
            onTap: () => _nav(context, SidebarPage.issues)),
          _NavItem(icon: '🟣', label: 'In Progress',
            badgeColor: AppTheme.purple, badge: '5',
            onTap: () => _nav(context, SidebarPage.issues)),
          _NavItem(icon: '✅', label: 'Resolved',
            onTap: () => _nav(context, SidebarPage.issues)),
          _NavItem(icon: '🔴', label: 'Critical',
            badgeColor: AppTheme.red, badge: '3',
            onTap: () => _nav(context, SidebarPage.issues)),

          const SizedBox(height: 8),

          // ── Clients ───────────────────────────────────
          _sectionLabel('CLIENTS'),
          _NavItem(icon: '💚', label: 'Ecocash',
            onTap: () => _nav(context, SidebarPage.issues)),
          _NavItem(icon: '🔷', label: 'Econet',
            onTap: () => _nav(context, SidebarPage.issues)),
          _NavItem(icon: '🟠', label: 'CWS',
            onTap: () => _nav(context, SidebarPage.issues)),
          _NavItem(icon: '🟡', label: 'EMM',
            onTap: () => _nav(context, SidebarPage.issues)),
          _NavItem(icon: '🔴', label: 'EthioTelecom',
            onTap: () => _nav(context, SidebarPage.issues)),

          const Spacer(),

          // ── User card ────────────────────────────────
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              _Avatar(name: user?.displayName ?? 'U'),
              const SizedBox(width: 8),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user?.displayName ?? 'User',
                    style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w500,
                      color: AppTheme.textColor),
                    overflow: TextOverflow.ellipsis),
                  Text((user?.role ?? 'user').toUpperCase(),
                    style: const TextStyle(
                      fontSize: 9.5, color: AppTheme.textDim, letterSpacing: 0.8)),
                ],
              )),
              IconButton(
                icon: const Icon(Icons.logout, size: 16, color: AppTheme.textDim),
                tooltip: 'Sign out',
                onPressed: () => authVm.signOut(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ]),
          ),
        ],
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
    if (page == activePage) return;
    Widget screen;
    // lazy import to avoid circular deps – use named routes instead
    switch (page) {
      case SidebarPage.dashboard:
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (_) => false);
        break;
      case SidebarPage.issues:
        Navigator.pushNamedAndRemoveUntil(context, '/issues', (_) => false);
        break;
      case SidebarPage.create:
        Navigator.pushNamed(context, '/create');
        break;
      case SidebarPage.history:
        Navigator.pushNamedAndRemoveUntil(context, '/history', (_) => false);
        break;
    }
  }
}

class _NavItem extends StatelessWidget {
  final String icon;
  final String label;
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
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 9),
          Expanded(child: Text(label,
            style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w400,
              color: active ? AppTheme.accent : AppTheme.textMuted))),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (badgeColor ?? AppTheme.accent),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(badge!,
                style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  color: badgeColor != null ? Colors.white : AppTheme.ink)),
            ),
        ]),
      ),
    );
  }
}

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
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Center(child: Text(initials,
        style: GoogleFonts.syne(
          fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.ink))),
    );
  }
}

/// Public avatar widget used in other screens
class UserAvatar extends StatelessWidget {
  final String name;
  final double size;
  const UserAvatar({super.key, required this.name, this.size = 32});

  @override
  Widget build(BuildContext context) {
    final initials = name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : name.toUpperCase();
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.22),
        gradient: const LinearGradient(
          colors: [AppTheme.accent, AppTheme.blue],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Center(child: Text(initials,
        style: GoogleFonts.syne(
          fontSize: size * 0.35, fontWeight: FontWeight.w700,
          color: AppTheme.ink))),
    );
  }
}
