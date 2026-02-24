// lib/presentation/issues/issue_list_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/issue_entity.dart';
import '../widgets/app_shell.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/badges.dart';
import '../issues/issue_viewmodel.dart';
import '../issues/issue_detail_screen.dart';

class IssueListScreen extends StatefulWidget {
  const IssueListScreen({super.key});

  @override
  State<IssueListScreen> createState() => _IssueListScreenState();
}

class _IssueListScreenState extends State<IssueListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<IssueViewModel>();

    return AppShell(
      activePage: SidebarPage.issues,
      child: Column(children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppTheme.border))),
          child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('All Issues',
                style: GoogleFonts.syne(
                  fontSize: 22, fontWeight: FontWeight.w700,
                  color: AppTheme.textColor, letterSpacing: -0.5)),
              const SizedBox(height: 4),
              Text('${vm.allIssues.length} total issues across all clients',
                style: const TextStyle(
                  fontSize: 12.5, color: AppTheme.textMuted)),
            ]),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/create'),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('New Issue'),
            ),
          ]),
        ),

        // Search & filters
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(
            color: AppTheme.card,
            border: Border(bottom: BorderSide(color: AppTheme.border))),
          child: Row(children: [
            // Search
            Expanded(
              flex: 3,
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.inkSoft,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: AppTheme.border),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: vm.setSearch,
                  style: const TextStyle(
                    fontSize: 13, color: AppTheme.textColor),
                  decoration: const InputDecoration(
                    hintText: 'Search by ID, summary, client...',
                    prefixIcon: Icon(Icons.search, size: 16, color: AppTheme.textDim),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                    isDense: true,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _FilterDrop(
              label: 'Status', value: vm.filterStatus,
              items: const ['', ...AppConstants.statuses],
              onChanged: vm.setFilterStatus,
            ),
            const SizedBox(width: 8),
            _FilterDrop(
              label: 'Client', value: vm.filterCustomer,
              items: ['', ...AppConstants.customers],
              onChanged: vm.setFilterCustomer,
            ),
            const SizedBox(width: 8),
            _FilterDrop(
              label: 'Priority', value: vm.filterPriority,
              items: ['', ...AppConstants.priorities],
              onChanged: vm.setFilterPriority,
            ),
            const SizedBox(width: 8),
            if (vm.filterStatus.isNotEmpty || vm.filterCustomer.isNotEmpty ||
                vm.filterPriority.isNotEmpty || _searchCtrl.text.isNotEmpty)
              GestureDetector(
                onTap: () { vm.clearFilters(); _searchCtrl.clear(); },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Clear', style: TextStyle(
                    fontSize: 12, color: AppTheme.accent))),
              ),
          ]),
        ),

        // Table header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0x06FFFFFF),
            border: Border(bottom: BorderSide(color: AppTheme.border))),
          child: _TableHeader(),
        ),

        // Issues
        Expanded(
          child: vm.issues.isEmpty
              ? _EmptyState()
              : ListView.builder(
                  itemCount: vm.issues.length,
                  itemBuilder: (ctx, i) => _IssueRow(
                    issue: vm.issues[i],
                    onTap: () => Navigator.push(ctx,
                      MaterialPageRoute(builder: (_) =>
                        IssueDetailScreen(issue: vm.issues[i]))),
                    onEdit: () => Navigator.pushNamed(ctx, '/edit',
                      arguments: vm.issues[i]),
                  ),
                ),
        ),

        // Pagination bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppTheme.border))),
          child: Row(children: [
            Text('Showing ${vm.issues.length} of ${vm.allIssues.length} issues',
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            const Spacer(),
            ...List.generate(3, (i) => Container(
              margin: const EdgeInsets.only(left: 4),
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: i == 0 ? AppTheme.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.border),
              ),
              child: Center(child: Text('${i + 1}',
                style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: i == 0 ? AppTheme.ink : AppTheme.textMuted))),
            )),
          ]),
        ),
      ]),
    );
  }
}

class _FilterDrop extends StatelessWidget {
  final String label, value;
  final List<String> items;
  final void Function(String) onChanged;

  const _FilterDrop({
    required this.label, required this.value,
    required this.items, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final active = value.isNotEmpty;
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: active ? AppTheme.accent.withOpacity(0.1) : AppTheme.inkSoft,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: active ? AppTheme.accent : AppTheme.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: AppTheme.inkSoft,
          style: TextStyle(
            fontSize: 12, color: active ? AppTheme.accent : AppTheme.textMuted),
          icon: Icon(Icons.keyboard_arrow_down,
            size: 14,
            color: active ? AppTheme.accent : AppTheme.textDim),
          items: items.map((i) => DropdownMenuItem(
            value: i,
            child: Text(i.isEmpty ? label : i,
              style: const TextStyle(fontSize: 12)),
          )).toList(),
          onChanged: (v) => onChanged(v ?? ''),
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const s = TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600,
      color: AppTheme.textDim, letterSpacing: 0.6);
    return Row(children: const [
      SizedBox(width: 90, child: Text('ID', style: s)),
      Expanded(flex: 4, child: Text('SUMMARY', style: s)),
      SizedBox(width: 90, child: Text('CLIENT', style: s)),
      SizedBox(width: 110, child: Text('TECHNOLOGY', style: s)),
      SizedBox(width: 85, child: Text('PRIORITY', style: s)),
      SizedBox(width: 130, child: Text('STATUS', style: s)),
      SizedBox(width: 110, child: Text('ASSIGNED TO', style: s)),
      SizedBox(width: 80, child: Text('OPENED', style: s)),
      SizedBox(width: 60),
    ]);
  }
}

class _IssueRow extends StatefulWidget {
  final IssueEntity issue;
  final VoidCallback onTap, onEdit;
  const _IssueRow({required this.issue, required this.onTap, required this.onEdit});

  @override
  State<_IssueRow> createState() => _IssueRowState();
}

class _IssueRowState extends State<_IssueRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final issue = widget.issue;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          decoration: BoxDecoration(
            color: _hover ? Colors.white.withOpacity(0.025) : Colors.transparent,
            border: const Border(
              bottom: BorderSide(color: Color(0x08FFFFFF))),
          ),
          child: Row(children: [
            SizedBox(width: 90,
              child: Text(issue.issueId,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11.5, color: AppTheme.accent,
                  fontWeight: FontWeight.w500))),
            Expanded(flex: 4, child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(issue.issueSummary,
                  style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500,
                    color: AppTheme.textColor),
                  overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('${issue.technology} • ${issue.rootCauseCategory}',
                  style: const TextStyle(
                    fontSize: 11, color: AppTheme.textMuted)),
              ],
            )),
            SizedBox(width: 90, child: TagChip(label: issue.customer)),
            SizedBox(width: 110,
              child: Text(issue.technology,
                style: const TextStyle(
                  fontSize: 11.5, color: AppTheme.textMuted))),
            SizedBox(width: 85,
              child: PriorityBadge(priority: issue.priority)),
            SizedBox(width: 130,
              child: StatusBadge(status: issue.status)),
            SizedBox(width: 110,
              child: Text(issue.assignedTo,
                style: const TextStyle(
                  fontSize: 12, color: AppTheme.textColor),
                overflow: TextOverflow.ellipsis)),
            SizedBox(width: 80,
              child: Text(
                _fmtDate(issue.createdAt),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11, color: AppTheme.textDim))),
            SizedBox(width: 60,
              child: TextButton(
                onPressed: widget.onEdit,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                ),
                child: const Text('Edit',
                  style: TextStyle(
                    fontSize: 12, color: AppTheme.textMuted)),
              )),
          ]),
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day)
      return 'Today';
    if (d.year == now.year && d.month == now.month && d.day == now.day - 1)
      return 'Yesterday';
    return '${d.day} ${_months[d.month - 1]}';
  }

  static const _months = ['Jan','Feb','Mar','Apr','May','Jun',
                           'Jul','Aug','Sep','Oct','Nov','Dec'];
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('📭', style: TextStyle(fontSize: 48)),
      const SizedBox(height: 16),
      Text('No issues found',
        style: GoogleFonts.syne(
          fontSize: 16, fontWeight: FontWeight.w600,
          color: AppTheme.textColor)),
      const SizedBox(height: 8),
      const Text('Try adjusting your filters or search',
        style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
    ]),
  );
}
