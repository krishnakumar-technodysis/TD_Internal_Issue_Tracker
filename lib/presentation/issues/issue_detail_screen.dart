// lib/presentation/issues/issue_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/issue_entity.dart';
import '../auth/auth_viewmodel.dart';
import '../issues/issue_viewmodel.dart';
import '../issues/create_issue_screen.dart';
import '../widgets/badges.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/app_shell.dart';

class IssueDetailScreen extends StatelessWidget {
  final IssueEntity issue;
  const IssueDetailScreen({super.key, required this.issue});

  String _fmt(DateTime? d) =>
    d == null ? '—' : DateFormat('dd MMM yyyy, HH:mm').format(d);

  @override
  Widget build(BuildContext context) {
    final authVm  = context.watch<AuthViewModel>();
    final issueVm = context.read<IssueViewModel>();
    final isAdmin = authVm.isAdmin;

    return AppShell(
      activePage: SidebarPage.issues,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Breadcrumb
          Row(children: [
            GestureDetector(
              onTap: () => Navigator.pushNamedAndRemoveUntil(
                context, '/issues', (_) => false),
              child: const Text('Issues',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted))),
            const Text(' › ',
              style: TextStyle(fontSize: 12, color: AppTheme.textDim)),
            Text(issue.issueId,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12, color: AppTheme.accent)),
          ]),
          const SizedBox(height: 16),

          // Header
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(issue.issueId,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 13, color: AppTheme.accent)),
                  const SizedBox(width: 10),
                  PriorityBadge(priority: issue.priority),
                  const SizedBox(width: 8),
                  StatusBadge(status: issue.status),
                ]),
                const SizedBox(height: 8),
                Text(issue.issueSummary,
                  style: GoogleFonts.cabin(
                    fontSize: 20, fontWeight: FontWeight.w700,
                    color: AppTheme.textColor, letterSpacing: -0.3)),
                const SizedBox(height: 6),
                Text('${issue.customer} · ${issue.technology} · Opened ${_fmt(issue.startDate ?? issue.createdAt)}',
                  style: const TextStyle(
                    fontSize: 12.5, color: AppTheme.textMuted)),
              ],
            )),
            const SizedBox(width: 16),
            Row(children: [
              OutlinedButton.icon(
                onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) =>
                    CreateIssueScreen(existing: issue))),
                icon: const Icon(Icons.edit_outlined, size: 14),
                label: const Text('Edit'),
              ),
              const SizedBox(width: 8),
              if (isAdmin) OutlinedButton.icon(
                onPressed: () => _confirmDelete(context, issueVm),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.red,
                  side: const BorderSide(color: AppTheme.border)),
                icon: const Icon(Icons.delete_outline, size: 14),
                label: const Text('Delete'),
              ),
            ]),
          ]),
          const SizedBox(height: 24),

          // Body
          LayoutBuilder(builder: (ctx, box) {
            final wide = box.maxWidth > 800;
            final main = _buildMain(context, issueVm, authVm);
            final side = _buildSide(context, issueVm, authVm);
            return wide
                ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: main),
                    const SizedBox(width: 20),
                    SizedBox(width: 280, child: side),
                  ])
                : Column(children: [main, const SizedBox(height: 16), side]);
          }),
          const SizedBox(height: 60),
        ]),
      ),
    );
  }

  Widget _buildMain(BuildContext context, IssueViewModel vm, AuthViewModel authVm) {
    return Column(children: [
      // Summary
      _DetailCard(title: 'Issue Summary', child: Text(
        issue.issueSummary,
        style: const TextStyle(
          fontSize: 14, color: AppTheme.textMuted, height: 1.7))),
      const SizedBox(height: 16),

      // Details grid
      _DetailCard(title: 'Issue Details', child: Column(children: [
        _InfoGrid(items: [
          _InfoItem('Client',      issue.customer),
          _InfoItem('Technology',  issue.technology),
          _InfoItem('Process',     issue.processName),
          _InfoItem('Priority',    issue.priority,  badge: true, isBadge: 'priority'),
          _InfoItem('Status',      issue.status,    badge: true, isBadge: 'status'),
          _InfoItem('Root Cause',  issue.rootCauseCategory),
          _InfoItem('Assigned To', issue.assignedTo),
          _InfoItem('Start Date',  _fmt(issue.startDate)),
          _InfoItem('Closing',     _fmt(issue.closingDate)),
        ]),
      ])),
      const SizedBox(height: 16),

      // Action taken
      if (issue.actionTaken.isNotEmpty)
        _DetailCard(title: 'Action Taken', child: Text(
          issue.actionTaken,
          style: const TextStyle(
            fontSize: 14, color: AppTheme.textMuted, height: 1.7))),
    ]);
  }

  Widget _buildSide(BuildContext context, IssueViewModel vm, AuthViewModel authVm) {
    return Column(children: [
      // Quick status update
      _SideSection(title: 'Update Status', child: Column(children: [
        _StatusSelector(current: issue.status, onChanged: (s) async {
          await vm.updateIssue(
            existing: issue,
            data: {'status': s},
            by: authVm.currentUser!,
          );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: AppTheme.card,
              content: Text('Status updated to $s',
                style: const TextStyle(color: AppTheme.textColor)),
              behavior: SnackBarBehavior.floating,
            ));
            Navigator.pushNamedAndRemoveUntil(context, '/issues', (_) => false);
          }
        }),
      ])),
      const SizedBox(height: 14),

      // Audit trail
      _SideSection(title: 'Audit Trail', child: _AuditTrail(issue: issue)),
      const SizedBox(height: 14),

      // People
      _SideSection(title: 'People', child: Column(children: [
        _PersonRow(label: 'Opened by',  name: issue.createdByName),
        _PersonRow(label: 'Assigned to', name: issue.assignedTo),
        _PersonRow(label: 'Resolved by',
          name: issue.resolvedByName ?? '—', dim: issue.resolvedByName == null),
        _PersonRow(label: 'Closed by',
          name: issue.closedByName ?? '—', dim: issue.closedByName == null),
      ])),
    ]);
  }

  void _confirmDelete(BuildContext context, IssueViewModel vm) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppTheme.border)),
        title: const Text('Delete Issue',
          style: TextStyle(color: AppTheme.textColor)),
        content: Text('Delete ${issue.issueId}? This cannot be undone.',
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
              await vm.deleteIssue(issue.id);
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

// ────────────────────────────────────────────────────────────────
class _DetailCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _DetailCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppTheme.card, borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppTheme.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
        child: Text(title,
          style: GoogleFonts.cabin(
            fontSize: 14, fontWeight: FontWeight.w600,
            color: AppTheme.textColor))),
      const Divider(height: 1),
      Padding(padding: const EdgeInsets.all(20), child: child),
    ]),
  );
}

class _InfoItem {
  final String label, value;
  final bool badge;
  final String? isBadge;
  const _InfoItem(this.label, this.value, {this.badge = false, this.isBadge});
}

class _InfoGrid extends StatelessWidget {
  final List<_InfoItem> items;
  const _InfoGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    final pairs = <Widget>[];
    for (int i = 0; i < items.length; i += 2) {
      pairs.add(Row(children: [
        Expanded(child: _cell(items[i])),
        if (i + 1 < items.length) ...[
          const SizedBox(width: 16),
          Expanded(child: _cell(items[i + 1])),
        ] else const Expanded(child: SizedBox()),
      ]));
      if (i + 2 < items.length) const SizedBox(height: 14);
      pairs.add(const SizedBox(height: 14));
    }
    return Column(children: pairs);
  }

  Widget _cell(_InfoItem item) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(item.label.toUpperCase(),
        style: const TextStyle(
          fontSize: 10, fontWeight: FontWeight.w600,
          color: AppTheme.textDim, letterSpacing: 0.8)),
      const SizedBox(height: 6),
      if (item.isBadge == 'priority')
        PriorityBadge(priority: item.value)
      else if (item.isBadge == 'status')
        StatusBadge(status: item.value)
      else
        Text(item.value,
          style: const TextStyle(
            fontSize: 13.5, color: AppTheme.textColor)),
    ],
  );
}

class _SideSection extends StatelessWidget {
  final String title;
  final Widget child;
  const _SideSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppTheme.card, borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppTheme.border)),
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

class _StatusSelector extends StatefulWidget {
  final String current;
  final void Function(String) onChanged;
  const _StatusSelector({required this.current, required this.onChanged});

  @override
  State<_StatusSelector> createState() => _StatusSelectorState();
}

class _StatusSelectorState extends State<_StatusSelector> {
  late String _selected;
  @override
  void initState() { super.initState(); _selected = widget.current; }

  @override
  Widget build(BuildContext context) => Column(children: [
    Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.inkSoft, borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppTheme.border)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selected, dropdownColor: AppTheme.inkSoft,
          style: const TextStyle(fontSize: 13, color: AppTheme.textColor),
          icon: const Icon(Icons.keyboard_arrow_down,
            size: 16, color: AppTheme.textDim),
          items: AppConstants.statuses.map((s) =>
            DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (v) => setState(() => _selected = v!),
        ),
      ),
    ),
    const SizedBox(height: 10),
    SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => widget.onChanged(_selected),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10)),
        child: const Text('Update Status'),
      ),
    ),
  ]);
}

class _AuditTrail extends StatelessWidget {
  final IssueEntity issue;
  const _AuditTrail({required this.issue});

  @override
  Widget build(BuildContext context) {
    final entries = <_AuditEntry>[
      _AuditEntry(
        action: 'Issue Created',
        by: issue.createdByName,
        at: issue.createdAt,
        color: AppTheme.blue,
        icon: '+'),
    ];
    if (issue.lastUpdatedByName != null)
      entries.add(_AuditEntry(
        action: 'Last Updated',
        by: issue.lastUpdatedByName!,
        at: issue.lastUpdatedAt,
        color: AppTheme.orange,
        icon: '↑'));
    if (issue.resolvedByName != null)
      entries.add(_AuditEntry(
        action: 'Resolved',
        by: issue.resolvedByName!,
        at: issue.resolvedAt,
        color: AppTheme.green,
        icon: '✓'));
    if (issue.closedByName != null)
      entries.add(_AuditEntry(
        action: 'Closed',
        by: issue.closedByName!,
        at: issue.closedAt,
        color: AppTheme.textDim,
        icon: '🔒'));

    return Column(
      children: entries.asMap().entries.map((e) {
        final entry = e.value;
        final isLast = e.key == entries.length - 1;
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Column(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: entry.color.withOpacity(0.12),
                border: Border.all(color: entry.color.withOpacity(0.4))),
              child: Center(child: Text(entry.icon,
                style: TextStyle(fontSize: 11, color: entry.color)))),
            if (!isLast) Container(
              width: 1, height: 24,
              color: AppTheme.border),
          ]),
          const SizedBox(width: 10),
          Expanded(child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.action,
                  style: TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w600,
                    color: entry.color)),
                const SizedBox(height: 2),
                Text('by ${entry.by}',
                  style: const TextStyle(
                    fontSize: 11.5, color: AppTheme.textMuted)),
                if (entry.at != null)
                  Text(
                    DateFormat('dd MMM yyyy · HH:mm').format(entry.at!),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10.5, color: AppTheme.textDim)),
              ],
            ),
          )),
        ]);
      }).toList(),
    );
  }
}

class _AuditEntry {
  final String action, by, icon;
  final DateTime? at;
  final Color color;
  const _AuditEntry({
    required this.action, required this.by, required this.at,
    required this.color, required this.icon,
  });
}

class _PersonRow extends StatelessWidget {
  final String label, name;
  final bool dim;
  const _PersonRow({
    required this.label, required this.name, this.dim = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(children: [
      Expanded(child: Text(label,
        style: const TextStyle(
          fontSize: 12, color: AppTheme.textMuted))),
      Text(name,
        style: TextStyle(
          fontSize: 12.5, fontWeight: FontWeight.w500,
          color: dim ? AppTheme.textDim : AppTheme.textColor)),
    ]),
  );
}
