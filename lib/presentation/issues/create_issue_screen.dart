// lib/presentation/issues/create_issue_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/issue_entity.dart';
import '../auth/auth_viewmodel.dart';
import '../issues/issue_viewmodel.dart';
import '../widgets/app_shell.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/form_widgets.dart';

class CreateIssueScreen extends StatefulWidget {
  final IssueEntity? existing;
  const CreateIssueScreen({super.key, this.existing});

  @override
  State<CreateIssueScreen> createState() => _CreateIssueScreenState();
}

class _CreateIssueScreenState extends State<CreateIssueScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _processCtrl = TextEditingController();
  final _assignCtrl  = TextEditingController();
  final _summaryCtrl = TextEditingController();
  final _actionCtrl  = TextEditingController();

  String _customer  = AppConstants.customers.first;
  String _tech      = AppConstants.technologies.first;
  String _priority  = 'Medium';
  String _status    = 'New';
  String _rootCause = 'Unknown';
  DateTime? _startDate, _closingDate;

  bool get isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final e = widget.existing!;
      _processCtrl.text = e.processName;
      _assignCtrl.text  = e.assignedTo;
      _summaryCtrl.text = e.issueSummary;
      _actionCtrl.text  = e.actionTaken;
      _customer  = e.customer;
      _tech      = e.technology;
      _priority  = e.priority;
      _status    = e.status;
      _rootCause = e.rootCauseCategory;
      _startDate    = e.startDate;
      _closingDate  = e.closingDate;
    }
  }

  @override
  void dispose() {
    _processCtrl.dispose(); _assignCtrl.dispose();
    _summaryCtrl.dispose(); _actionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final authVm  = context.read<AuthViewModel>();
    final issueVm = context.read<IssueViewModel>();
    final user    = authVm.currentUser!;
    final data = {
      'customer': _customer, 'processName': _processCtrl.text.trim(),
      'technology': _tech, 'priority': _priority,
      'assignedTo': _assignCtrl.text.trim(),
      'status': _status,
      'issueSummary': _summaryCtrl.text.trim(),
      'rootCauseCategory': _rootCause,
      'startDate': _startDate, 'closingDate': _closingDate,
      'actionTaken': _actionCtrl.text.trim(),
    };
    final ok = isEdit
        ? await issueVm.updateIssue(existing: widget.existing!, data: data, by: user)
        : await issueVm.createIssue(data: data, by: user);
    if (ok && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppTheme.card,
        content: Row(children: [
          const Icon(Icons.check_circle_outline, color: AppTheme.green, size: 16),
          const SizedBox(width: 8),
          Text(isEdit ? 'Issue updated successfully' : 'Issue created successfully',
            style: const TextStyle(color: AppTheme.textColor)),
        ]),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppTheme.border)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm      = context.watch<IssueViewModel>();
    final authVm  = context.watch<AuthViewModel>();
    final user    = authVm.currentUser;
    final loading = vm.state == IssueViewState.loading;

    return AppShell(
      activePage: isEdit ? SidebarPage.issues : SidebarPage.create,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header
            Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (isEdit) ...[
                  Row(children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text('Issues',
                        style: TextStyle(
                          fontSize: 12, color: AppTheme.textMuted))),
                    const Text(' › ',
                      style: TextStyle(
                        fontSize: 12, color: AppTheme.textDim)),
                    Text(widget.existing!.issueId,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12, color: AppTheme.accent)),
                    const Text(' › ',
                      style: TextStyle(
                        fontSize: 12, color: AppTheme.textDim)),
                    const Text('Edit',
                      style: TextStyle(
                        fontSize: 12, color: AppTheme.accent)),
                  ]),
                  const SizedBox(height: 6),
                ],
                Text(isEdit ? 'Edit Issue' : 'Create New Issue',
                  style: GoogleFonts.syne(
                    fontSize: 22, fontWeight: FontWeight.w700,
                    color: AppTheme.textColor, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text(
                  isEdit
                    ? 'Updating: ${widget.existing!.issueSummary}'
                    : 'Document a new technical issue for tracking and resolution',
                  style: const TextStyle(
                    fontSize: 12.5, color: AppTheme.textMuted),
                  overflow: TextOverflow.ellipsis),
              ]),
              const Spacer(),
              if (isEdit) OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('← Back'),
              ),
            ]),
            const SizedBox(height: 24),

            // Two-column layout
            LayoutBuilder(builder: (ctx, box) {
              final wide = box.maxWidth > 800;
              final form = _buildForm(context, loading);
              final side = _buildSidebar(context, user?.displayName ?? '');
              return wide
                  ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(child: form),
                      const SizedBox(width: 20),
                      SizedBox(width: 280, child: side),
                    ])
                  : Column(children: [form, const SizedBox(height: 16), side]);
            }),
          ]),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, bool loading) {
    return Column(children: [
      // Section 1 – Basic Info
      FormSection(
        title: 'Issue Information', emoji: '📋',
        child: Column(children: [
          // Issue ID
          TField(
            label: 'Issue ID',
            controller: TextEditingController(
              text: isEdit ? widget.existing!.issueId : 'Auto-generated'),
            readOnly: true,
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: TDropdown(
              label: 'Client *', value: _customer,
              items: AppConstants.customers,
              onChanged: (v) => setState(() => _customer = v!),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            )),
            const SizedBox(width: 14),
            Expanded(child: TDropdown(
              label: 'Technology *', value: _tech,
              items: AppConstants.technologies,
              onChanged: (v) => setState(() => _tech = v!),
            )),
          ]),
          const SizedBox(height: 14),
          TField(
            label: 'Process Name *', controller: _processCtrl,
            hint: 'e.g. Daily Payment Reconciliation Bot',
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 14),
          TField(
            label: 'Issue Summary *', controller: _summaryCtrl,
            hint: 'Describe the issue clearly...',
            maxLines: 3,
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
        ]),
      ),
      const SizedBox(height: 16),

      // Section 2 – Classification
      FormSection(
        title: 'Classification & Assignment', emoji: '⚙️',
        child: Column(children: [
          Row(children: [
            Expanded(child: TDropdown(
              label: 'Priority *', value: _priority,
              items: AppConstants.priorities,
              onChanged: (v) => setState(() => _priority = v!),
            )),
            const SizedBox(width: 14),
            if (isEdit || context.read<AuthViewModel>().isAdmin)
              Expanded(child: TDropdown(
                label: 'Status *', value: _status,
                items: AppConstants.statuses,
                onChanged: (v) => setState(() => _status = v!),
              ))
            else
              Expanded(child: TDropdown(
                label: 'Root Cause *', value: _rootCause,
                items: AppConstants.rootCauses,
                onChanged: (v) => setState(() => _rootCause = v!),
              )),
          ]),
          const SizedBox(height: 14),
          if (isEdit || context.read<AuthViewModel>().isAdmin) ...[
            TDropdown(
              label: 'Root Cause *', value: _rootCause,
              items: AppConstants.rootCauses,
              onChanged: (v) => setState(() => _rootCause = v!),
            ),
            const SizedBox(height: 14),
          ],
          TField(
            label: 'Assigned To *', controller: _assignCtrl,
            hint: 'Assignee name or email',
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: TDatePicker(
              label: 'Start Date', value: _startDate,
              onChanged: (d) => setState(() => _startDate = d))),
            const SizedBox(width: 14),
            Expanded(child: TDatePicker(
              label: 'Target Closing Date', value: _closingDate,
              onChanged: (d) => setState(() => _closingDate = d))),
          ]),
        ]),
      ),
      const SizedBox(height: 16),

      // Section 3 – Action Taken
      FormSection(
        title: 'Action Taken', emoji: '🔧',
        child: TField(
          label: 'Action Taken',
          controller: _actionCtrl,
          hint: 'What steps have been taken so far...',
          maxLines: 4,
        ),
        footer: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Discard'),
            ),
            const SizedBox(width: 10),
            if (isEdit) ...[
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.red,
                  side: const BorderSide(color: AppTheme.border)),
                onPressed: () => _confirmDelete(context),
                child: const Text('Delete'),
              ),
              const SizedBox(width: 10),
            ],
            ElevatedButton(
              onPressed: loading ? null : _submit,
              child: loading
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.ink))
                  : Text(isEdit ? 'Save Changes  →' : 'Create Issue  →'),
            ),
          ]),
        ),
      ),
    ]);
  }

  Widget _buildSidebar(BuildContext context, String userName) {
    return Column(children: [
      // Status info
      _SideCard(title: 'Issue Status', child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEdit ? 'Current status:' : 'New issues start as:',
            style: const TextStyle(
              fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.blue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.blue.withOpacity(0.3)),
            ),
            child: Text(isEdit ? _status : 'New',
              style: const TextStyle(
                fontSize: 11.5, fontWeight: FontWeight.w600,
                color: AppTheme.blue))),
        ],
      )),
      const SizedBox(height: 14),

      // Status flow
      _SideCard(title: 'Status Flow', child: Column(
        children: [
          ['New', AppTheme.blue],
          ['In Progress', AppTheme.purple],
          ['Waiting for Client', AppTheme.yellow],
          ['Resolved', AppTheme.green],
          ['Closed', AppTheme.textDim],
        ].asMap().entries.map((e) => Column(children: [
          Row(children: [
            Container(width: 6, height: 6,
              decoration: BoxDecoration(
                color: e.value[1] as Color,
                shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(e.value[0] as String,
              style: const TextStyle(
                fontSize: 12, color: AppTheme.textMuted)),
          ]),
          if (e.key < 4) ...[
            const SizedBox(height: 4),
            Container(margin: const EdgeInsets.only(left: 3),
              height: 10, width: 1,
              color: AppTheme.border),
            const SizedBox(height: 4),
          ],
        ])).toList(),
      )),
      const SizedBox(height: 14),

      // Opened by
      _SideCard(title: 'Opened By', child: Row(children: [
        Container(width: 30, height: 30,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            gradient: const LinearGradient(
              colors: [AppTheme.accent, AppTheme.blue])),
          child: Center(child: Text(
            userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : 'U',
            style: GoogleFonts.syne(fontSize: 12,
              fontWeight: FontWeight.w700, color: AppTheme.ink)))),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(userName,
            style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500,
              color: AppTheme.textColor)),
          Text(isEdit ? 'Editing now' : 'Creating now',
            style: const TextStyle(
              fontSize: 11, color: AppTheme.textDim)),
        ]),
      ])),
    ]);
  }

  void _confirmDelete(BuildContext context) {
    final issueVm = context.read<IssueViewModel>();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppTheme.border)),
        title: const Text('Delete Issue',
          style: TextStyle(color: AppTheme.textColor)),
        content: Text(
          'Are you sure you want to delete ${widget.existing!.issueId}? This cannot be undone.',
          style: const TextStyle(color: AppTheme.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
              style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.red, foregroundColor: Colors.white),
            onPressed: () async {
              await issueVm.deleteIssue(widget.existing!.id);
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(
                  context, '/issues', (_) => false);
              }
            },
            child: const Text('Delete')),
        ],
      ),
    );
  }
}

class _SideCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SideCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppTheme.card,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppTheme.border),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
        child: Text(title.toUpperCase(),
          style: const TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600,
            color: AppTheme.textDim, letterSpacing: 1.2))),
      const Divider(height: 1),
      Padding(padding: const EdgeInsets.all(16), child: child),
    ]),
  );
}
