// lib/presentation/projects/create_project_screen.dart
import 'package:flutter/material.dart';
import 'package:issue_tracker/presentation/projects/project_view_model.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/project_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../auth/auth_viewmodel.dart';
import '../setting/settings_view_model.dart';
import '../widgets/form_widgets.dart';

class CreateProjectScreen extends StatefulWidget {
  final ProjectEntity? existing;
  const CreateProjectScreen({super.key, this.existing});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String    _client   = '';
  String    _priority = 'Medium';
  String    _status   = 'active';
  DateTime? _startDate;
  DateTime? _endDate;
  List<String> _selectedMemberUids = [];

  bool get isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final p        = widget.existing!;
      _nameCtrl.text = p.name;
      _descCtrl.text = p.description;
      _client        = p.client;
      _priority      = p.priority;
      _status        = p.status;
      _startDate     = p.startDate;
      _endDate       = p.endDate;
      _selectedMemberUids = List.from(p.memberUids);
    }
  }

  @override
  void dispose() { _nameCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final authVm = context.read<AuthViewModel>();
    final vm     = context.read<ProjectViewModel>();
    final user   = authVm.currentUser;
    if (user == null) return;

    final data = {
      'name':        _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'client':      _client,
      'priority':    _priority,
      'status':      _status,
      'startDate':   _startDate,
      'endDate':     _endDate,
      'memberUids':  _selectedMemberUids,
    };

    bool ok;
    if (isEdit) {
      ok = await vm.updateProject(id: widget.existing!.id, data: data, by: user);
    } else {
      ok = await vm.createProject(data: data, by: user);
    }
    if (!mounted) return;
    if (ok) {
      Navigator.pushNamedAndRemoveUntil(context, '/projects', (_) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppTheme.red,
        content: Text(
          isEdit ? 'Failed to update project. Please try again.'
                 : 'Failed to create project. Please try again.',
          style: const TextStyle(color: Colors.white),
        ),
      ));
    }
  }

  Future<void> _confirmDelete() async {
    final vm = context.read<ProjectViewModel>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(children: [
          Container(padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: AppTheme.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.delete_outline_rounded,
                  color: AppTheme.red, size: 20)),
          const SizedBox(width: 12),
          const Text('Delete Project',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                  color: AppTheme.textColor)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(text: TextSpan(
                style: const TextStyle(fontSize: 13.5, color: AppTheme.textMuted, height: 1.5),
                children: [
                  const TextSpan(text: 'Are you sure you want to delete '),
                  TextSpan(
                      text: '"${widget.existing!.name}"',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textColor)),
                  const TextSpan(text: '?'),
                ],
              )),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: AppTheme.red.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.red.withOpacity(0.2))),
                child: const Row(children: [
                  Icon(Icons.warning_amber_rounded, color: AppTheme.red, size: 15),
                  SizedBox(width: 8),
                  Expanded(child: Text(
                      'This will permanently delete the project and all its tasks. This action cannot be undone.',
                      style: TextStyle(fontSize: 12, color: AppTheme.red))),
                ]),
              ),
            ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
              child: const Text('Yes, Delete')),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await vm.deleteProject(widget.existing!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final vm     = context.watch<ProjectViewModel>();

    return Scaffold(
      backgroundColor: AppTheme.ink,
      body: StreamBuilder(
        stream: authVm.allUsersStream,
        builder: (_, userSnap) {
          final users = (userSnap.data ?? authVm.allUsers)
              .where((u) => u.canLogin).toList()
            ..sort((a, b) => a.displayName.compareTo(b.displayName));
          return SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Form(
              key: _formKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // ── Header ─────────────────────────────────────────────
                Row(children: [
                  IconButton(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/projects', (_) => false),
                      icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textMuted)),
                  const SizedBox(width: 4),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(isEdit ? 'Edit Project' : 'Create New Project',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                            color: AppTheme.textColor)),
                    Text(isEdit ? 'Update project details' : 'Fill in the details below',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                  ])),
                  // Delete button (edit mode only)
                  if (isEdit)
                    TextButton.icon(
                      onPressed: _confirmDelete,
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: AppTheme.red, size: 18),
                      label: const Text('Delete',
                          style: TextStyle(color: AppTheme.red, fontSize: 13)),
                      style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    ),
                ]),
                const SizedBox(height: 24),

                // ── Project Name ────────────────────────────────────────
                TField(
                  label: 'Project Name', controller: _nameCtrl, isRequired: true,
                  hint: 'e.g. Ecocash Payment Automation',
                  validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 14),

                // ── Description ─────────────────────────────────────────
                TField(
                  label: 'Description', controller: _descCtrl,
                  hint: 'Brief overview of the project scope and goals',
                  maxLines: 3,
                ),
                const SizedBox(height: 14),

                // ── Client + Priority ───────────────────────────────────
                StreamBuilder(
                  stream: context.read<SettingsViewModel>().clientsStream,
                  builder: (_, snap) {
                    final clients = (snap.data ?? [])
                        .where((c) => c.isActive).map((c) => c.name).toList();

                    // Ensure _client is always valid:
                    // 1. On create: default to first item when loaded
                    // 2. On edit: keep existing value; if not in list add it so dropdown works
                    final effectiveClients = List<String>.from(clients);
                    if (_client.isNotEmpty && !effectiveClients.contains(_client)) {
                      effectiveClients.insert(0, _client); // keep existing value valid
                    }
                    if (effectiveClients.isNotEmpty && _client.isEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback(
                              (_) => setState(() => _client = effectiveClients.first));
                    }

                    return FormRow(
                      breakpoint: 600,
                      children: [
                        TDropdown(
                          label: 'Client', isRequired: true,
                          value: _client.isEmpty ? null : _client,
                          hint: 'Select client',
                          items: effectiveClients.isEmpty
                              ? AppConstants.customers
                              : effectiveClients,
                          onChanged: (v) => setState(() => _client = v ?? ''),
                          validator: (v) =>
                          v == null || v.isEmpty ? 'Client is required' : null,
                        ),
                        TDropdown(
                          label: 'Priority', value: _priority,
                          items: AppConstants.priorities,
                          onChanged: (v) => setState(() => _priority = v!),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),

                // ── Status + Start Date ─────────────────────────────────
                FormRow(
                  breakpoint: 600,
                  children: [
                    TDropdown(
                      label: 'Status', value: _status,
                      items: AppConstants.projectStatuses,
                      displayItems: AppConstants.projectStatuses
                          .map(AppConstants.projectStatusLabel).toList(),
                      onChanged: (v) => setState(() => _status = v!),
                    ),
                    TDatePicker(
                      label: 'Start Date',
                      value: _startDate,
                      onChanged: (d) => setState(() {
                        _startDate = d;
                        if (_endDate != null && d != null && _endDate!.isBefore(d)) {
                          _endDate = null;
                        }
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── End Date ────────────────────────────────────────────
                TDatePicker(
                  label: 'End Date (Deadline)',
                  value: _endDate,
                  firstDate: _startDate,
                  onChanged: (d) => setState(() => _endDate = d),
                ),
                const SizedBox(height: 14),

                // ── Timeline banner ─────────────────────────────────────
                if (_startDate != null || _endDate != null)
                  _TimelineBanner(startDate: _startDate, endDate: _endDate),
                if (_startDate != null || _endDate != null) const SizedBox(height: 14),

                // ── Team Members ────────────────────────────────────────
                _TeamMemberPicker(
                  users: users,
                  selectedUids: _selectedMemberUids,
                  onToggle: (uid) => setState(() {
                    _selectedMemberUids.contains(uid)
                        ? _selectedMemberUids.remove(uid)
                        : _selectedMemberUids.add(uid);
                  }),
                ),
                const SizedBox(height: 28),

                // ── Submit ──────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: vm.isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppTheme.accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                    child: vm.isLoading
                        ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2,
                            color: Colors.white))
                        : Text(isEdit ? 'Save Changes' : 'Create Project',
                        style: const TextStyle(fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Timeline banner
// ─────────────────────────────────────────────────────────────────────
class _TimelineBanner extends StatelessWidget {
  final DateTime? startDate, endDate;
  const _TimelineBanner({this.startDate, this.endDate});

  @override
  Widget build(BuildContext context) {
    final now      = DateTime.now();
    final isOverdue = endDate != null && endDate!.isBefore(now);
    final daysLeft  = endDate != null ? endDate!.difference(now).inDays : null;
    final color = isOverdue ? AppTheme.red
        : daysLeft != null && daysLeft <= 7 ? AppTheme.orange
        : AppTheme.green;
    final fmt = DateFormat('dd MMM yyyy');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Row(children: [
        Icon(isOverdue ? Icons.warning_rounded : Icons.schedule_rounded,
            color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            if (startDate != null) ...[
              Text('Start: ${fmt.format(startDate!)}',
                  style: TextStyle(fontSize: 12, color: color,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 12),
            ],
            if (endDate != null)
              Text('Deadline: ${fmt.format(endDate!)}',
                  style: TextStyle(fontSize: 12, color: color,
                      fontWeight: FontWeight.w600)),
          ]),
          if (endDate != null) ...[
            const SizedBox(height: 2),
            Text(
                isOverdue
                    ? 'Overdue by ${now.difference(endDate!).inDays} day(s)'
                    : daysLeft == 0 ? 'Due today!'
                    : 'Deadline in $daysLeft day(s)',
                style: TextStyle(fontSize: 11, color: color)),
          ],
        ])),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Team member picker — matches TField style exactly
// ─────────────────────────────────────────────────────────────────────
class _TeamMemberPicker extends StatefulWidget {
  final List<UserEntity> users;
  final List<String> selectedUids;
  final void Function(String uid) onToggle;
  const _TeamMemberPicker({required this.users, required this.selectedUids,
    required this.onToggle});
  @override State<_TeamMemberPicker> createState() => _TeamMemberPickerState();
}

class _TeamMemberPickerState extends State<_TeamMemberPicker> {
  final _searchCtrl = TextEditingController();
  bool  _open  = false;
  String _query = '';

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Color _roleColor(UserEntity u) {
    if (u.isAdmin)   return AppTheme.red;
    if (u.isManager) return AppTheme.orange;
    return AppTheme.blue;
  }
  String _roleLabel(UserEntity u) {
    if (u.isAdmin)   return 'Admin';
    if (u.isManager) return 'Manager';
    return 'User';
  }

  @override
  Widget build(BuildContext context) {
    final selectedUsers = widget.users
        .where((u) => widget.selectedUids.contains(u.uid)).toList();
    final unselected = widget.users
        .where((u) => !widget.selectedUids.contains(u.uid) &&
        (_query.isEmpty ||
            u.displayName.toLowerCase().contains(_query) ||
            u.department.toLowerCase().contains(_query)))
        .toList();

    return TapRegion(
      onTapOutside: (_) => setState(() => _open = false),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Label (matches TField exactly) ────────────────
        RichText(text: const TextSpan(
          text: 'TEAM MEMBERS',
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700,
              color: AppTheme.textMuted, letterSpacing: 0.7,
              fontFamily: 'DMSans'),
        )),
        const SizedBox(height: 6),

        // ── Search input (matches TField border/fill style) ─
        TextFormField(
          controller: _searchCtrl,
          onTap: () => setState(() => _open = true),
          onChanged: (v) => setState(() {
            _query = v.toLowerCase();
            _open = true;
          }),
          style: const TextStyle(fontSize: 13.5, color: AppTheme.textColor),
          decoration: InputDecoration(
            hintText: widget.users.isEmpty
                ? 'No team members in the system'
                : 'Search by name or department...',
            hintStyle: const TextStyle(color: AppTheme.textDim, fontSize: 13),
            prefixIcon: const Icon(Icons.search_rounded, size: 17, color: AppTheme.textDim),
            suffixIcon: _query.isNotEmpty
                ? GestureDetector(
                onTap: () { _searchCtrl.clear(); setState(() => _query = ''); },
                child: const Icon(Icons.close_rounded, size: 16, color: AppTheme.textDim))
                : null,
            filled: true,
            fillColor: AppTheme.cardAlt,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.borderLight)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.borderLight)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.accent, width: 1.5)),
          ),
        ),

        // ── Dropdown list (only when focused or query typed) ─
        if (_open)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.accent.withOpacity(0.4)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12),
                    blurRadius: 12, offset: const Offset(0, 4))]),
            child: unselected.isEmpty
                ? Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 15, color: AppTheme.textDim),
                  const SizedBox(width: 8),
                  Text(_query.isNotEmpty
                      ? 'No members match "$_query"'
                      : widget.users.isEmpty
                      ? 'No team members in the system yet'
                      : 'All members already selected',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textDim)),
                ]))
                : ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: unselected.length,
                separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppTheme.border),
                itemBuilder: (_, i) {
                  final u = unselected[i];
                  final rc = _roleColor(u);
                  return InkWell(
                    onTap: () {
                      widget.onToggle(u.uid);
                      _searchCtrl.clear();
                      setState(() {
                        _query = '';
                        _open = true;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 9),
                      child: Row(children: [
                        // Avatar
                        Container(width: 30, height: 30,
                            decoration: BoxDecoration(
                                color: rc.withOpacity(0.13),
                                shape: BoxShape.circle),
                            child: Center(child: Text(
                                u.displayName.isNotEmpty
                                    ? u.displayName[0].toUpperCase() : '?',
                                style: TextStyle(fontSize: 12,
                                    fontWeight: FontWeight.w700, color: rc)))),
                        const SizedBox(width: 10),
                        // Name + dept
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(u.displayName, style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600,
                                color: AppTheme.textColor)),
                            Text(u.department.isNotEmpty
                                ? u.department : u.email,
                                style: const TextStyle(fontSize: 11,
                                    color: AppTheme.textMuted),
                                overflow: TextOverflow.ellipsis),
                          ],
                        )),
                        // Role pill
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                                color: rc.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: rc.withOpacity(0.25))),
                            child: Text(_roleLabel(u), style: TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w700,
                                color: rc))),
                      ]),
                    ),
                  );
                }),
          ),

        // ── Selected chips ──────────────────────────────────
        if (selectedUsers.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6,
              children: selectedUsers.map((u) {
                final rc = _roleColor(u);
                return Container(
                  padding: const EdgeInsets.fromLTRB(8, 4, 6, 4),
                  decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.accent.withOpacity(0.35))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 18, height: 18,
                        decoration: BoxDecoration(
                            color: rc.withOpacity(0.15), shape: BoxShape.circle),
                        child: Center(child: Text(
                            u.displayName[0].toUpperCase(),
                            style: TextStyle(fontSize: 9,
                                fontWeight: FontWeight.w800, color: rc)))),
                    const SizedBox(width: 6),
                    Text(u.displayName, style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w600,
                        color: AppTheme.accent)),
                    const SizedBox(width: 5),
                    GestureDetector(
                        onTap: () => widget.onToggle(u.uid),
                        child: const Icon(Icons.close_rounded,
                            size: 13, color: AppTheme.accent)),
                  ]),
                );
              }).toList()),
        ] else ...[
          const SizedBox(height: 6),
          const Text('No members assigned yet',
              style: TextStyle(fontSize: 11.5, color: AppTheme.textDim)),
        ],
      ]),
    );
  }
}