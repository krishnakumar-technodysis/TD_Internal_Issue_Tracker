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
    final user   = authVm.currentUser!;

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
      'notes':          _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    };

    bool ok;
    if (isEdit) {
      ok = await vm.updateTask(id: widget.existing!.id, data: data, by: user);
    } else {
      ok = await vm.createTask(data: data, by: user);
    }
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final vm     = context.watch<ProjectViewModel>();
    final users  = authVm.allUsers
        .where((u) => u.status == 'approved').toList();

    return Scaffold(
      backgroundColor: AppTheme.ink,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header
            Row(children: [
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textMuted)),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(isEdit ? 'Edit Task' : 'Add Task',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                        color: AppTheme.textColor)),
                Text(widget.projectName,
                    style: const TextStyle(fontSize: 12, color: AppTheme.accent)),
              ]),
            ]),
            const SizedBox(height: 24),

            // Title
            TField(
              label: 'Task Title', controller: _titleCtrl,
              isRequired: true, hint: 'What needs to be done?',
              validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 14),

            // Description
            TField(
              label: 'Description', controller: _descCtrl,
              hint: 'More detail about this task', maxLines: 3,
            ),
            const SizedBox(height: 14),

            // Priority + Status
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

            // Assign To
            _UserDropdown(
              users: users,
              selectedUid: _assignedToUid,
              onChanged: (uid, name) => setState(() {
                _assignedToUid  = uid;
                _assignedToName = name;
              }),
            ),
            const SizedBox(height: 14),

            // Start + Due Date
            FormRow(breakpoint: 500, children: [
              TDatePicker(
                label: 'Start Date',
                value: _startDate,
                onChanged: (d) => setState(() {
                  _startDate = d;
                  if (_dueDate != null && d != null && _dueDate!.isBefore(d)) {
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

            // Due date status banner
            if (_dueDate != null) _DueDateBanner(dueDate: _dueDate!),
            if (_dueDate != null) const SizedBox(height: 14),

            // Notes
            TField(
              label: 'Notes', controller: _notesCtrl,
              hint: 'Any additional notes or context', maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Submit
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
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(isEdit ? 'Save Changes' : 'Create Task',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Due date banner ───────────────────────────────────────
class _DueDateBanner extends StatelessWidget {
  final DateTime dueDate;
  const _DueDateBanner({required this.dueDate});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isOverdue = dueDate.isBefore(now);
    final days = dueDate.difference(now).inDays;
    final color = isOverdue ? AppTheme.red
        : days <= 2 ? AppTheme.orange
        : AppTheme.green;
    final icon = isOverdue ? Icons.warning_rounded
        : days <= 2 ? Icons.schedule_rounded
        : Icons.check_circle_outline_rounded;
    final msg = isOverdue
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

// ── User dropdown ─────────────────────────────────────────
class _UserDropdown extends StatelessWidget {
  final List<UserEntity> users;
  final String selectedUid;
  final void Function(String uid, String name) onChanged;

  const _UserDropdown({
    required this.users, required this.selectedUid, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('ASSIGN TO *',
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700,
              color: AppTheme.textMuted, letterSpacing: 0.7)),
      const SizedBox(height: 6),
      DropdownButtonFormField<String>(
        value: selectedUid.isEmpty ? null : selectedUid,
        hint: const Text('Select team member',
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
        items: users.map((u) => DropdownMenuItem(
          value: u.uid,
          child: Row(children: [
            Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                    color: AppTheme.accentBg,
                    borderRadius: BorderRadius.circular(6)),
                child: Center(child: Text(u.displayName[0].toUpperCase(),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: AppTheme.accent)))),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(u.displayName,
                    style: const TextStyle(fontSize: 13, color: AppTheme.textColor,
                        fontWeight: FontWeight.w500)),
                if (u.department.isNotEmpty)
                  Text(u.department,
                      style: const TextStyle(fontSize: 10.5, color: AppTheme.textDim)),
              ],
            )),
          ]),
        )).toList(),
        onChanged: (uid) {
          if (uid == null) return;
          final u = users.firstWhere((u) => u.uid == uid);
          onChanged(uid, u.displayName);
        },
        validator: (v) => v == null || v.isEmpty ? 'Assignee is required' : null,
      ),
    ]);
  }
}