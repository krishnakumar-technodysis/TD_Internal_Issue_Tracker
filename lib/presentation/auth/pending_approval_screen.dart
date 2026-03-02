// lib/presentation/auth/pending_approval_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import 'auth_viewmodel.dart';

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm         = context.watch<AuthViewModel>();
    final user           = authVm.currentUser;
    final isDisabled     = user?.isDisabled == true;
    final justRegistered = authVm.registeredJustNow;

    final accentColor = isDisabled ? AppTheme.red : AppTheme.orange;
    final icon        = isDisabled ? '🚫' : '⏳';
    final heading     = isDisabled
        ? 'Account Disabled'
        : justRegistered ? 'Registration Submitted!' : 'Awaiting Approval';
    final body        = isDisabled
        ? 'Your account has been disabled by an administrator. Please contact your administrator for assistance.'
        : justRegistered
        ? "Your account has been created and is pending admin review. You'll be able to log in once approved."
        : 'Your account is waiting for admin approval. Please check back later or contact your administrator.';

    return Scaffold(
      backgroundColor: AppTheme.ink,
      body: Stack(children: [

        // ── Background glows ───────────────────────────
        Positioned(top: -120, left: -120,
            child: _Glow(color: accentColor.withOpacity(0.06))),
        Positioned(bottom: -120, right: -120,
            child: _Glow(color: AppTheme.blue.withOpacity(0.06))),

        // ── Content ────────────────────────────────────
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  // ── Icon ─────────────────────────────
                  Container(
                      width: 88, height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accentColor.withOpacity(0.1),
                        border: Border.all(
                            color: accentColor.withOpacity(0.3), width: 1.5),
                      ),
                      child: Center(child: Text(icon,
                          style: const TextStyle(fontSize: 38)))),
                  const SizedBox(height: 28),

                  // ── Heading ───────────────────────────
                  Text(heading,
                      style: GoogleFonts.dmSans(
                          fontSize: 24, fontWeight: FontWeight.w700,
                          color: AppTheme.textColor, letterSpacing: -0.4),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),

                  // ── Body ──────────────────────────────
                  Text(body,
                      style: const TextStyle(
                          fontSize: 14, color: AppTheme.textMuted, height: 1.6),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 32),

                  // ── Info card ─────────────────────────
                  if (user != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('YOUR DETAILS',
                              style: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w700,
                                  color: AppTheme.textDim, letterSpacing: 1.3)),
                          const SizedBox(height: 14),
                          _InfoRow(icon: Icons.person_outline_rounded,
                              label: 'Name', value: user.displayName),
                          const SizedBox(height: 10),
                          _InfoRow(icon: Icons.email_outlined,
                              label: 'Email', value: user.email),
                          if (user.department.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            _InfoRow(icon: Icons.work_outline_rounded,
                                label: 'Department', value: user.department),
                          ],
                          const SizedBox(height: 10),
                          _InfoRow(
                              icon: isDisabled
                                  ? Icons.block_rounded
                                  : Icons.pending_outlined,
                              label: 'Status',
                              value: isDisabled ? 'Disabled' : 'Pending Review',
                              valueColor: accentColor),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),

                  // ── Info banner ───────────────────────
                  if (!isDisabled)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.accentBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppTheme.accent.withOpacity(0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 16, color: AppTheme.accent),
                          const SizedBox(width: 10),
                          const Expanded(child: Text(
                              'An admin will review your request. Once approved, '
                                  'return to this page and sign in to access the portal.',
                              style: TextStyle(
                                  fontSize: 13, color: AppTheme.accent, height: 1.5))),
                        ],
                      ),
                    ),
                  const SizedBox(height: 28),

                  // ── Actions ───────────────────────────
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => authVm.signOut(),
                        icon: const Icon(Icons.logout_rounded, size: 16),
                        label: const Text('Sign Out'),
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13)),
                      ),
                    ),
                    if (!isDisabled) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => authVm.refreshStatus(),
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Check Status'),
                          style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 13)),
                        ),
                      ),
                    ],
                  ]),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color? valueColor;
  const _InfoRow({required this.icon, required this.label,
    required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 15, color: AppTheme.textDim),
    const SizedBox(width: 8),
    Text('$label: ', style: const TextStyle(
        fontSize: 13, color: AppTheme.textMuted)),
    Expanded(child: Text(value, style: TextStyle(
        fontSize: 13, fontWeight: FontWeight.w500,
        color: valueColor ?? AppTheme.textColor),
        overflow: TextOverflow.ellipsis)),
  ]);
}

class _Glow extends StatelessWidget {
  final Color color;
  const _Glow({required this.color});

  @override
  Widget build(BuildContext context) => Container(
      width: 400, height: 400,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
              colors: [color, Colors.transparent])));
}