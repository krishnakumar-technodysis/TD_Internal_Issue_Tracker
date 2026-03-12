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
import '../widgets/app_button.dart';
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

        // ── Header ────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
          decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.border))),
          child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('All Issues',
                  style: GoogleFonts.syne(
                      fontSize: 22, fontWeight: FontWeight.w700,
                      color: AppTheme.textColor, letterSpacing: -0.5)),
              const SizedBox(height: 5),
              Wrap(spacing: 12, children: [
                _StatPill('${vm.allIssues.length}', 'total', AppTheme.textMuted),
                if (vm.openIssues > 0)
                  _StatPill('${vm.openIssues}', 'open', AppTheme.orange),
                if (vm.inProgressIssues > 0)
                  _StatPill('${vm.inProgressIssues}', 'in progress', AppTheme.purple),
                if (vm.criticalIssues > 0)
                  _StatPill('${vm.criticalIssues}', 'critical', AppTheme.red),
              ]),
            ]),
            const Spacer(),
            AppButton(
              label: 'New Issue',
              icon: Icons.add,
              onPressed: () => Navigator.pushNamed(context, '/create'),
            ),
          ]),
        ),

        // ── Search & Filters ──────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          decoration: BoxDecoration(
              color: AppTheme.inkSoft.withOpacity(0.5),
              border: const Border(
                  bottom: BorderSide(color: AppTheme.border))),
          child: LayoutBuilder(builder: (_, box) {
            final isWide = box.maxWidth > 700;
            if (isWide) return Row(children: _buildFilters(vm));
            // Narrow: search full width, chips in Wrap (no Expanded in Wrap)
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SearchBox(controller: _searchCtrl, onChanged: vm.setSearch),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8,
                    children: _buildNarrowFilters(vm)),
              ],
            );
          }),
        ),

        // ── Column headers ────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(20, 9, 20, 9),
          decoration: BoxDecoration(
              color: AppTheme.ink.withOpacity(0.6),
              border: const Border(
                  bottom: BorderSide(color: AppTheme.border))),
          child: _ColumnHeader(),
        ),

        // ── List ──────────────────────────────────────────────────────
        Expanded(
          child: vm.issues.isEmpty
              ? const _EmptyState()
              : ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: ListView.builder(
              primary: false,
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: vm.issues.length,
              itemBuilder: (ctx, i) => _IssueRow(
                issue: vm.issues[i],
                isEven: i % 2 == 0,
                onTap: () => Navigator.push(ctx,
                    MaterialPageRoute(builder: (_) =>
                        IssueDetailScreen(issue: vm.issues[i]))),
                onEdit: () => Navigator.pushNamed(ctx, '/edit',
                    arguments: vm.issues[i]),
              ),
            ),
          ),
        ),

        // ── Footer ────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.border))),
          child: Text(
              vm.issues.length == vm.allIssues.length
                  ? 'Showing all ${vm.issues.length} issue${vm.issues.length != 1 ? "s" : ""}'
                  : 'Showing ${vm.issues.length} of ${vm.allIssues.length} issues',
              style: const TextStyle(fontSize: 12, color: AppTheme.textDim)),
        ),
      ]),
    );
  }

  List<Widget> _buildFilters(IssueViewModel vm) => [
    Expanded(
      flex: 4,
      child: _SearchBox(
        controller: _searchCtrl,
        onChanged: vm.setSearch,
      ),
    ),
    const SizedBox(width: 10),
    _FilterChip(
      label: 'Status', value: vm.filterStatus,
      items: const ['', ...AppConstants.statuses],
      onChanged: vm.setFilterStatus,
    ),
    const SizedBox(width: 8),
    _FilterChip(
      label: 'Client', value: vm.filterCustomer,
      items: ['', ...AppConstants.customers],
      onChanged: vm.setFilterCustomer,
    ),
    const SizedBox(width: 8),
    _FilterChip(
      label: 'Priority', value: vm.filterPriority,
      items: ['', ...AppConstants.priorities],
      onChanged: vm.setFilterPriority,
    ),
    if (vm.filterStatus.isNotEmpty || vm.filterCustomer.isNotEmpty ||
        vm.filterPriority.isNotEmpty || _searchCtrl.text.isNotEmpty) ...[
      const SizedBox(width: 6),
      GestureDetector(
        onTap: () { vm.clearFilters(); _searchCtrl.clear(); },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: AppTheme.border)),
          child: const Text('✕  Clear',
              style: TextStyle(
                  fontSize: 12, color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500)),
        ),
      ),
    ],
  ];

  // Same as _buildFilters but without Expanded (safe to use in Wrap)
  List<Widget> _buildNarrowFilters(IssueViewModel vm) => [
    _FilterChip(
      label: 'Status', value: vm.filterStatus,
      items: const ['', ...AppConstants.statuses],
      onChanged: vm.setFilterStatus,
    ),
    _FilterChip(
      label: 'Client', value: vm.filterCustomer,
      items: ['', ...AppConstants.customers],
      onChanged: vm.setFilterCustomer,
    ),
    _FilterChip(
      label: 'Priority', value: vm.filterPriority,
      items: ['', ...AppConstants.priorities],
      onChanged: vm.setFilterPriority,
    ),
    if (vm.filterStatus.isNotEmpty || vm.filterCustomer.isNotEmpty ||
        vm.filterPriority.isNotEmpty || _searchCtrl.text.isNotEmpty)
      GestureDetector(
        onTap: () { vm.clearFilters(); _searchCtrl.clear(); },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
              color: AppTheme.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.red.withOpacity(0.3))),
          child: const Text('✕ Clear',
              style: TextStyle(fontSize: 12, color: AppTheme.red)),
        ),
      ),
  ];
}

// ── Search box ────────────────────────────────────────────────────────
class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onChanged;
  const _SearchBox({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
    height: 38,
    decoration: BoxDecoration(
      color: AppTheme.inkSoft,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppTheme.border),
    ),
    child: TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13, color: AppTheme.textColor),
      decoration: const InputDecoration(
        hintText: 'Search by ID, summary, client…',
        prefixIcon: Icon(Icons.search_rounded,
            size: 17, color: AppTheme.textDim),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(vertical: 11),
        isDense: true,
      ),
    ),
  );
}

// ── Filter chip dropdown ──────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label, value;
  final List<String> items;
  final void Function(String) onChanged;
  const _FilterChip({
    required this.label, required this.value,
    required this.items, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final active = value.isNotEmpty;
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: active
            ? AppTheme.accent.withOpacity(0.1)
            : AppTheme.inkSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: active
                ? AppTheme.accent.withOpacity(0.5)
                : AppTheme.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: AppTheme.inkMid,
          isDense: true,
          icon: Icon(Icons.expand_more_rounded,
              size: 15,
              color: active ? AppTheme.accent : AppTheme.textDim),
          style: TextStyle(
              fontSize: 12.5,
              color: active ? AppTheme.accent : AppTheme.textMuted),
          items: items.map((v) => DropdownMenuItem(
            value: v,
            child: Text(
                v.isEmpty ? label : v,
                style: TextStyle(
                    fontSize: 12.5,
                    color: v.isEmpty ? AppTheme.textDim : AppTheme.textColor)),
          )).toList(),
          onChanged: (v) => onChanged(v ?? ''),
        ),
      ),
    );
  }
}

// ── Column header ─────────────────────────────────────────────────────
class _ColumnHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
        fontSize: 10.5, fontWeight: FontWeight.w700,
        color: AppTheme.textDim, letterSpacing: 0.8);
    return Row(children: const [
      SizedBox(width: 10),                                // left indent
      SizedBox(width: 80,  child: Text('ID',          style: style)),
      Expanded(flex: 5,    child: Text('SUMMARY',     style: style)),
      SizedBox(width: 10),
      SizedBox(width: 110, child: Text('CLIENT',      style: style)),
      SizedBox(width: 100, child: Text('PRIORITY',    style: style)),
      SizedBox(width: 140, child: Text('STATUS',      style: style)),
      SizedBox(width: 130, child: Text('ASSIGNED TO', style: style)),
      SizedBox(width: 90,  child: Text('OPENED',      style: style)),
      SizedBox(width: 50),
    ]);
  }
}

// ── Issue row ─────────────────────────────────────────────────────────
class _IssueRow extends StatefulWidget {
  final IssueEntity issue;
  final bool isEven;
  final VoidCallback onTap, onEdit;
  const _IssueRow({
    required this.issue, required this.isEven,
    required this.onTap, required this.onEdit,
  });

  @override
  State<_IssueRow> createState() => _IssueRowState();
}

class _IssueRowState extends State<_IssueRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final issue = widget.issue;
    final bg = _hover
        ? AppTheme.inkMid.withOpacity(0.7)
        : widget.isEven
        ? AppTheme.inkSoft.withOpacity(0.35)
        : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            color: bg,
            border: const Border(
                bottom: BorderSide(color: Color(0x18FFFFFF))),
          ),
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ID
              SizedBox(width: 80,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(issue.issueId,
                          style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              color: AppTheme.accent,
                              fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis),
                    ],
                  )),

              // Summary + sub-line
              Expanded(flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(issue.issueSummary,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500,
                              color: AppTheme.textColor, height: 1.4),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      if (issue.processName.trim().isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(issue.processName,
                            style: const TextStyle(
                                fontSize: 11.5, color: AppTheme.textDim),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  )),

              const SizedBox(width: 10),

              // Client
              SizedBox(width: 110,
                  child: Padding(
                      padding: const EdgeInsets.only(top: 2, bottom: 2),
                      child: Wrap(children: [TagChip(label: issue.customer)]))),

              // Priority
              SizedBox(width: 100,
                  child: Padding(
                      padding: const EdgeInsets.only(top: 2, bottom: 2),
                      child: Wrap(children: [PriorityBadge(priority: issue.priority)]))),

              // Status
              SizedBox(width: 140,
                  child: Padding(
                      padding: const EdgeInsets.only(top: 2, bottom: 2),
                      child: Wrap(children: [StatusBadge(status: issue.status)]))),

              // Assigned To
              SizedBox(width: 130,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 2),
                    child: issue.assignedTo.isEmpty
                        ? const Text('—',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textDim))
                        : Row(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InitialAvatar(name: issue.assignedTo),
                          const SizedBox(width: 7),
                          Expanded(child: Text(issue.assignedTo,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12.5, color: AppTheme.textColor))),
                        ]),
                  )),

              // Opened
              SizedBox(width: 90,
                  child: Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 2),
                      child: Text(_fmtDate(issue.createdAt),
                          style: GoogleFonts.jetBrainsMono(
                              fontSize: 10.5, color: AppTheme.textDim)))),

              // Edit — visible only on hover
              SizedBox(width: 50,
                  child: AnimatedOpacity(
                    opacity: _hover ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 120),
                    child: TextButton(
                      onPressed: widget.onEdit,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Edit',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.accent,
                              fontWeight: FontWeight.w500)),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inHours   < 24 && d.day == DateTime.now().day) return 'Today';
    if (diff.inDays    == 1) return 'Yesterday';
    if (diff.inDays    <  7) return '${diff.inDays}d ago';
    return '${d.day} ${_months[d.month - 1]}';
  }

  static const _months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'];
}

// ── Initial avatar ────────────────────────────────────────────────────
class _InitialAvatar extends StatelessWidget {
  final String name;
  const _InitialAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(' ').length >= 2
        ? '${name.split(' ').first[0]}${name.split(' ').last[0]}'.toUpperCase()
        : name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
    final colors = [
      [AppTheme.blue,   AppTheme.accent],
      [AppTheme.purple, AppTheme.blue],
      [AppTheme.orange, AppTheme.yellow],
      [AppTheme.green,  AppTheme.accent],
    ];
    final ci = name.codeUnitAt(0) % colors.length;
    return Container(
      width: 24, height: 24,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          gradient: LinearGradient(
              colors: colors[ci],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight)),
      child: Center(child: Text(initials,
          style: const TextStyle(
              fontSize: 9.5, fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A)))),
    );
  }
}

// ── Stat pill ─────────────────────────────────────────────────────────
class _StatPill extends StatelessWidget {
  final String count, label;
  final Color color;
  const _StatPill(this.count, this.label, this.color);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
          width: 6, height: 6,
          decoration: BoxDecoration(
              color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      RichText(text: TextSpan(
        children: [
          TextSpan(text: count,
              style: TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w600,
                  color: color)),
          TextSpan(text: '  $label',
              style: const TextStyle(
                  fontSize: 12.5, color: AppTheme.textMuted)),
        ],
      )),
    ],
  );
}

// ── Empty state ───────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
              color: AppTheme.inkSoft,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.border)),
          child: const Center(
              child: Text('📭', style: TextStyle(fontSize: 32)))),
      const SizedBox(height: 18),
      Text('No issues found',
          style: GoogleFonts.syne(
              fontSize: 16, fontWeight: FontWeight.w600,
              color: AppTheme.textColor)),
      const SizedBox(height: 6),
      const Text('Adjust filters or create a new issue',
          style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
    ]),
  );
}