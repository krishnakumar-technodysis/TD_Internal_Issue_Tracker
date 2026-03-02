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
import '../widgets/app_button.dart';
import '../widgets/form_widgets.dart';

class CreateIssueScreen extends StatefulWidget {
  final IssueEntity? existing;
  const CreateIssueScreen({super.key, this.existing});

  @override
  State<CreateIssueScreen> createState() => _CreateIssueScreenState();
}

class _CreateIssueScreenState extends State<CreateIssueScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _processCtrl  = TextEditingController();
  final _assignCtrl   = TextEditingController();
  final _summaryCtrl  = TextEditingController();
  final _actionCtrl   = TextEditingController();

  String    _customer   = AppConstants.customers.first;
  String    _tech       = AppConstants.technologies.first;
  String    _priority   = 'Medium';
  String    _status     = 'New';
  String    _rootCause  = 'Unknown';
  DateTime? _startDate;
  DateTime? _closingDate;

  bool get isEdit => widget.existing != null;

  // ── breakpoints ──────────────────────────────────────
  static const double _kTwoCol  = 900;  // form + sidebar side-by-side
  static const double _kCompact = 600;  // collapse internal field rows

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final e = widget.existing!;
      _processCtrl.text = e.processName;
      _assignCtrl.text  = e.assignedTo;
      _summaryCtrl.text = e.issueSummary;
      _actionCtrl.text  = e.actionTaken;
      _customer   = e.customer;
      _tech       = e.technology;
      _priority   = e.priority;
      _status     = e.status;
      _rootCause  = e.rootCauseCategory;
      _startDate  = e.startDate;
      _closingDate = e.closingDate;
    }
  }

  @override
  void dispose() {
    _processCtrl.dispose();
    _assignCtrl.dispose();
    _summaryCtrl.dispose();
    _actionCtrl.dispose();
    super.dispose();
  }

  // ── submit ────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      // Scroll to first error
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please fix the errors before submitting'),
        backgroundColor: AppTheme.orange,
      ));
      return;
    }
    final authVm  = context.read<AuthViewModel>();
    final issueVm = context.read<IssueViewModel>();
    final user    = authVm.currentUser!;

    final data = {
      'customer':          _customer,
      'processName':       _processCtrl.text.trim(),
      'technology':        _tech,
      'priority':          _priority,
      'assignedTo':        _assignCtrl.text.trim(),
      'status':            _status,
      'issueSummary':      _summaryCtrl.text.trim(),
      'rootCauseCategory': _rootCause,
      'startDate':         _startDate,
      'closingDate':       _closingDate,
      'actionTaken':       _actionCtrl.text.trim(),
    };

    final ok = isEdit
        ? await issueVm.updateIssue(
        existing: widget.existing!, data: data, by: user)
        : await issueVm.createIssue(data: data, by: user);

    if (ok && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppTheme.card,
        content: Row(children: [
          const Icon(Icons.check_circle_outline,
              color: AppTheme.green, size: 16),
          const SizedBox(width: 8),
          Text(
              isEdit ? 'Issue updated' : 'Issue created',
              style: const TextStyle(color: AppTheme.textColor)),
        ]),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: AppTheme.border)),
      ));
    }
  }

  // ── delete confirmation ───────────────────────────────
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
            style: TextStyle(
                color: AppTheme.textColor, fontWeight: FontWeight.w700)),
        content: Text(
            'Delete ${widget.existing!.issueId}? This action cannot be undone.',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.red,
                  foregroundColor: Colors.white),
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

  // ══════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final vm      = context.watch<IssueViewModel>();
    final authVm  = context.watch<AuthViewModel>();
    final loading = vm.state == IssueViewState.loading;
    final isAdmin = authVm.isAdmin;
    final userName = authVm.currentUser?.displayName ?? '';

    return AppShell(
      activePage: isEdit ? SidebarPage.issues : SidebarPage.create,
      child: LayoutBuilder(builder: (context, constraints) {
        final width    = constraints.maxWidth;
        final isTwoCol = width >= _kTwoCol;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: width < 480 ? 16 : 28,
            vertical:   24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Page header ──────────────────────────
                _PageHeader(
                  isEdit:   isEdit,
                  issueId:  widget.existing?.issueId,
                  summary:  widget.existing?.issueSummary,
                  onBack:   () => Navigator.pop(context),
                ),
                const SizedBox(height: 24),

                // ── Two-column or stacked ─────────────────
                if (isTwoCol)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildForm(
                          loading: loading,
                          isAdmin: isAdmin,
                          compact: false)),
                      const SizedBox(width: 20),
                      SizedBox(width: 264,
                          child: _buildSidebar(userName)),
                    ],
                  )
                else
                  Column(children: [
                    _buildForm(
                        loading: loading,
                        isAdmin: isAdmin,
                        compact: width < _kCompact),
                    const SizedBox(height: 16),
                    _buildSidebar(userName),
                  ]),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ══════════════════════════════════════════════════════
  // FORM COLUMN
  // ══════════════════════════════════════════════════════
  Widget _buildForm({
    required bool loading,
    required bool isAdmin,
    required bool compact,
  }) {
    return Column(children: [

      // ── Section 1 — Issue Information ────────────────
      FormSection(
        title: 'Issue Information', emoji: '📋',
        child: Column(children: [

          // Issue ID (read-only)
          TField(
            label: 'Issue ID',
            controller: TextEditingController(
                text: isEdit
                    ? widget.existing!.issueId
                    : 'Auto-generated on save'),
            readOnly: true,
          ),
          const SizedBox(height: 14),

          // Client + Technology
          FormRow(
            breakpoint: compact ? 9999 : 440,
            children: [
              TDropdown(
                label: 'Client',
                value: _customer,
                items: AppConstants.customers,
                isRequired: true,
                onChanged: (v) => setState(() => _customer = v!),
                validator: (v) =>
                v == null || v.isEmpty ? 'Client is required' : null,
              ),
              TDropdown(
                label: 'Technology',
                value: _tech,
                items: AppConstants.technologies,
                isRequired: true,
                onChanged: (v) => setState(() => _tech = v!),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Process Name — 80 chars
          TField(
            label: 'Process Name',
            controller: _processCtrl,
            hint: 'e.g. Daily Payment Reconciliation Bot',
            isRequired: true,
            maxLength: FieldLimits.processName,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Process name is required';
              if (v.trim().length < 3) return 'Too short — at least 3 characters';
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Summary — 300 chars, 3 lines
          TField(
            label: 'Issue Summary',
            controller: _summaryCtrl,
            hint: 'What is happening? When did it start? What is the impact?',
            isRequired: true,
            maxLines: 4,
            maxLength: FieldLimits.summary,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Summary is required';
              if (v.trim().length < 10)
                return 'Please be more descriptive — at least 10 characters';
              return null;
            },
          ),
        ]),
      ),
      const SizedBox(height: 16),

      // ── Section 2 — Classification ───────────────────
      FormSection(
        title: 'Classification & Assignment', emoji: '⚙️',
        child: Column(children: [

          // Priority + Status (admin) or Priority + RootCause (user)
          FormRow(
            breakpoint: compact ? 9999 : 440,
            children: [
              TDropdown(
                label: 'Priority',
                value: _priority,
                items: AppConstants.priorities,
                isRequired: true,
                onChanged: (v) => setState(() => _priority = v!),
              ),
              if (isEdit || isAdmin)
                TDropdown(
                  label: 'Status',
                  value: _status,
                  items: AppConstants.statuses,
                  isRequired: true,
                  onChanged: (v) => setState(() => _status = v!),
                )
              else
                TDropdown(
                  label: 'Root Cause',
                  value: _rootCause,
                  items: AppConstants.rootCauses,
                  onChanged: (v) => setState(() => _rootCause = v!),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Root Cause — only shown for admin separately when status also shown
          if (isEdit || isAdmin) ...[
            TDropdown(
              label: 'Root Cause',
              value: _rootCause,
              items: AppConstants.rootCauses,
              onChanged: (v) => setState(() => _rootCause = v!),
            ),
            const SizedBox(height: 14),
          ],

          // Assigned To — 60 chars
          TField(
            label: 'Assigned To',
            controller: _assignCtrl,
            hint: 'Engineer name or team',
            isRequired: true,
            maxLength: FieldLimits.assignedTo,
            validator: (v) =>
            v == null || v.trim().isEmpty ? 'Assignee is required' : null,
          ),
          const SizedBox(height: 14),

          // Start + Closing Dates
          FormRow(
            breakpoint: compact ? 9999 : 440,
            children: [
              TDatePicker(
                label: 'Start Date',
                value: _startDate,
                onChanged: (d) => setState(() => _startDate = d),
              ),
              TDatePicker(
                label: 'Target Closing Date',
                value: _closingDate,
                onChanged: (d) => setState(() {
                  _closingDate = d;
                }),
              ),
            ],
          ),

          // Closing date warning
          if (_startDate != null &&
              _closingDate != null &&
              _closingDate!.isBefore(_startDate!)) ...[
            const SizedBox(height: 8),
            _WarningBanner('Closing date is before start date'),
          ],
        ]),
      ),
      const SizedBox(height: 16),

      // ── Section 3 — Action Taken ─────────────────────
      FormSection(
        title: 'Action Taken', emoji: '🔧',
        footer: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: _FormActions(
            isEdit:  isEdit,
            loading: loading,
            onDiscard:  () => Navigator.pop(context),
            onDelete:   isEdit ? () => _confirmDelete(context) : null,
            onSubmit:   _submit,
          ),
        ),
        child: TField(
          label: 'Notes & Actions',
          controller: _actionCtrl,
          hint:
          'What steps have been taken? Is there a workaround? Any client communication?',
          maxLines: 5,
          maxLength: FieldLimits.actionTaken,
        ),
      ),
    ]);
  }

  // ══════════════════════════════════════════════════════
  // SIDEBAR
  // ══════════════════════════════════════════════════════
  Widget _buildSidebar(String userName) {
    return Column(children: [

      // Status card
      _SideCard(
        title: 'Issue Status',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
              isEdit ? 'Current status:' : 'New issues start as:',
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.blueBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.blue.withOpacity(0.25)),
            ),
            child: Text(
                isEdit ? _status : 'New',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: AppTheme.blue)),
          ),
        ]),
      ),
      const SizedBox(height: 12),

      // Flow card
      _SideCard(
        title: 'Status Flow',
        child: Column(children: [
          for (final entry in const [
            ['New',                AppTheme.blue],
            ['In Progress',        AppTheme.purple],
            ['Waiting for Client', AppTheme.orange],
            ['Resolved',           AppTheme.green],
            ['Closed',             AppTheme.textDim],
          ].asMap().entries) ...[
            _FlowStep(
              label: entry.value[0] as String,
              color: entry.value[1] as Color,
              isActive: isEdit && _status == entry.value[0],
            ),
            if (entry.key < 4)
              Container(
                  margin: const EdgeInsets.only(left: 6),
                  height: 10, width: 1,
                  color: AppTheme.border),
          ],
        ]),
      ),
      const SizedBox(height: 12),

      // Field limits reference card
      _SideCard(
        title: 'Field Limits',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _LimitRow('Process Name',  '${FieldLimits.processName} chars'),
            SizedBox(height: 7),
            _LimitRow('Issue Summary', '${FieldLimits.summary} chars'),
            SizedBox(height: 7),
            _LimitRow('Assigned To',   '${FieldLimits.assignedTo} chars'),
            SizedBox(height: 7),
            _LimitRow('Notes',         '${FieldLimits.actionTaken} chars'),
          ],
        ),
      ),
      const SizedBox(height: 12),

      // Opened by
      _SideCard(
        title: 'Opened By',
        child: Row(children: [
          Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppTheme.accentBg,
                border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
              ),
              child: Center(child: Text(
                  userName.isNotEmpty
                      ? userName.substring(0, 1).toUpperCase()
                      : 'U',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: AppTheme.accent)))),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(userName,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: AppTheme.textColor)),
              Text(isEdit ? 'Editing now' : 'Creating now',
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textDim)),
            ],
          )),
        ]),
      ),
    ]);
  }
}

// ══════════════════════════════════════════════════════════
// SUB-WIDGETS
// ══════════════════════════════════════════════════════════

class _PageHeader extends StatelessWidget {
  final bool isEdit;
  final String? issueId, summary;
  final VoidCallback onBack;

  const _PageHeader({
    required this.isEdit, this.issueId, this.summary,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb
          if (isEdit) Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              GestureDetector(
                  onTap: onBack,
                  child: const Text('All Issues',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted))),
              const Text(' › ',
                  style: TextStyle(fontSize: 12, color: AppTheme.textDim)),
              Text(issueId ?? '',
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 12, color: AppTheme.accent)),
              const Text(' › Edit',
                  style: TextStyle(fontSize: 12, color: AppTheme.accent)),
            ],
          ),
          if (isEdit) const SizedBox(height: 6),

          // Title
          Text(
              isEdit ? 'Edit Issue' : 'Create New Issue',
              style: GoogleFonts.dmSans(
                  fontSize: 22, fontWeight: FontWeight.w700,
                  color: AppTheme.textColor, letterSpacing: -0.4)),
          const SizedBox(height: 3),
          Text(
            isEdit
                ? 'Editing: ${summary ?? ''}'
                : 'Document a new technical issue for tracking and resolution',
            style: const TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      )),
      if (isEdit) ...[
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded, size: 14),
          label: const Text('Back'),
          style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
        ),
      ],
    ]);
  }
}

// ── Form action buttons row ───────────────────────────────
class _FormActions extends StatelessWidget {
  final bool isEdit, loading;
  final VoidCallback onDiscard, onSubmit;
  final VoidCallback? onDelete;

  const _FormActions({
    required this.isEdit, required this.loading,
    required this.onDiscard, required this.onSubmit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, box) {
      final narrow = box.maxWidth < 400;
      final buttons = [
        OutlinedButton(
          onPressed: onDiscard,
          child: const Text('Discard'),
        ),
        if (onDelete != null) OutlinedButton(
          style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.red,
              side: const BorderSide(color: AppTheme.border)),
          onPressed: onDelete,
          child: const Text('Delete'),
        ),
        AppButton(
          label:   isEdit ? 'Save Changes' : 'Create Issue',
          loading: loading,
          onPressed: onSubmit,
          width: 140,
          height: 38,
        ),
      ];

      return narrow
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: buttons.map((b) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: b,
        )).toList(),
      )
          : Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: buttons.expand((b) sync* {
          if (b != buttons.first) yield const SizedBox(width: 8);
          yield b;
        }).toList(),
      );
    });
  }
}

// ── Side card wrapper ─────────────────────────────────────
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
                fontSize: 10, fontWeight: FontWeight.w700,
                color: AppTheme.textDim, letterSpacing: 1.2)),
      ),
      const Divider(height: 1, color: AppTheme.border),
      Padding(padding: const EdgeInsets.all(16), child: child),
    ]),
  );
}

// ── Status flow step ──────────────────────────────────────
class _FlowStep extends StatelessWidget {
  final String label;
  final Color color;
  final bool isActive;

  const _FlowStep({
    required this.label, required this.color, this.isActive = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: isActive
        ? BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withOpacity(0.25)),
    )
        : null,
    child: Row(children: [
      Container(width: 7, height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Text(label, style: TextStyle(
          fontSize: 12,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          color: isActive ? color : AppTheme.textMuted)),
      if (isActive) ...[
        const Spacer(),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4)),
            child: Text('Current',
                style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w700, color: color,
                    letterSpacing: 0.3))),
      ],
    ]),
  );
}

// ── Field limit row (sidebar reference) ───────────────────
class _LimitRow extends StatelessWidget {
  final String field, limit;
  const _LimitRow(this.field, this.limit);

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Text(field,
        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted))),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
          color: AppTheme.cardAlt,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppTheme.border)),
      child: Text(limit,
          style: GoogleFonts.jetBrainsMono(
              fontSize: 10.5, color: AppTheme.textDim,
              fontWeight: FontWeight.w500)),
    ),
  ]);
}

// ── Warning banner ────────────────────────────────────────
class _WarningBanner extends StatelessWidget {
  final String message;
  const _WarningBanner(this.message);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: AppTheme.orangeBg,
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: AppTheme.orange.withOpacity(0.3)),
    ),
    child: Row(children: [
      const Icon(Icons.warning_amber_rounded,
          size: 15, color: AppTheme.orange),
      const SizedBox(width: 8),
      Expanded(child: Text(message,
          style: const TextStyle(
              fontSize: 12.5, color: AppTheme.orange,
              fontWeight: FontWeight.w500))),
    ]),
  );
}