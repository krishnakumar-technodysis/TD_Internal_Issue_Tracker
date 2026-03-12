// lib/presentation/projects/create_task_screen.dart
import 'package:flutter/material.dart';
import 'package:issue_tracker/presentation/projects/project_view_model.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../auth/auth_viewmodel.dart';
import '../widgets/form_widgets.dart';

class CreateTaskScreen extends StatefulWidget {
  final String projectId;
  final String projectName;
  final TaskEntity? existing;
  const CreateTaskScreen({
    super.key,
    required this.projectId,
    required this.projectName,
    this.existing,
  });

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  final _notesCtrl = TextEditingController();

  String    _priority       = 'Medium';
  String    _status         = 'todo';
  String    _assignedToUid  = '';
  String    _assignedToName = '';
  DateTime? _startDate;
  DateTime? _dueDate;
  String?   _submitError;
  bool      _loading = false;

  bool get isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final t = widget.existing!;
      _titleCtrl.text = t.title;
      _descCtrl.text  = t.description;
      _notesCtrl.text = t.notes ?? '';
      _priority       = t.priority;
      _status         = t.status;
      _assignedToUid  = t.assignedToUid;
      _assignedToName = t.assignedToName;
      _startDate      = t.startDate;
      _dueDate        = t.dueDate;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _descCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final authVm = context.read<AuthViewModel>();
    final vm     = context.read<ProjectViewModel>();
    final user   = authVm.currentUser;
    if (user == null) return;

    setState(() { _loading = true; _submitError = null; });

    final data = {
      'projectId':      widget.projectId,
      'projectName':    widget.projectName,
      'title':          _titleCtrl.text.trim(),
      'description':    _descCtrl.text.trim(),
      'priority':       _priority,
      'status':         _status,
      'assignedToUid':  _assignedToUid,
      'assignedToName': _assignedToName,
      'startDate':      _startDate,
      'dueDate':        _dueDate,
      'notes':          _notesCtrl.text.trim().isEmpty
          ? null : _notesCtrl.text.trim(),
    };

    try {
      bool ok;
      if (isEdit) {
        ok = await vm.updateTask(id: widget.existing!.id, data: data, by: user);
      } else {
        ok = await vm.createTask(data: data, by: user);
      }
      if (!mounted) return;
      if (ok) {
        Navigator.pop(context);
      } else {
        setState(() => _submitError = 'Failed to save task. Please try again.');
      }
    } catch (e) {
      if (mounted) setState(() => _submitError = 'An error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: AppTheme.ink,
      body: SafeArea(
        child: StreamBuilder<List<UserEntity>>(
          stream: authVm.allUsersStream,
          initialData: authVm.allUsers,
          builder: (context, userSnap) {
            final users = (userSnap.data ?? authVm.allUsers)
                .where((u) => u.status == 'approved' || u.isAdmin)
                .toList()
              ..sort((a, b) => a.displayName.compareTo(b.displayName));

            final isLoadingUsers =
                userSnap.connectionState == ConnectionState.waiting &&
                    users.isEmpty;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                  Row(children: [
                    IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: AppTheme.textMuted)),
                    Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(isEdit ? 'Edit Task' : 'Add Task',
                          style: const TextStyle(fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textColor)),
                      Text(widget.projectName,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.accent),
                          overflow: TextOverflow.ellipsis),
                    ])),
                  ]),
                  const SizedBox(height: 20),

                  if (_submitError != null) ...[
                    _ErrorBanner(message: _submitError!),
                    const SizedBox(height: 16),
                  ],

                  TField(
                    label: 'Task Title', controller: _titleCtrl,
                    isRequired: true, hint: 'What needs to be done?',
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 14),

                  TField(
                    label: 'Description', controller: _descCtrl,
                    hint: 'More detail about this task', maxLines: 3,
                  ),
                  const SizedBox(height: 14),

                  FormRow(breakpoint: 500, children: [
                    TDropdown(
                      label: 'Priority', value: _priority,
                      items: AppConstants.priorities,
                      onChanged: (v) => setState(() => _priority = v!),
                    ),
                    TDropdown(
                      label: 'Status', value: _status,
                      items: AppConstants.taskStatuses,
                      displayItems: AppConstants.taskStatuses
                          .map(AppConstants.taskStatusLabel).toList(),
                      onChanged: (v) => setState(() => _status = v!),
                    ),
                  ]),
                  const SizedBox(height: 14),

                  if (isLoadingUsers)
                    const _UsersLoadingField()
                  else if (users.isEmpty)
                    const _NoUsersField()
                  else
                    _UserDropdown(
                      users: users,
                      selectedUid: _assignedToUid,
                      onChanged: (uid, name) => setState(() {
                        _assignedToUid  = uid;
                        _assignedToName = name;
                      }),
                    ),
                  const SizedBox(height: 14),

                  FormRow(breakpoint: 500, children: [
                    TDatePicker(
                      label: 'Start Date',
                      value: _startDate,
                      onChanged: (d) => setState(() {
                        _startDate = d;
                        if (_dueDate != null && d != null &&
                            _dueDate!.isBefore(d)) {
                          _dueDate = null;
                        }
                      }),
                    ),
                    TDatePicker(
                      label: 'Due Date',
                      value: _dueDate,
                      firstDate: _startDate,
                      onChanged: (d) => setState(() => _dueDate = d),
                    ),
                  ]),
                  const SizedBox(height: 14),

                  if (_dueDate != null) _DueDateBanner(dueDate: _dueDate!),
                  if (_dueDate != null) const SizedBox(height: 14),

                  TField(
                    label: 'Notes', controller: _notesCtrl,
                    hint: 'Any additional notes or context', maxLines: 3,
                  ),
                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppTheme.accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10))),
                      child: _loading
                          ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                          : Text(isEdit ? 'Save Changes' : 'Create Task',
                          style: const TextStyle(fontSize: 15,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ]),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DueDateBanner extends StatelessWidget {
  final DateTime dueDate;
  const _DueDateBanner({required this.dueDate});

  @override
  Widget build(BuildContext context) {
    final now       = DateTime.now();
    final isOverdue = dueDate.isBefore(now);
    final days      = dueDate.difference(now).inDays;
    final color     = isOverdue ? AppTheme.red
        : days <= 2  ? AppTheme.orange
        : AppTheme.green;
    final icon      = isOverdue ? Icons.warning_rounded
        : days <= 2  ? Icons.schedule_rounded
        : Icons.check_circle_outline_rounded;
    final msg       = isOverdue
        ? '⚠️ Overdue by ${now.difference(dueDate).inDays} day(s)'
        : days == 0 ? '⏰ Due today!'
        : '✅ Due in $days day(s)';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Row(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(msg, style: TextStyle(fontSize: 12.5, color: color,
            fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

class _UserDropdown extends StatelessWidget {
  final List<UserEntity> users;
  final String selectedUid;
  final void Function(String uid, String name) onChanged;

  const _UserDropdown({
    required this.users,
    required this.selectedUid,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final validUid = users.any((u) => u.uid == selectedUid) ? selectedUid : '';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('ASSIGN TO *',
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700,
              color: AppTheme.textMuted, letterSpacing: 0.7)),
      const SizedBox(height: 6),
      DropdownButtonFormField<String>(
        value: validUid.isEmpty ? null : validUid,
        isExpanded: true,
        hint: const Text('Select team member',
            style: TextStyle(color: AppTheme.textDim, fontSize: 13)),
        decoration: InputDecoration(
            filled: true, fillColor: AppTheme.cardAlt,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.borderLight)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.borderLight)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                    color: AppTheme.accent, width: 1.5))),
        dropdownColor: AppTheme.card,
        // Compact single-line display in the closed field (avoids overflow)
        selectedItemBuilder: (context) => users.map((u) => Align(
          alignment: Alignment.centerLeft,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                    color: AppTheme.accentBg,
                    borderRadius: BorderRadius.circular(5)),
                child: Center(child: Text(
                    u.displayName.isNotEmpty
                        ? u.displayName[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accent)))),
            const SizedBox(width: 8),
            Flexible(child: Text(u.displayName,
                style: const TextStyle(fontSize: 13,
                    color: AppTheme.textColor, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis)),
          ]),
        )).toList(),
        // Rich 2-line display inside the open dropdown list
        items: users.map((u) => DropdownMenuItem(
          value: u.uid,
          child: Row(children: [
            Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                    color: AppTheme.accentBg,
                    borderRadius: BorderRadius.circular(6)),
                child: Center(child: Text(
                    u.displayName.isNotEmpty
                        ? u.displayName[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accent)))),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(u.displayName,
                    style: const TextStyle(fontSize: 13,
                        color: AppTheme.textColor,
                        fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
                if (u.department.isNotEmpty)
                  Text(u.department,
                      style: const TextStyle(
                          fontSize: 10.5, color: AppTheme.textDim)),
              ],
            )),
          ]),
        )).toList(),
        onChanged: (uid) {
          if (uid == null) return;
          final match = users.where((u) => u.uid == uid).toList();
          if (match.isNotEmpty) onChanged(uid, match.first.displayName);
        },
        validator: (v) => v == null || v.isEmpty
            ? 'Please assign this task to a team member' : null,
      ),
    ]);
  }
}

class _UsersLoadingField extends StatelessWidget {
  const _UsersLoadingField();
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('ASSIGN TO *',
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700,
              color: AppTheme.textMuted, letterSpacing: 0.7)),
      const SizedBox(height: 6),
      Container(
        height: 48,
        decoration: BoxDecoration(
            color: AppTheme.cardAlt,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.borderLight)),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 1.5, color: AppTheme.accent)),
            SizedBox(width: 10),
            Text('Loading team members…',
                style: TextStyle(fontSize: 13, color: AppTheme.textDim)),
          ],
        ),
      ),
    ],
  );
}

class _NoUsersField extends StatelessWidget {
  const _NoUsersField();
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('ASSIGN TO',
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700,
              color: AppTheme.textMuted, letterSpacing: 0.7)),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: AppTheme.cardAlt,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.borderLight)),
        child: const Row(children: [
          Icon(Icons.info_outline_rounded, size: 15, color: AppTheme.textDim),
          SizedBox(width: 8),
          Expanded(child: Text(
              'No approved users found. Create users via Admin Panel first.',
              style: TextStyle(fontSize: 12.5, color: AppTheme.textDim))),
        ]),
      ),
    ],
  );
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
        color: AppTheme.redBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.red.withOpacity(0.25))),
    child: Row(children: [
      const Icon(Icons.error_outline_rounded, size: 16, color: AppTheme.red),
      const SizedBox(width: 8),
      Expanded(child: Text(message,
          style: const TextStyle(fontSize: 13, color: AppTheme.red))),
    ]),
  );
}
