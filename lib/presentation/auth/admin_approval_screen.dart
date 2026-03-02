// lib/presentation/auth/admin_approval_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/user_entity.dart';
import '../widgets/app_shell.dart';
import '../widgets/app_sidebar.dart';
import 'auth_viewmodel.dart';

class AdminApprovalScreen extends StatelessWidget {
  const AdminApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();

    return AppShell(
      activePage: SidebarPage.approvals,
      child: StreamBuilder<List<dynamic>>(
        stream: authVm.pendingUsersStream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.accent));
          }
          final users = snap.data ?? <UserEntity>[];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Header ──────────────────────────────
                Row(children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('User Approvals',
                          style: GoogleFonts.dmSans(
                              fontSize: 22, fontWeight: FontWeight.w700,
                              color: AppTheme.textColor,
                              letterSpacing: -0.4)),
                      const SizedBox(height: 3),
                      Text(
                          users.isEmpty
                              ? 'No pending requests'
                              : '${users.length} user${users.length != 1 ? 's' : ''} awaiting approval',
                          style: const TextStyle(
                              fontSize: 13, color: AppTheme.textMuted)),
                    ],
                  )),
                  // Badge
                  if (users.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.orangeBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppTheme.orange.withOpacity(0.3)),
                      ),
                      child: Row(children: [
                        Container(width: 7, height: 7,
                            decoration: const BoxDecoration(
                                color: AppTheme.orange,
                                shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text('${users.length} Pending',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600,
                                color: AppTheme.orange)),
                      ]),
                    ),
                ]),
                const SizedBox(height: 24),

                // ── Empty state ──────────────────────────
                if (users.isEmpty)
                  _EmptyState()
                else
                // ── User cards ───────────────────────
                  ...users.map((user) =>
                      _UserApprovalCard(
                        user:       user,
                        onApprove:  () => _approve(context, authVm, user),
                        onReject:   () => _reject(context, authVm, user),
                      ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _approve(
      BuildContext context, AuthViewModel vm, UserEntity user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(
        title:   'Approve ${user.displayName}?',
        message: '${user.displayName} (${user.email}) will be granted access to the portal.',
        confirmLabel: 'Approve',
        confirmColor: AppTheme.green,
      ),
    );
    if (ok == true && context.mounted) {
      await vm.approveUser(user.uid);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(_snack(
            '${user.displayName} approved — they can now log in',
            AppTheme.green));
      }
    }
  }

  Future<void> _reject(
      BuildContext context, AuthViewModel vm, UserEntity user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(
        title:   'Reject ${user.displayName}?',
        message: '${user.displayName} (${user.email}) will be denied access. This can be reversed by editing their Firestore record.',
        confirmLabel: 'Reject',
        confirmColor: AppTheme.red,
      ),
    );
    if (ok == true && context.mounted) {
      await vm.rejectUser(user.uid);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(_snack(
            '${user.displayName}\'s request was rejected',
            AppTheme.red));
      }
    }
  }

  SnackBar _snack(String msg, Color color) => SnackBar(
    content: Row(children: [
      Icon(Icons.check_circle_outline_rounded,
          color: color, size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(msg,
          style: const TextStyle(color: AppTheme.textColor))),
    ]),
    backgroundColor: AppTheme.card,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppTheme.border)),
  );
}

// ─────────────────────────────────────────────────────────────────────
// User card
// ─────────────────────────────────────────────────────────────────────
class _UserApprovalCard extends StatelessWidget {
  final UserEntity user;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  const _UserApprovalCard({
    required this.user,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: isWide
          ? Row(crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _Avatar(name: user.displayName),
            const SizedBox(width: 14),
            Expanded(child: _UserInfo(user: user)),
            const SizedBox(width: 16),
            _ActionButtons(
                onApprove: onApprove, onReject: onReject),
          ])
          : Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              _Avatar(name: user.displayName),
              const SizedBox(width: 12),
              Expanded(child: _UserInfo(user: user)),
            ]),
            const SizedBox(height: 14),
            _ActionButtons(
                onApprove: onApprove,
                onReject: onReject,
                fullWidth: true),
          ]),
    );
  }
}

class _UserInfo extends StatelessWidget {
  final UserEntity user;
  const _UserInfo({required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Name + pending badge
      Row(children: [
        Flexible(child: Text(user.displayName,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600,
                color: AppTheme.textColor),
            overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 8),
        Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
                color: AppTheme.orangeBg,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color: AppTheme.orange.withOpacity(0.25))),
            child: const Text('Pending',
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: AppTheme.orange))),
      ]),
      const SizedBox(height: 5),
      // Email
      Row(children: [
        const Icon(Icons.email_outlined,
            size: 13, color: AppTheme.textDim),
        const SizedBox(width: 5),
        Flexible(child: Text(user.email,
            style: const TextStyle(
                fontSize: 12.5, color: AppTheme.textMuted),
            overflow: TextOverflow.ellipsis)),
      ]),
      const SizedBox(height: 3),
      // Department + date
      Row(children: [
        if (user.department.isNotEmpty) ...[
          const Icon(Icons.work_outline_rounded,
              size: 13, color: AppTheme.textDim),
          const SizedBox(width: 5),
          Text(user.department,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(width: 14),
        ],
        const Icon(Icons.access_time_rounded,
            size: 13, color: AppTheme.textDim),
        const SizedBox(width: 5),
        Text(
            'Requested ${DateFormat('dd MMM yyyy').format(user.createdAt)}',
            style: const TextStyle(
                fontSize: 12, color: AppTheme.textDim)),
      ]),
    ]);
  }
}

class _ActionButtons extends StatelessWidget {
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final bool fullWidth;
  const _ActionButtons({
    required this.onApprove,
    required this.onReject,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final approve = ElevatedButton.icon(
      onPressed: onApprove,
      icon: const Icon(Icons.check_rounded, size: 15),
      label: const Text('Approve'),
      style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
              horizontal: 18, vertical: 10)),
    );
    final reject = OutlinedButton.icon(
      onPressed: onReject,
      icon: const Icon(Icons.close_rounded, size: 15),
      label: const Text('Reject'),
      style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.red,
          side: BorderSide(color: AppTheme.red.withOpacity(0.4)),
          padding: const EdgeInsets.symmetric(
              horizontal: 18, vertical: 10)),
    );

    if (fullWidth) {
      return Row(children: [
        Expanded(child: reject),
        const SizedBox(width: 10),
        Expanded(child: approve),
      ]);
    }
    return Row(mainAxisSize: MainAxisSize.min, children: [
      reject,
      const SizedBox(width: 10),
      approve,
    ]);
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(' ')
        .take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
            colors: [AppTheme.orange, AppTheme.yellow],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
      ),
      child: Center(child: Text(initials,
          style: GoogleFonts.dmSans(
              fontSize: 14, fontWeight: FontWeight.w700,
              color: Colors.white))),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 60),
    decoration: BoxDecoration(
      color: AppTheme.card,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.border),
    ),
    child: Column(children: [
      Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.greenBg,
              border: Border.all(
                  color: AppTheme.green.withOpacity(0.25))),
          child: const Center(
              child: Text('✓', style: TextStyle(
                  fontSize: 28, color: AppTheme.green)))),
      const SizedBox(height: 16),
      const Text('All caught up!',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600,
              color: AppTheme.textColor)),
      const SizedBox(height: 6),
      const Text(
          'No pending approval requests',
          style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────
// Confirm dialog
// ─────────────────────────────────────────────────────────────────────
class _ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final Color confirmColor;
  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.confirmColor,
  });

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: AppTheme.card,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.border)),
    title: Text(title,
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700,
            color: AppTheme.textColor)),
    content: Text(message,
        style: const TextStyle(
            fontSize: 13.5, color: AppTheme.textMuted, height: 1.5)),
    actions: [
      TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel')),
      ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white),
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel)),
    ],
  );
}