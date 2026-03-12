// lib/presentation/dashboard/user_dashboard.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/project_entity.dart';
import '../../domain/entities/task_entity.dart';
import '../auth/auth_viewmodel.dart';
import '../projects/project_detail_screen.dart';
import '../projects/project_view_model.dart';
import '../widgets/app_shell.dart';
import '../widgets/app_sidebar.dart';

class UserDashboard extends StatelessWidget {
  const UserDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final projVm = context.watch<ProjectViewModel>();
    final user   = authVm.currentUser;
    final uid    = user?.uid ?? '';
    final name   = user?.displayName ?? 'User';

    return AppShell(
      activePage: SidebarPage.userDashboard,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Greeting ──────────────────────────────────────────────────
            _Greeting(name: name),
            const SizedBox(height: 24),

            // ── My Tasks ──────────────────────────────────────────────────
            const _SectionHeader(title: 'My Tasks', icon: '✅'),
            const SizedBox(height: 12),
            StreamBuilder<List<TaskEntity>>(
              stream: projVm.getMyTasks(uid),
              builder: (context, snap) {
                final tasks = snap.data ?? [];
                if (snap.connectionState == ConnectionState.waiting && tasks.isEmpty) {
                  return const _LoadingBox();
                }
                if (tasks.isEmpty) {
                  return const _EmptyBox(
                    icon: '✅',
                    message: 'No tasks assigned to you yet.',
                  );
                }
                return _TaskKanban(tasks: tasks);
              },
            ),
            const SizedBox(height: 32),

            // ── My Projects ───────────────────────────────────────────────
            const _SectionHeader(title: 'My Projects', icon: '📁'),
            const SizedBox(height: 12),
            StreamBuilder<List<ProjectEntity>>(
              stream: projVm.getMyProjects(uid),
              builder: (context, snap) {
                final projects = snap.data ?? [];
                if (snap.connectionState == ConnectionState.waiting && projects.isEmpty) {
                  return const _LoadingBox();
                }
                if (projects.isEmpty) {
                  return const _EmptyBox(
                    icon: '📁',
                    message: "You haven't been added to any projects yet.",
                  );
                }
                return _ProjectList(projects: projects);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Greeting
// ─────────────────────────────────────────────────────────────────────────────
class _Greeting extends StatelessWidget {
  final String name;
  const _Greeting({required this.name});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('$greeting, ${name.split(' ').first}',
          style: GoogleFonts.dmSans(
              fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textColor)),
      const SizedBox(height: 4),
      Text(DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
          style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Header
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title, icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) => Row(children: [
    Text(icon, style: const TextStyle(fontSize: 16)),
    const SizedBox(width: 8),
    Text(title,
        style: GoogleFonts.dmSans(
            fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textColor)),
  ]);
}

// ─────────────────────────────────────────────────────────────────────────────
// Task Kanban — groups by status
// ─────────────────────────────────────────────────────────────────────────────
class _TaskKanban extends StatelessWidget {
  final List<TaskEntity> tasks;
  const _TaskKanban({required this.tasks});

  static const _columns = [
    ('todo',        'To Do',       AppTheme.blue),
    ('in_progress', 'In Progress', AppTheme.purple),
    ('review',      'Review',      AppTheme.orange),
    ('done',        'Done',        AppTheme.green),
  ];

  @override
  Widget build(BuildContext context) {
    // Stat bar at top
    final open     = tasks.where((t) => t.isOpen).length;
    final overdue  = tasks.where((t) => t.isOverdue).length;
    final done     = tasks.where((t) => t.isDone).length;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      // Quick stats
      Wrap(spacing: 8, runSpacing: 8, children: [
        _StatChip('$open', 'Open',    AppTheme.blue),
        _StatChip('$done', 'Done',    AppTheme.green),
        if (overdue > 0) _StatChip('$overdue', 'Overdue', AppTheme.red),
      ]),
      const SizedBox(height: 16),

      // Columns
      LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth > 700;
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _columns.map((col) {
              final (status, label, color) = col;
              final colTasks = tasks.where((t) => t.status == status).toList();
              return Expanded(child: _KanbanColumn(
                  label: label, color: color, tasks: colTasks));
            }).toList(),
          );
        }
        // Narrow: stacked
        return Column(children: _columns.map((col) {
          final (status, label, color) = col;
          final colTasks = tasks.where((t) => t.status == status).toList();
          if (colTasks.isEmpty) return const SizedBox.shrink();
          return _KanbanColumn(label: label, color: color, tasks: colTasks);
        }).toList());
      }),
    ]);
  }
}

class _KanbanColumn extends StatelessWidget {
  final String label;
  final Color color;
  final List<TaskEntity> tasks;
  const _KanbanColumn({required this.label, required this.color, required this.tasks});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(right: 8, bottom: 8),
    decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Column header
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Row(children: [
          Container(width: 8, height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          const Spacer(),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8)),
              child: Text('${tasks.length}',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color))),
        ]),
      ),
      if (tasks.isEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Text('No tasks', style: TextStyle(fontSize: 11.5, color: color.withOpacity(0.6))),
        )
      else
        ...tasks.map((t) => _TaskCard(task: t)),
      const SizedBox(height: 4),
    ]),
  );
}

class _TaskCard extends StatelessWidget {
  final TaskEntity task;
  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final priorityColor = AppTheme.priorityColor(task.priority);
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(task.title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: AppTheme.textColor),
            maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 6),
        Row(children: [
          Container(width: 6, height: 6,
              decoration: BoxDecoration(color: priorityColor, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(task.priority,
              style: TextStyle(fontSize: 10.5, color: priorityColor)),
          const Spacer(),
          if (task.dueDate != null) ...[
            Icon(Icons.schedule_rounded, size: 11,
                color: task.isOverdue ? AppTheme.red : AppTheme.textDim),
            const SizedBox(width: 3),
            Text(DateFormat('dd MMM').format(task.dueDate!),
                style: TextStyle(fontSize: 10.5,
                    color: task.isOverdue ? AppTheme.red : AppTheme.textDim)),
          ],
        ]),
        if (task.projectName.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('📁 ${task.projectName}',
              style: const TextStyle(fontSize: 10, color: AppTheme.textDim),
              overflow: TextOverflow.ellipsis),
        ],
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Project List
// ─────────────────────────────────────────────────────────────────────────────
class _ProjectList extends StatelessWidget {
  final List<ProjectEntity> projects;
  const _ProjectList({required this.projects});

  @override
  Widget build(BuildContext context) {
    return Column(children: projects.map((p) => _ProjectRow(project: p)).toList());
  }
}

class _ProjectRow extends StatelessWidget {
  final ProjectEntity project;
  const _ProjectRow({required this.project});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(project.status);
    final progress    = project.progress;

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => ProjectDetailScreen(projectId: project.id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(project.name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                    color: AppTheme.textColor),
                overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            _Badge(_statusLabel(project.status), statusColor),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            Text(project.client, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            const Spacer(),
            Text(
                '${project.taskCount - project.openTaskCount}/${project.taskCount} tasks',
                style: const TextStyle(fontSize: 11, color: AppTheme.textDim)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                  value: progress, minHeight: 4,
                  backgroundColor: AppTheme.border,
                  valueColor: AlwaysStoppedAnimation(statusColor))),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            Text('${(progress * 100).round()}% complete',
                style: const TextStyle(fontSize: 10.5, color: AppTheme.textDim)),
          ]),
        ]),
      ),
    );
  }

  Color _statusColor(String s) => switch (s) {
    'active'    => AppTheme.green,
    'on_hold'   => AppTheme.orange,
    'completed' => AppTheme.accent,
    _           => AppTheme.red,
  };
  String _statusLabel(String s) => switch (s) {
    'active'    => 'Active',
    'on_hold'   => 'On Hold',
    'completed' => 'Done',
    _           => 'Cancelled',
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String value, label;
  final Color color;
  const _StatChip(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
    ]),
  );
}

class _Badge extends StatelessWidget {
  final String text; final Color color;
  const _Badge(this.text, this.color);
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Text(text, style: TextStyle(
          fontSize: 10.5, fontWeight: FontWeight.w600, color: color)));
}

class _LoadingBox extends StatelessWidget {
  const _LoadingBox();
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: CircularProgressIndicator(color: AppTheme.accent),
    ),
  );
}

class _EmptyBox extends StatelessWidget {
  final String icon, message;
  const _EmptyBox({required this.icon, required this.message});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border)),
    child: Row(children: [
      Text(icon, style: const TextStyle(fontSize: 24)),
      const SizedBox(width: 12),
      Expanded(child: Text(message,
          style: const TextStyle(fontSize: 13, color: AppTheme.textMuted))),
    ]),
  );
}
