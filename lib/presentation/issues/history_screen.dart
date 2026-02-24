// lib/presentation/issues/history_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/issue_entity.dart';
import '../issues/issue_viewmodel.dart';
import '../issues/issue_detail_screen.dart';
import '../widgets/app_shell.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/badges.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _filter = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  List<IssueEntity> _filtered(List<IssueEntity> all) {
    final q = _searchCtrl.text.toLowerCase();
    return all.where((i) {
      final ms = q.isEmpty
          || i.issueId.toLowerCase().contains(q)
          || i.issueSummary.toLowerCase().contains(q)
          || i.customer.toLowerCase().contains(q);
      final mf = _filter.isEmpty
          || i.status == _filter
          || i.customer == _filter;
      return ms && mf;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final vm  = context.watch<IssueViewModel>();
    final all = _filtered(vm.allIssues);

    return AppShell(
      activePage: SidebarPage.history,
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppTheme.border))),
          child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Issue History',
                style: GoogleFonts.syne(
                  fontSize: 22, fontWeight: FontWeight.w700,
                  color: AppTheme.textColor, letterSpacing: -0.5)),
              const SizedBox(height: 4),
              const Text('Complete audit log of all issue activity',
                style: TextStyle(
                  fontSize: 12.5, color: AppTheme.textMuted)),
            ]),
            const Spacer(),
            Container(
              height: 36, width: 220,
              decoration: BoxDecoration(
                color: AppTheme.inkSoft,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: AppTheme.border)),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(fontSize: 13, color: AppTheme.textColor),
                decoration: const InputDecoration(
                  hintText: 'Search history...',
                  prefixIcon: Icon(Icons.search, size: 16, color: AppTheme.textDim),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                  isDense: true,
                ),
              ),
            ),
          ]),
        ),

        // Filter chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppTheme.border))),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _Chip('All Activity',    '', _filter, () => setState(() => _filter = '')),
              ...[...AppConstants.statuses, ...AppConstants.customers].map((f) =>
                _Chip(f, f, _filter, () => setState(() => _filter = f))),
            ]),
          ),
        ),

        // Sub-header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0x04FFFFFF),
            border: Border(bottom: BorderSide(color: AppTheme.border))),
          child: Row(children: [
            Text('${all.length} events',
              style: const TextStyle(
                fontSize: 12, color: AppTheme.textMuted)),
            const Text(' — Showing most recent',
              style: TextStyle(fontSize: 12, color: AppTheme.textDim)),
          ]),
        ),

        // History list
        Expanded(
          child: all.isEmpty
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('📭', style: TextStyle(fontSize: 40)),
                    const SizedBox(height: 12),
                    Text('No history found',
                      style: GoogleFonts.syne(
                        fontSize: 15, fontWeight: FontWeight.w600,
                        color: AppTheme.textColor)),
                  ]))
              : ListView.builder(
                  itemCount: all.length,
                  itemBuilder: (ctx, i) =>
                    _HistoryRow(
                      issue: all[i],
                      onTap: () => Navigator.push(ctx,
                        MaterialPageRoute(builder: (_) =>
                          IssueDetailScreen(issue: all[i]))),
                    ),
                ),
        ),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label, value, current;
  final VoidCallback onTap;
  const _Chip(this.label, this.value, this.current, this.onTap);

  @override
  Widget build(BuildContext context) {
    final active = value == current;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppTheme.accent.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppTheme.accent : AppTheme.border),
        ),
        child: Text(label,
          style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w500,
            color: active ? AppTheme.accent : AppTheme.textMuted)),
      ),
    );
  }
}

class _HistoryRow extends StatefulWidget {
  final IssueEntity issue;
  final VoidCallback onTap;
  const _HistoryRow({required this.issue, required this.onTap});

  @override
  State<_HistoryRow> createState() => _HistoryRowState();
}

class _HistoryRowState extends State<_HistoryRow> {
  bool _hover = false;

  String get _emoji {
    switch (widget.issue.status) {
      case 'Resolved': return '✅';
      case 'Closed':   return '🔒';
      case 'Critical': return '🚨';
      default:         return '📋';
    }
  }

  Color get _emojiColor {
    switch (widget.issue.status) {
      case 'Resolved': return AppTheme.green;
      case 'Closed':   return AppTheme.textDim;
      case 'New':      return AppTheme.blue;
      case 'In Progress': return AppTheme.purple;
      default:         return AppTheme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final issue = widget.issue;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: _hover ? Colors.white.withOpacity(0.02) : Colors.transparent,
            border: const Border(
              bottom: BorderSide(color: Color(0x08FFFFFF)))),
          child: Row(children: [
            // ID
            SizedBox(width: 80,
              child: Text(issue.issueId,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11, color: AppTheme.accent))),
            // Icon
            Container(
              width: 36, height: 36,
              margin: const EdgeInsets.only(right: 14),
              decoration: BoxDecoration(
                color: _emojiColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text(_emoji,
                style: const TextStyle(fontSize: 16)))),
            // Summary
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _actionLabel(issue.status) + ' — ' + issue.issueSummary,
                  style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500,
                    color: AppTheme.textColor),
                  overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(
                  'by ${issue.createdByName} · ${issue.customer} · ${issue.technology}',
                  style: const TextStyle(
                    fontSize: 11.5, color: AppTheme.textMuted)),
              ],
            )),
            const SizedBox(width: 12),
            // Status badge
            StatusBadge(status: issue.status),
            const SizedBox(width: 16),
            // Date
            SizedBox(width: 80,
              child: Text(
                _relDate(issue.createdAt),
                textAlign: TextAlign.right,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10.5, color: AppTheme.textDim))),
          ]),
        ),
      ),
    );
  }

  String _actionLabel(String status) {
    switch (status) {
      case 'Resolved': return 'Issue resolved';
      case 'Closed':   return 'Issue closed';
      case 'In Progress': return 'In progress';
      default:         return 'Issue created';
    }
  }

  String _relDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays == 0) return DateFormat('HH:mm').format(d);
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7)  return '${diff.inDays} days ago';
    return DateFormat('dd MMM').format(d);
  }
}
