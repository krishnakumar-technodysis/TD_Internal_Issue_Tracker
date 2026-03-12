// lib/presentation/dashboard/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/project_entity.dart';
import '../../domain/entities/task_entity.dart';
import '../auth/auth_viewmodel.dart';
import '../issues/issue_viewmodel.dart';
import '../projects/create_project_screen.dart';
import '../projects/project_screen.dart';
import '../projects/project_detail_screen.dart';
import '../projects/project_view_model.dart';
import '../widgets/app_shell.dart';
import '../widgets/app_sidebar.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm  = context.watch<AuthViewModel>();
    final projVm  = context.watch<ProjectViewModel>();
    final issueVm = context.watch<IssueViewModel>();
    final user    = authVm.currentUser;
    final name    = user?.displayName ?? 'Admin';

    return AppShell(
      activePage: SidebarPage.adminDashboard,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Header ────────────────────────────────────────────────────
            _DashHeader(name: name, user: user),
            const SizedBox(height: 24),

            // ── Project + Task streams ────────────────────────────────────
            StreamBuilder<List<ProjectEntity>>(
              stream: projVm.getAllProjects(),
              builder: (context, projSnap) {
                final projects = projSnap.data ?? [];

                return StreamBuilder<List<TaskEntity>>(
                  stream: projVm.getAllTasks(),
                  builder: (context, taskSnap) {
                    final tasks = taskSnap.data ?? [];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // ── Summary cards ──────────────────────────────
                        _SummaryRow(
                            projects: projects,
                            tasks: tasks,
                            issueVm: issueVm),
                        const SizedBox(height: 24),

                        // ── Quick actions ──────────────────────────────
                        _QuickActions(),
                        const SizedBox(height: 28),

                        // ── Projects list ─────────────────────────────
                        _SectionHeader(
                          title: 'Active Projects',
                          icon: '📁',
                          action: projects.isNotEmpty
                              ? TextButton(
                                  onPressed: () => Navigator.push(context,
                                      MaterialPageRoute(
                                          builder: (_) => const ProjectsScreen())),
                                  child: const Text('View all',
                                      style: TextStyle(color: AppTheme.accent)))
                              : null,
                        ),
                        const SizedBox(height: 12),
                        if (projects.isEmpty)
                          _EmptyBox(
                            icon: '📁',
                            message: 'No projects yet. Create one to get started.',
                            action: ElevatedButton.icon(
                              onPressed: () => Navigator.push(context,
                                  MaterialPageRoute(
                                      builder: (_) => const CreateProjectScreen())),
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: const Text('Create Project'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.accent,
                                  foregroundColor: Colors.white),
                            ),
                          )
                        else
                          _ProjectSummaryList(
                              projects: projects
                                  .where((p) => p.status == 'active')
                                  .take(5)
                                  .toList()),
                        const SizedBox(height: 28),

                        // ── Tasks overview ─────────────────────────────
                        const _SectionHeader(title: 'Task Overview', icon: '✅'),
                        const SizedBox(height: 12),
                        if (tasks.isEmpty)
                          const _EmptyBox(icon: '✅', message: 'No tasks found.')
                        else
                          _TaskStatusGrid(tasks: tasks),
                        const SizedBox(height: 24),

                        // ── Overdue tasks ──────────────────────────────
                        if (tasks.any((t) => t.isOverdue)) ...[
                          const _SectionHeader(
                              title: 'Overdue Tasks', icon: '🔴'),
                          const SizedBox(height: 12),
                          _OverdueTaskList(
                              tasks: tasks.where((t) => t.isOverdue).take(5).toList()),
                          const SizedBox(height: 24),
                        ],
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────
class _DashHeader extends StatelessWidget {
  final String name;
  final dynamic user;
  const _DashHeader({required this.name, required this.user});

  @override
  Widget build(BuildContext context) {
    final hour     = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    return Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$greeting, ${name.split(' ').first}',
            style: GoogleFonts.dmSans(
                fontSize: 22, fontWeight: FontWeight.w700,
                color: AppTheme.textColor)),
        const SizedBox(height: 4),
        Text(DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
            style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
      ])),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary row cards
// ─────────────────────────────────────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final List<ProjectEntity> projects;
  final List<TaskEntity> tasks;
  final IssueViewModel issueVm;
  const _SummaryRow({required this.projects, required this.tasks, required this.issueVm});

  @override
  Widget build(BuildContext context) {
    final activeProj  = projects.where((p) => p.isActive).length;
    final openTasks   = tasks.where((t) => t.isOpen).length;
    final overdueTasks = tasks.where((t) => t.isOverdue).length;
    final openIssues  = issueVm.openIssues;

    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth > 800 ? 4 : constraints.maxWidth > 500 ? 2 : 1;
      return GridView.count(
        crossAxisCount: cols,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _SummaryCard(
              icon: '📁', label: 'Active Projects',
              value: '$activeProj', color: AppTheme.accent),
          _SummaryCard(
              icon: '✅', label: 'Open Tasks',
              value: '$openTasks', color: AppTheme.blue),
          _SummaryCard(
              icon: '⚠️', label: 'Overdue Tasks',
              value: '$overdueTasks',
              color: overdueTasks > 0 ? AppTheme.red : AppTheme.textDim),
          _SummaryCard(
              icon: '🐛', label: 'Open Issues',
              value: '$openIssues', color: AppTheme.orange),
        ],
      );
    });
  }
}

class _SummaryCard extends StatelessWidget {
  final String icon, label, value;
  final Color color;
  const _SummaryCard({required this.icon, required this.label,
    required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border)),
    child: Row(children: [
      Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Center(child: Text(icon, style: const TextStyle(fontSize: 18)))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
        Text(label, style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted)),
      ])),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick actions
// ─────────────────────────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _SectionHeader(title: 'Quick Actions', icon: '⚡'),
      const SizedBox(height: 12),
      Wrap(spacing: 10, runSpacing: 10, children: [
        _ActionButton(
          icon: Icons.add_rounded,
          label: 'New Project',
          color: AppTheme.accent,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const CreateProjectScreen())),
        ),
        _ActionButton(
          icon: Icons.folder_open_rounded,
          label: 'All Projects',
          color: AppTheme.blue,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ProjectsScreen())),
        ),
        _ActionButton(
          icon: Icons.bug_report_outlined,
          label: 'All Issues',
          color: AppTheme.orange,
          onTap: () => Navigator.pushNamed(context, '/issues'),
        ),
      ]),
    ],
  );
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.label,
    required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: 16, color: color),
    label: Text(label, style: TextStyle(color: color, fontSize: 13)),
    style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        side: BorderSide(color: color.withOpacity(0.4)),
        backgroundColor: color.withOpacity(0.06)),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Project summary list
// ─────────────────────────────────────────────────────────────────────────────
class _ProjectSummaryList extends StatelessWidget {
  final List<ProjectEntity> projects;
  const _ProjectSummaryList({required this.projects});

  @override
  Widget build(BuildContext context) => Column(
    children: projects.map((p) => _ProjectSummaryRow(project: p)).toList(),
  );
}

class _ProjectSummaryRow extends StatelessWidget {
  final ProjectEntity project;
  const _ProjectSummaryRow({required this.project});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => ProjectDetailScreen(projectId: project.id))),
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(project.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                  color: AppTheme.textColor),
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Text(project.client,
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        ])),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${(project.progress * 100).round()}%',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                  color: AppTheme.accent)),
          const SizedBox(height: 4),
          SizedBox(width: 80, child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                  value: project.progress, minHeight: 4,
                  backgroundColor: AppTheme.border,
                  valueColor: const AlwaysStoppedAnimation(AppTheme.accent)))),
        ]),
        const SizedBox(width: 8),
        const Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.textDim),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Task status grid
// ─────────────────────────────────────────────────────────────────────────────
class _TaskStatusGrid extends StatelessWidget {
  final List<TaskEntity> tasks;
  const _TaskStatusGrid({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final todo       = tasks.where((t) => t.status == 'todo').length;
    final inProgress = tasks.where((t) => t.status == 'in_progress').length;
    final review     = tasks.where((t) => t.status == 'review').length;
    final done       = tasks.where((t) => t.isDone).length;

    return Wrap(spacing: 8, runSpacing: 8, children: [
      _TaskStatusChip('$todo', 'To Do',       AppTheme.blue),
      _TaskStatusChip('$inProgress', 'In Progress', AppTheme.purple),
      _TaskStatusChip('$review', 'Review',     AppTheme.orange),
      _TaskStatusChip('$done', 'Done',         AppTheme.green),
      _TaskStatusChip('${tasks.length}', 'Total', AppTheme.textDim),
    ]);
  }
}

class _TaskStatusChip extends StatelessWidget {
  final String count, label;
  final Color color;
  const _TaskStatusChip(this.count, this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25))),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(count, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.8))),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Overdue task list
// ─────────────────────────────────────────────────────────────────────────────
class _OverdueTaskList extends StatelessWidget {
  final List<TaskEntity> tasks;
  const _OverdueTaskList({required this.tasks});

  @override
  Widget build(BuildContext context) => Column(
    children: tasks.map((t) => Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppTheme.redBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.red.withOpacity(0.25))),
      child: Row(children: [
        const Icon(Icons.warning_amber_rounded, size: 16, color: AppTheme.red),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
              color: AppTheme.textColor), overflow: TextOverflow.ellipsis),
          if (t.dueDate != null)
            Text('Due: ${DateFormat('dd MMM yyyy').format(t.dueDate!)}',
                style: const TextStyle(fontSize: 11.5, color: AppTheme.red)),
        ])),
        const SizedBox(width: 8),
        Text('→ ${t.assignedToName}',
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
            overflow: TextOverflow.ellipsis),
      ]),
    )).toList(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title, icon;
  final Widget? action;
  const _SectionHeader({required this.title, required this.icon, this.action});

  @override
  Widget build(BuildContext context) => Row(children: [
    Text(icon, style: const TextStyle(fontSize: 16)),
    const SizedBox(width: 8),
    Text(title, style: GoogleFonts.dmSans(
        fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textColor)),
    const Spacer(),
    if (action != null) action!,
  ]);
}

class _EmptyBox extends StatelessWidget {
  final String icon, message;
  final Widget? action;
  const _EmptyBox({required this.icon, required this.message, this.action});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border)),
    child: Column(children: [
      Text(icon, style: const TextStyle(fontSize: 32)),
      const SizedBox(height: 10),
      Text(message, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
      if (action != null) ...[const SizedBox(height: 16), action!],
    ]),
  );
}
