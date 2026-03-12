// lib/presentation/admin/admin_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:issue_tracker/presentation/setting/settings_view_model.dart' as issue_tracker;
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/user_entity.dart';
import '../auth/auth_viewmodel.dart';
import '../widgets/app_shell.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/form_widgets.dart';
import '../widgets/app_button.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      activePage: SidebarPage.admin,
      child: DefaultTabController(
        length: 2,
        child: Column(children: [
          // ── Tab bar header ────────────────────────────
          Container(
            color: AppTheme.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Admin Panel',
                          style: GoogleFonts.dmSans(
                              fontSize: 22, fontWeight: FontWeight.w700,
                              color: AppTheme.textColor, letterSpacing: -0.4)),
                      const SizedBox(height: 3),
                      const Text('Manage users and create accounts',
                          style: TextStyle(
                              fontSize: 13, color: AppTheme.textMuted)),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                TabBar(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  tabs: const [
                    Tab(text: 'All Users'),
                    Tab(text: 'Create User'),
                  ],
                  labelStyle: GoogleFonts.dmSans(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 13),
                ),
                const Divider(height: 1, color: AppTheme.border),
              ],
            ),
          ),

          // ── Tab content ───────────────────────────────
          Expanded(
            child: TabBarView(children: [
              _UserListTab(),
              const _CreateUserTab(),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Tab 1 — All Users
// ─────────────────────────────────────────────────────────────────────
class _UserListTab extends StatefulWidget {
  @override
  State<_UserListTab> createState() => _UserListTabState();
}

class _UserListTabState extends State<_UserListTab> {
  String _filterRole   = 'All';
  String _filterStatus = 'All';

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();

    return StreamBuilder<List<UserEntity>>(
      stream: authVm.allUsersStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.accent));
        }

        final all = snap.data ?? <UserEntity>[];

        // Filter
        final filtered = all.where((u) {
          final roleOk = _filterRole   == 'All' || u.role   == _filterRole.toLowerCase();
          final statOk = _filterStatus == 'All' || u.status == _filterStatus.toLowerCase();
          return roleOk && statOk;
        }).toList();

        return Column(children: [
          // ── Filter bar ────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
            decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: AppTheme.border))),
            child: Row(children: [
              Text('${all.length} users',
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textMuted,
                      fontWeight: FontWeight.w500)),
              const Spacer(),
              // Role filter
              _FilterChip(
                value: _filterRole,
                options: const ['All', 'Admin', 'User'],
                onChanged: (v) => setState(() => _filterRole = v),
              ),
              const SizedBox(width: 8),
              // Status filter
              _FilterChip(
                value: _filterStatus,
                options: const ['All', 'Approved', 'Pending', 'Rejected'],
                onChanged: (v) => setState(() => _filterStatus = v),
              ),
            ]),
          ),

          // ── List ──────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? _emptyState('No users match the selected filters')
                : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: filtered.length,
              separatorBuilder: (_, __) =>
              const SizedBox(height: 8),
              itemBuilder: (context, i) =>
                  _UserRow(
                    user: filtered[i],
                    onRoleChange: (role) =>
                        _changeRole(context, authVm, filtered[i], role),
                    onDelete:  () => _delete(context, authVm, filtered[i]),
                    onDisable:        () => _disable(context, authVm, filtered[i]),
                    onEnable:         () => _enable(context, authVm, filtered[i]),
                    onResetPassword:  () => _resetPassword(context, authVm, filtered[i]),
                  ),
            ),
          ),
        ]);
      },
    );
  }

  Future<void> _changeRole(BuildContext context, AuthViewModel vm,
      UserEntity user, String newRole) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(
        title:   'Change role for ${user.displayName}?',
        message: 'Set role to ${newRole.toUpperCase()}. This affects what they can access.',
        confirmLabel: 'Change Role',
        confirmColor: AppTheme.accent,
      ),
    );
    if (ok == true && context.mounted) {
      await vm.updateUserRole(user.uid, newRole);
      if (context.mounted) _snack(context, 'Role updated', AppTheme.green);
    }
  }

  Future<void> _disable(
      BuildContext context, AuthViewModel vm, UserEntity user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(
        title:   'Disable ${user.displayName}?',
        message: '${user.displayName} will not be able to log in. Their data and issues will be kept. You can re-enable them at any time.',
        confirmLabel: 'Disable',
        confirmColor: AppTheme.orange,
      ),
    );
    if (ok == true && context.mounted) {
      await vm.disableUser(user.uid);
      if (context.mounted) _snack(context, '${user.displayName} has been disabled', AppTheme.orange);
    }
  }

  Future<void> _enable(
      BuildContext context, AuthViewModel vm, UserEntity user) async {
    await vm.enableUser(user.uid);
    if (context.mounted) _snack(context, '${user.displayName} has been re-enabled', AppTheme.green);
  }

  Future<void> _resetPassword(
      BuildContext context, AuthViewModel vm, UserEntity user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(
        title:   'Reset password for ${user.displayName}?',
        message: 'A password reset link will be sent to ${user.email}. They can use it to set a new password.',
        confirmLabel: 'Send Reset Link',
        confirmColor: AppTheme.blue,
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await vm.sendPasswordReset(user.email);
      if (context.mounted) _snack(context, 'Reset link sent to ${user.email}', AppTheme.blue);
    } catch (e) {
      if (context.mounted) _snack(context, 'Failed to send reset link', AppTheme.red);
    }
  }

  Future<void> _delete(BuildContext context, AuthViewModel vm,
      UserEntity user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(
        title:   'Remove ${user.displayName}?',
        message: 'This removes their Firestore record. Their Firebase Auth account will remain — delete it manually in the Firebase Console.',
        confirmLabel: 'Remove',
        confirmColor: AppTheme.red,
      ),
    );
    if (ok == true && context.mounted) {
      await vm.deleteUser(user.uid);
      if (context.mounted) _snack(context, 'User removed', AppTheme.red);
    }
  }

  void _snack(BuildContext ctx, String msg, Color color) =>
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Row(children: [
          Icon(Icons.check_circle_outline_rounded, color: color, size: 15),
          const SizedBox(width: 8),
          Text(msg, style: const TextStyle(color: AppTheme.textColor)),
        ]),
        backgroundColor: AppTheme.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: AppTheme.border)),
      ));
}

// ─────────────────────────────────────────────────────────────────────
// Tab 2 — Create User
// ─────────────────────────────────────────────────────────────────────
class _CreateUserTab extends StatefulWidget {
  const _CreateUserTab();

  @override
  State<_CreateUserTab> createState() => _CreateUserTabState();
}

class _CreateUserTabState extends State<_CreateUserTab> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  String  _role       = AppConstants.roleUser;
  String  _department = '';
  bool    _loading = false;
  bool    _obscure = true;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; _success = null; });
    try {
      await context.read<AuthViewModel>().createUser(
        email:       _emailCtrl.text.trim(),
        password:    _passCtrl.text,
        displayName: _nameCtrl.text.trim(),
        role:        _role,
        department:  _department,
      );
      final name = _nameCtrl.text.trim();
      _nameCtrl.clear(); _emailCtrl.clear(); _passCtrl.clear();
      setState(() {
        _success = 'User "$name" created successfully.';
        _role = AppConstants.roleUser;
        _department = '';
      });
      if (mounted) DefaultTabController.of(context).animateTo(0);
    } catch (e) {
      setState(() => _error = _parseErr(e.toString()));
    } finally {
      setState(() => _loading = false);
    }
  }

  String _parseErr(String e) {
    if (e.contains('email-already-in-use')) return 'An account already exists for this email.';
    if (e.contains('weak-password'))        return 'Password must be at least 6 characters.';
    if (e.contains('invalid-email'))        return 'Invalid email address.';
    return 'Failed to create user. Try again.';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              if (_success != null) ...[
                _Banner(msg: _success!, color: AppTheme.green, bg: AppTheme.greenBg,
                    icon: Icons.check_circle_outline_rounded),
                const SizedBox(height: 16),
              ],
              if (_error != null) ...[
                _Banner(msg: _error!, color: AppTheme.red, bg: AppTheme.redBg,
                    icon: Icons.error_outline_rounded),
                const SizedBox(height: 16),
              ],

              TField(
                label: 'Full Name', controller: _nameCtrl,
                isRequired: true, maxLength: 60,
                hint: 'e.g. Tendai Moyo',
                validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 14),
              TField(
                label: 'Email Address', controller: _emailCtrl,
                isRequired: true,
                hint: 'user@technodysis.com',
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TField(
                label: 'Password', controller: _passCtrl,
                isRequired: true, obscureText: _obscure,
                hint: 'Min 6 characters',
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 18, color: AppTheme.textDim),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                validator: (v) => v == null || v.length < 6 ? 'Minimum 6 characters' : null,
              ),
              const SizedBox(height: 14),

              // Department — pulled from Firestore settings
              _DepartmentDropdown(
                value: _department.isEmpty ? null : _department,
                onChanged: (v) => setState(() => _department = v ?? ''),
              ),
              const SizedBox(height: 14),

              // Role with description chips
              _RolePicker(
                value: _role,
                onChanged: (v) => setState(() => _role = v),
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'Create User Account',
                  loading: _loading,
                  onPressed: _create,
                  height: 46,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// User row card
// ─────────────────────────────────────────────────────────────────────
class _UserRow extends StatelessWidget {
  final UserEntity user;
  final void Function(String) onRoleChange;
  final VoidCallback onDelete;
  final VoidCallback onDisable;
  final VoidCallback onEnable;
  final VoidCallback onResetPassword;
  const _UserRow({
    required this.user,
    required this.onRoleChange,
    required this.onDelete,
    required this.onDisable,
    required this.onEnable,
    required this.onResetPassword,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = user.isApproved ? AppTheme.green
        : user.isPending   ? AppTheme.orange
        : user.isDisabled  ? AppTheme.textDim
        : AppTheme.red;
    final statusBg = user.isApproved ? AppTheme.greenBg
        : user.isPending   ? AppTheme.orangeBg
        : user.isDisabled  ? AppTheme.border
        : AppTheme.redBg;
    final statusLabel = user.status[0].toUpperCase() + user.status.substring(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(children: [
        // Avatar
        _Initials(name: user.displayName, isAdmin: user.isAdmin),
        const SizedBox(width: 12),

        // Info
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Flexible(child: Text(user.displayName,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: AppTheme.textColor),
                  overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              // Role badge
              _Badge(
                label: user.role.toUpperCase(),
                color: user.isAdmin ? AppTheme.accent : AppTheme.blue,
                bg: user.isAdmin ? AppTheme.accentBg : AppTheme.blueBg,
              ),
            ]),
            const SizedBox(height: 3),
            Text(user.email,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textMuted),
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Row(children: [
              // Status
              _Badge(
                  label: statusLabel,
                  color: statusColor, bg: statusBg),
              if (user.department.isNotEmpty) ...[
                const SizedBox(width: 8),
                Flexible(child: Text(user.department,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textDim),
                    overflow: TextOverflow.ellipsis)),
              ],
              const SizedBox(width: 8),
              Text(
                  DateFormat('dd MMM yy').format(user.createdAt),
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textDim)),
            ]),
          ],
        )),
        const SizedBox(width: 8),

        // Actions
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded,
              size: 18, color: AppTheme.textDim),
          color: AppTheme.card,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: AppTheme.border)),
          onSelected: (v) {
            if (v == 'delete')   { onDelete();        return; }
            if (v == 'disable')  { onDisable();       return; }
            if (v == 'enable')   { onEnable();        return; }
            if (v == 'reset')    { onResetPassword(); return; }
            onRoleChange(v);
          },
          itemBuilder: (_) {
            final authVm = context.read<AuthViewModel>();
            final isSuperAdmin = authVm.currentUser?.email ==
                AppConstants.superAdminEmail;
            return [
              if (!user.isAdmin)
                _menuItem('admin',   '⬆ Promote to Admin',  AppTheme.accent),
              if (user.isAdmin)
                _menuItem('user',    '⬇ Demote to User',    AppTheme.orange),
              if (!user.isDisabled)
                _menuItem('disable', '🚫 Disable User',     AppTheme.orange),
              if (user.isDisabled)
                _menuItem('enable',  '✅ Enable User',      AppTheme.green),
              // Only super admin can reset passwords
              if (isSuperAdmin)
                _menuItem('reset',   '🔑 Reset Password',   AppTheme.blue),
              _menuItem('delete',  '✕ Remove User',         AppTheme.red),
            ];
          },
        ),
      ]),
    );
  }

  PopupMenuItem<String> _menuItem(String val, String label, Color color) =>
      PopupMenuItem(
        value: val,
        child: Text(label,
            style: TextStyle(fontSize: 13, color: color,
                fontWeight: FontWeight.w500)),
      );
}

// ─────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────
class _Initials extends StatelessWidget {
  final String name;
  final bool isAdmin;
  const _Initials({required this.name, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(' ')
        .take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
    return Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        gradient: LinearGradient(
            colors: isAdmin
                ? [AppTheme.accent, AppTheme.blue]
                : [AppTheme.blue, AppTheme.purple],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Center(child: Text(initials,
          style: GoogleFonts.dmSans(
              fontSize: 12, fontWeight: FontWeight.w700,
              color: Colors.white))),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color, bg;
  const _Badge({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.25))),
    child: Text(label,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w700, color: color)),
  );
}

class _FilterChip extends StatelessWidget {
  final String value;
  final List<String> options;
  final void Function(String) onChanged;
  const _FilterChip({
    required this.value, required this.options, required this.onChanged});

  @override
  Widget build(BuildContext context) =>
      DropdownButton<String>(
        value: value,
        isDense: true,
        underline: const SizedBox(),
        style: const TextStyle(fontSize: 12.5, color: AppTheme.textColor),
        dropdownColor: AppTheme.card,
        borderRadius: BorderRadius.circular(8),
        items: options.map((o) => DropdownMenuItem(
            value: o,
            child: Text(o,
                style: const TextStyle(fontSize: 12.5)))).toList(),
        onChanged: (v) => onChanged(v!),
      );
}

class _Banner extends StatelessWidget {
  final String msg;
  final Color color, bg;
  final IconData icon;
  const _Banner({required this.msg, required this.color,
    required this.bg, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25))),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 8),
      Expanded(child: Text(msg,
          style: TextStyle(fontSize: 13, color: color, height: 1.5))),
    ]),
  );
}

class _ConfirmDialog extends StatelessWidget {
  final String title, message, confirmLabel;
  final Color confirmColor;
  const _ConfirmDialog({
    required this.title, required this.message,
    required this.confirmLabel, required this.confirmColor});

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: AppTheme.card,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.border)),
    title: Text(title, style: const TextStyle(
        fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textColor)),
    content: Text(message, style: const TextStyle(
        fontSize: 13.5, color: AppTheme.textMuted, height: 1.5)),
    actions: [
      TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel')),
      ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor, foregroundColor: Colors.white),
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel)),
    ],
  );
}

Widget _emptyState(String msg) => Center(
  child: Padding(
    padding: const EdgeInsets.all(40),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('👤', style: TextStyle(fontSize: 32)),
      const SizedBox(height: 12),
      Text(msg, style: const TextStyle(
          fontSize: 13, color: AppTheme.textDim)),
    ]),
  ),
);

// ── Department dropdown (reads from Firestore) ────────────
class _DepartmentDropdown extends StatelessWidget {
  final String? value;
  final void Function(String?) onChanged;
  const _DepartmentDropdown({this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    // Import inline to avoid circular import
    final vm = context.read<issue_tracker.SettingsViewModel>();
    return StreamBuilder<List<dynamic>>(
      stream: vm.departmentsStream,
      builder: (context, snap) {
        final depts = (snap.data ?? [])
            .where((d) => d.isActive)
            .map((d) => d.name as String)
            .toList();

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('DEPARTMENT',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700,
                  color: AppTheme.textMuted, letterSpacing: 0.7)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: (value != null && depts.contains(value)) ? value : null,
            hint: const Text('Select department',
                style: TextStyle(color: AppTheme.textDim, fontSize: 13)),
            decoration: InputDecoration(
                filled: true, fillColor: AppTheme.cardAlt,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.borderLight)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.borderLight)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.accent, width: 1.5))),
            dropdownColor: AppTheme.card,
            items: depts.map((d) => DropdownMenuItem(
              value: d,
              child: Text(d, style: const TextStyle(
                  fontSize: 13, color: AppTheme.textColor)),
            )).toList(),
            onChanged: onChanged,
          ),
        ]);
      },
    );
  }
}

// ── Role picker with description ──────────────────────────
class _RolePicker extends StatelessWidget {
  final String value;
  final void Function(String) onChanged;
  const _RolePicker({required this.value, required this.onChanged});

  static const _roles = [
    (id: 'user',    label: 'User',    icon: '👤', desc: 'Can create & view issues, view assigned projects'),
    (id: 'manager', label: 'Manager', icon: '👔', desc: 'All user access + create projects, manage team'),
    (id: 'admin',   label: 'Admin',   icon: '🛡️',  desc: 'Full access — users, settings, approvals'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('ROLE *',
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700,
              color: AppTheme.textMuted, letterSpacing: 0.7)),
      const SizedBox(height: 8),
      Column(children: _roles.map((r) {
        final selected = value == r.id;
        return GestureDetector(
          onTap: () => onChanged(r.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: selected ? AppTheme.accent.withOpacity(0.1) : AppTheme.cardAlt,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: selected ? AppTheme.accent : AppTheme.border,
                    width: selected ? 1.5 : 1)),
            child: Row(children: [
              Text(r.icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.label,
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600,
                          color: selected ? AppTheme.accent : AppTheme.textColor)),
                  Text(r.desc,
                      style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted)),
                ],
              )),
              if (selected)
                const Icon(Icons.check_circle_rounded,
                    color: AppTheme.accent, size: 18),
            ]),
          ),
        );
      }).toList()),
    ]);
  }
}