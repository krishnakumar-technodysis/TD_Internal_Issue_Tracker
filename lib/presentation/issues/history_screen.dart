// lib/presentation/issues/history_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/issue_entity.dart';
import '../../domain/entities/project_entity.dart';
import '../../domain/entities/task_entity.dart';
import '../issues/issue_viewmodel.dart';
import '../issues/issue_detail_screen.dart';
import '../projects/project_view_model.dart';
import '../widgets/app_shell.dart';
import '../widgets/app_sidebar.dart';

// ─────────────────────────────────────────────────────────────────────
// Activity event type — add new types here for future entities
// ─────────────────────────────────────────────────────────────────────
enum ActivityType {
  issue   ('Issue',   '🐛', AppTheme.blue),
  project ('Project', '📁', AppTheme.accent),
  task    ('Task',    '✅', AppTheme.green);

  final String label;
  final String icon;
  final Color  color;
  const ActivityType(this.label, this.icon, this.color);
}

// ─────────────────────────────────────────────────────────────────────
// Normalised activity event — wraps any entity
// ─────────────────────────────────────────────────────────────────────
class ActivityEvent {
  final ActivityType type;
  final String id;           // display ID / name
  final String title;        // main line
  final String subtitle;     // secondary line (by / client / project)
  final String status;
  final String createdByName;
  final DateTime createdAt;
  final dynamic rawEntity;   // original entity for navigation

  const ActivityEvent({
    required this.type,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.createdByName,
    required this.createdAt,
    this.rawEntity,
  });

  // ── Factories ────────────────────────────────────────────────────
  factory ActivityEvent.fromIssue(IssueEntity e) => ActivityEvent(
    type:          ActivityType.issue,
    id:            e.issueId,
    title:         e.issueSummary,
    subtitle:      'by ${e.createdByName} · ${e.customer} · ${e.technology}',
    status:        e.status,
    createdByName: e.createdByName,
    createdAt:     e.createdAt,
    rawEntity:     e,
  );

  factory ActivityEvent.fromProject(ProjectEntity e) => ActivityEvent(
    type:          ActivityType.project,
    id:            'PRJ',
    title:         e.name,
    subtitle:      'by ${e.createdByName} · ${e.client} · ${e.priority}',
    status:        e.status,
    createdByName: e.createdByName,
    createdAt:     e.createdAt,
    rawEntity:     e,
  );

  factory ActivityEvent.fromTask(TaskEntity e) => ActivityEvent(
    type:          ActivityType.task,
    id:            'TSK',
    title:         e.title,
    subtitle:      'by ${e.createdByName} · ${e.projectName} · assigned to ${e.assignedToName}',
    status:        e.status,
    createdByName: e.createdByName,
    createdAt:     e.createdAt,
    rawEntity:     e,
  );

  // ── Status display helpers ────────────────────────────────────────
  String get statusLabel => switch (type) {
    ActivityType.issue   => status,
    ActivityType.project => _projectStatusLabel(status),
    ActivityType.task    => _taskStatusLabel(status),
  };

  String get actionLabel => switch (type) {
    ActivityType.issue   => _issueAction(status),
    ActivityType.project => _projectAction(status),
    ActivityType.task    => _taskAction(status),
  };

  Color get statusColor => switch (type) {
    ActivityType.issue   => AppTheme.statusColor(status),
    ActivityType.project => _projectStatusColor(status),
    ActivityType.task    => _taskStatusColor(status),
  };

  static String _projectStatusLabel(String s) => switch (s) {
    'active'    => 'Active',
    'on_hold'   => 'On Hold',
    'completed' => 'Completed',
    _           => 'Cancelled',
  };
  static String _taskStatusLabel(String s) => switch (s) {
    'todo'        => 'To Do',
    'in_progress' => 'In Progress',
    'review'      => 'Review',
    'done'        => 'Done',
    _             => 'Cancelled',
  };
  static String _issueAction(String s) => switch (s) {
    'Resolved'   => 'Issue resolved',
    'Closed'     => 'Issue closed',
    'In Progress'=> 'Issue in progress',
    _            => 'Issue created',
  };
  static String _projectAction(String s) => switch (s) {
    'completed' => 'Project completed',
    'on_hold'   => 'Project on hold',
    'cancelled' => 'Project cancelled',
    _           => 'Project created',
  };
  static String _taskAction(String s) => switch (s) {
    'done'        => 'Task completed',
    'in_progress' => 'Task in progress',
    'review'      => 'Task in review',
    'cancelled'   => 'Task cancelled',
    _             => 'Task created',
  };
  static Color _projectStatusColor(String s) => switch (s) {
    'active'    => AppTheme.green,
    'on_hold'   => AppTheme.orange,
    'completed' => AppTheme.accent,
    _           => AppTheme.red,
  };
  static Color _taskStatusColor(String s) => switch (s) {
    'done'        => AppTheme.green,
    'in_progress' => AppTheme.purple,
    'review'      => AppTheme.orange,
    'cancelled'   => AppTheme.red,
    _             => AppTheme.blue,
  };
}

// ─────────────────────────────────────────────────────────────────────
// History Screen
// ─────────────────────────────────────────────────────────────────────
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  ActivityType? _typeFilter;     // null = all types
  String        _statusFilter = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  // Build unified event list from all three streams
  List<ActivityEvent> _buildEvents(
      List<IssueEntity>   issues,
      List<ProjectEntity> projects,
      List<TaskEntity>    tasks,
      ) {
    final events = <ActivityEvent>[
      ...issues.map(ActivityEvent.fromIssue),
      ...projects.map(ActivityEvent.fromProject),
      ...tasks.map(ActivityEvent.fromTask),
    ];
    events.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return events;
  }

  List<ActivityEvent> _filter(List<ActivityEvent> all) {
    final q = _searchCtrl.text.toLowerCase();
    return all.where((e) {
      final matchType   = _typeFilter == null || e.type == _typeFilter;
      final matchStatus = _statusFilter.isEmpty || e.statusLabel == _statusFilter;
      final matchSearch = q.isEmpty
          || e.title.toLowerCase().contains(q)
          || e.id.toLowerCase().contains(q)
          || e.createdByName.toLowerCase().contains(q)
          || e.subtitle.toLowerCase().contains(q);
      return matchType && matchStatus && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final issueVm   = context.watch<IssueViewModel>();
    final projectVm = context.watch<ProjectViewModel>();

    return AppShell(
      activePage: SidebarPage.history,
      child: StreamBuilder<List<ProjectEntity>>(
        stream: projectVm.getAllProjects(),
        builder: (_, projectSnap) {
          final projects = projectSnap.data ?? [];

          // Collect all tasks across all projects via a multi-stream approach
          // For simplicity use cached project task counts; for live tasks
          // we build a secondary stream aggregator using FutureBuilder
          return _HistoryBody(
            issueVm:  issueVm,
            projects: projects,
            projectVm: projectVm,
            typeFilter:   _typeFilter,
            statusFilter: _statusFilter,
            searchCtrl:   _searchCtrl,
            onTypeFilter:   (t) => setState(() {
              _typeFilter = _typeFilter == t ? null : t;
              _statusFilter = '';
            }),
            onStatusFilter: (s) => setState(() => _statusFilter = _statusFilter == s ? '' : s),
            onSearch: () => setState(() {}),
            buildEvents: _buildEvents,
            filter: _filter,
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Main body — handles task stream aggregation
// ─────────────────────────────────────────────────────────────────────
class _HistoryBody extends StatelessWidget {
  final IssueViewModel issueVm;
  final ProjectViewModel projectVm;
  final List<ProjectEntity> projects;
  final ActivityType? typeFilter;
  final String statusFilter;
  final TextEditingController searchCtrl;
  final void Function(ActivityType) onTypeFilter;
  final void Function(String) onStatusFilter;
  final VoidCallback onSearch;
  final List<ActivityEvent> Function(List<IssueEntity>, List<ProjectEntity>, List<TaskEntity>) buildEvents;
  final List<ActivityEvent> Function(List<ActivityEvent>) filter;

  const _HistoryBody({
    required this.issueVm, required this.projectVm, required this.projects,
    required this.typeFilter, required this.statusFilter, required this.searchCtrl,
    required this.onTypeFilter, required this.onStatusFilter, required this.onSearch,
    required this.buildEvents, required this.filter,
  });

  @override
  Widget build(BuildContext context) {
    // Combine tasks from the task viewmodel stream (all tasks)
    // by using getTasksByProject per project — we union them into one list
    // For scalability, we stream all tasks via a separate Firestore query if available
    // Here we use issueVm.allIssues (sync) and stream projects/tasks:
    return StreamBuilder<List<TaskEntity>>(
      stream: projectVm.getAllTasks(),
      builder: (_, taskSnap) {
        // taskSnap may be empty if getMyTasks filters by uid; use empty list fallback
        final tasks = taskSnap.data ?? [];
        final all   = buildEvents(issueVm.allIssues, projects, tasks);
        final shown = filter(all);

        return Column(children: [
          _Header(searchCtrl: searchCtrl, onSearch: onSearch, total: shown.length, allTotal: all.length),
          _TypeTabs(selected: typeFilter, onTap: onTypeFilter, events: all),
          _StatusChips(
              typeFilter: typeFilter, statusFilter: statusFilter,
              onTap: onStatusFilter, events: all),
          _CountBar(shown: shown.length, total: all.length, filtered: typeFilter != null || statusFilter.isNotEmpty || searchCtrl.text.isNotEmpty),
          Expanded(child: shown.isEmpty
              ? _EmptyState(hasFilter: typeFilter != null || statusFilter.isNotEmpty || searchCtrl.text.isNotEmpty)
              : ListView.builder(
            itemCount: shown.length,
            itemBuilder: (ctx, i) => _EventRow(event: shown[i]),
          )),
        ]);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final TextEditingController searchCtrl;
  final VoidCallback onSearch;
  final int total, allTotal;
  const _Header({required this.searchCtrl, required this.onSearch,
    required this.total, required this.allTotal});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(24, 22, 24, 16),
    decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border))),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Activity History',
            style: GoogleFonts.dmSans(fontSize: 22, fontWeight: FontWeight.w700,
                color: AppTheme.textColor, letterSpacing: -0.5)),
        const SizedBox(height: 4),
        const Text('Unified audit log — issues, projects & tasks',
            style: TextStyle(fontSize: 12.5, color: AppTheme.textMuted)),
      ])),
      // Search box
      Container(
        height: 36, width: 220,
        decoration: BoxDecoration(color: AppTheme.inkSoft,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: AppTheme.border)),
        child: TextField(
          controller: searchCtrl,
          onChanged: (_) => onSearch(),
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
  );
}

// ─────────────────────────────────────────────────────────────────────
// Type tabs — Issues / Projects / Tasks (extensible)
// ─────────────────────────────────────────────────────────────────────
class _TypeTabs extends StatelessWidget {
  final ActivityType? selected;
  final void Function(ActivityType) onTap;
  final List<ActivityEvent> events;
  const _TypeTabs({required this.selected, required this.onTap, required this.events});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.border))),
      child: Row(children: [
        // "All" pill
        _TypePill(
          label: 'All',
          icon: '📋',
          count: events.length,
          active: selected == null,
          color: AppTheme.textMuted,
          onTap: () {
            // Tapping All when already all = no-op; we handle deselect in parent
            if (selected != null) onTap(selected!); // will deselect
          },
        ),
        const SizedBox(width: 8),
        // One pill per type
        ...ActivityType.values.map((t) {
          final count = events.where((e) => e.type == t).length;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _TypePill(
              label: t.label,
              icon: t.icon,
              count: count,
              active: selected == t,
              color: t.color,
              onTap: () => onTap(t),
            ),
          );
        }),
      ]),
    );
  }
}

class _TypePill extends StatelessWidget {
  final String label, icon;
  final int count;
  final bool active;
  final Color color;
  final VoidCallback onTap;
  const _TypePill({required this.label, required this.icon,
    required this.count, required this.active, required this.color,
    required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
          color: active ? color.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? color : AppTheme.border)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(icon, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600,
            color: active ? color : AppTheme.textMuted)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
              color: (active ? color : AppTheme.textDim).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8)),
          child: Text('$count', style: TextStyle(fontSize: 10,
              fontWeight: FontWeight.w700,
              color: active ? color : AppTheme.textDim)),
        ),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────
// Status filter chips — dynamically built from the current type
// ─────────────────────────────────────────────────────────────────────
class _StatusChips extends StatelessWidget {
  final ActivityType? typeFilter;
  final String statusFilter;
  final void Function(String) onTap;
  final List<ActivityEvent> events;
  const _StatusChips({required this.typeFilter, required this.statusFilter,
    required this.onTap, required this.events});

  List<String> _statusLabels() {
    final relevant = typeFilter == null
        ? events
        : events.where((e) => e.type == typeFilter).toList();
    final labels = relevant.map((e) => e.statusLabel).toSet().toList()..sort();
    return labels;
  }

  @override
  Widget build(BuildContext context) {
    final labels = _statusLabels();
    if (labels.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.border))),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          _StatusChip('All Statuses', '', statusFilter, () => onTap('')),
          ...labels.map((s) => _StatusChip(s, s, statusFilter, () => onTap(s))),
        ]),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label, value, current;
  final VoidCallback onTap;
  const _StatusChip(this.label, this.value, this.current, this.onTap);
  @override
  Widget build(BuildContext context) {
    final active = value == current;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: active ? AppTheme.accent.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: active ? AppTheme.accent : AppTheme.border)),
        child: Text(label, style: TextStyle(fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: active ? AppTheme.accent : AppTheme.textMuted)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Count bar
// ─────────────────────────────────────────────────────────────────────
class _CountBar extends StatelessWidget {
  final int shown, total;
  final bool filtered;
  const _CountBar({required this.shown, required this.total, required this.filtered});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
    decoration: const BoxDecoration(
        color: Color(0x04FFFFFF),
        border: Border(bottom: BorderSide(color: AppTheme.border))),
    child: Row(children: [
      Text(filtered ? '$shown of $total events' : '$total events',
          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
      const Text(' — sorted by newest first',
          style: TextStyle(fontSize: 12, color: AppTheme.textDim)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  const _EmptyState({required this.hasFilter});
  @override
  Widget build(BuildContext context) => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(hasFilter ? '🔍' : '📭',
          style: const TextStyle(fontSize: 40)),
      const SizedBox(height: 12),
      Text(hasFilter ? 'No events match your filters'
          : 'No activity yet',
          style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600,
              color: AppTheme.textColor)),
      if (hasFilter) ...[
        const SizedBox(height: 6),
        const Text('Try adjusting the type or status filter',
            style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
      ],
    ],
  ));
}

// ─────────────────────────────────────────────────────────────────────
// Event Row — renders any ActivityEvent
// ─────────────────────────────────────────────────────────────────────
class _EventRow extends StatefulWidget {
  final ActivityEvent event;
  const _EventRow({required this.event});
  @override State<_EventRow> createState() => _EventRowState();
}

class _EventRowState extends State<_EventRow> {
  bool _hover = false;

  void _navigate(BuildContext context) {
    final e = widget.event;
    switch (e.type) {
      case ActivityType.issue:
        Navigator.push(context, MaterialPageRoute(
            builder: (_) => IssueDetailScreen(issue: e.rawEntity as IssueEntity)));
      case ActivityType.project:
        Navigator.pushNamed(context, '/projects');
      case ActivityType.task:
        Navigator.pushNamed(context, '/projects');
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => _navigate(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          decoration: BoxDecoration(
              color: _hover ? Colors.white.withOpacity(0.02) : Colors.transparent,
              border: const Border(
                  bottom: BorderSide(color: Color(0x08FFFFFF)))),
          child: Row(children: [
            // Type icon badge
            _TypeIcon(type: e.type),
            const SizedBox(width: 14),

            // Content
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Action label + title
                RichText(text: TextSpan(
                  style: const TextStyle(fontSize: 13,
                      fontWeight: FontWeight.w500, color: AppTheme.textColor),
                  children: [
                    TextSpan(text: '${e.actionLabel} — ',
                        style: TextStyle(color: e.type.color,
                            fontWeight: FontWeight.w600)),
                    TextSpan(text: e.title),
                  ],
                ), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(e.subtitle,
                    style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                    overflow: TextOverflow.ellipsis),
              ],
            )),
            const SizedBox(width: 12),

            // Status badge
            _StatusBadge(label: e.statusLabel, color: e.statusColor),
            const SizedBox(width: 16),

            // Date
            SizedBox(width: 80,
                child: Text(_relDate(e.createdAt), textAlign: TextAlign.right,
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 10.5, color: AppTheme.textDim))),
          ]),
        ),
      ),
    );
  }

  String _relDate(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays == 0) return DateFormat('HH:mm').format(d);
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7)  return '${diff.inDays}d ago';
    return DateFormat('dd MMM').format(d);
  }
}

// ─────────────────────────────────────────────────────────────────────
// Type icon badge
// ─────────────────────────────────────────────────────────────────────
class _TypeIcon extends StatelessWidget {
  final ActivityType type;
  const _TypeIcon({required this.type});
  @override
  Widget build(BuildContext context) => Container(
    width: 38, height: 38,
    decoration: BoxDecoration(
        color: type.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: type.color.withOpacity(0.25))),
    child: Center(child: Text(type.icon,
        style: const TextStyle(fontSize: 17))),
  );
}

// ─────────────────────────────────────────────────────────────────────
// Generic status badge (replaces StatusBadge for mixed statuses)
// ─────────────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String label;
  final Color  color;
  const _StatusBadge({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3))),
    child: Text(label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
        overflow: TextOverflow.ellipsis),
  );
}