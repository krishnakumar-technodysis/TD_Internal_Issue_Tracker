// lib/presentation/projects/project_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:issue_tracker/presentation/projects/project_view_model.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/project_entity.dart';
import '../../domain/entities/task_entity.dart';
import '../auth/auth_viewmodel.dart';
import '../widgets/app_shell.dart';
import '../widgets/app_sidebar.dart';
import 'create_project_screen.dart';
import 'create_task_screen.dart';

class ProjectDetailScreen extends StatelessWidget {
  final String projectId;
  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    final projVm  = context.watch<ProjectViewModel>();
    final authVm  = context.watch<AuthViewModel>();
    final isAdmin = authVm.currentUser?.isAdmin ?? false;

    return AppShell(
      activePage: SidebarPage.projects,
      child: FutureBuilder<ProjectEntity>(
        future: projVm.getProject(projectId),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final project = snap.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header bar
              _ProjectHeader(
                  project: project, isAdmin: isAdmin, projVm: projVm),
              const Divider(height: 1, color: AppTheme.border),
              // Body
              Expanded(child: _ProjectBody(
                  project: project, isAdmin: isAdmin, projVm: projVm)),
            ],
          );
        },
      ),
    );
  }
}

class _ProjectHeader extends StatelessWidget {
  final ProjectEntity project;
  final bool isAdmin;
  final ProjectViewModel projVm;
  const _ProjectHeader({required this.project,
    required this.isAdmin, required this.projVm});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(project.status);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(children: [
        IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textDim),
            onPressed: () => Navigator.pop(context)),
        const SizedBox(width: 8),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(project.name,
                  style: const TextStyle(fontSize: 18,
                      fontWeight: FontWeight.w700, color: AppTheme.textColor)),
              const SizedBox(width: 10),
              _Badge(_statusLabel(project.status), statusColor),
            ]),
            Text('${project.client} • ${project.priority} priority',
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          ],
        )),
        if (isAdmin) ...[
          // Delete button
          IconButton(
            tooltip: 'Delete Project',
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppTheme.red, size: 20),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppTheme.card,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  title: Row(children: [
                    Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: AppTheme.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.delete_outline_rounded,
                            color: AppTheme.red, size: 20)),
                    const SizedBox(width: 12),
                    const Text('Delete Project',
                        style: TextStyle(fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textColor)),
                  ]),
                  content: Column(mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(text: TextSpan(
                          style: const TextStyle(fontSize: 13.5,
                              color: AppTheme.textMuted, height: 1.5),
                          children: [
                            const TextSpan(text: 'Are you sure you want to delete '),
                            TextSpan(text: '"${project.name}"',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textColor)),
                            const TextSpan(text: '?'),
                          ],
                        )),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: AppTheme.red.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: AppTheme.red.withOpacity(0.2))),
                          child: const Row(children: [
                            Icon(Icons.warning_amber_rounded,
                                color: AppTheme.red, size: 15),
                            SizedBox(width: 8),
                            Expanded(child: Text(
                                'This will permanently delete the project and all its tasks. This cannot be undone.',
                                style: TextStyle(fontSize: 12,
                                    color: AppTheme.red))),
                          ]),
                        ),
                      ]),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel',
                            style: TextStyle(color: AppTheme.textMuted))),
                    ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8))),
                        child: const Text('Yes, Delete')),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                await context.read<ProjectViewModel>().deleteProject(project.id);
                if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/projects', (_) => false);
              }
            },
          ),
          const SizedBox(width: 4),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => CreateProjectScreen(existing: project))),
            icon: const Icon(Icons.edit_outlined, size: 14),
            label: const Text('Edit', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => CreateTaskScreen(projectId: project.id, projectName: project.name))),
            icon: const Icon(Icons.add_rounded, size: 14),
            label: const Text('Add Task', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
          ),
        ],
      ]),
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
    'completed' => 'Completed',
    _           => 'Cancelled',
  };
}

class _ProjectBody extends StatefulWidget {
  final ProjectEntity project;
  final bool isAdmin;
  final ProjectViewModel projVm;
  const _ProjectBody({required this.project,
    required this.isAdmin, required this.projVm});
  @override State<_ProjectBody> createState() => _ProjectBodyState();
}

class _ProjectBodyState extends State<_ProjectBody> {
  String _taskFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 900;

    return StreamBuilder<List<TaskEntity>>(
      stream: widget.projVm.getProjectTasks(widget.project.id),
      builder: (context, snap) {
        final allTasks = snap.data ?? [];
        final filtered = _taskFilter == 'All'
            ? allTasks
            : allTasks.where((t) =>
        t.status.toLowerCase() == _taskFilter.toLowerCase()).toList();

        if (isWide) {
          return Row(children: [
            // Left: project info
            SizedBox(width: 280,
                child: _ProjectInfoPanel(project: widget.project)),
            const VerticalDivider(width: 1, color: AppTheme.border),
            // Right: tasks
            Expanded(child: _TasksPanel(
              tasks: filtered, allTasks: allTasks,
              filter: _taskFilter, isAdmin: widget.isAdmin,
              projVm: widget.projVm,
              projectId: widget.project.id,
              projectName: widget.project.name,
              onFilterChange: (f) => setState(() => _taskFilter = f),
            )),
          ]);
        } else {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              _ProjectInfoPanel(project: widget.project),
              const SizedBox(height: 20),
              _TasksPanel(
                tasks: filtered, allTasks: allTasks,
                filter: _taskFilter, isAdmin: widget.isAdmin,
                projVm: widget.projVm,
                projectId: widget.project.id,
                projectName: widget.project.name,
                onFilterChange: (f) => setState(() => _taskFilter = f),
              ),
            ]),
          );
        }
      },
    );
  }
}

class _ProjectInfoPanel extends StatelessWidget {
  final ProjectEntity project;
  const _ProjectInfoPanel({required this.project});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Progress
        const Text('PROGRESS', style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w700,
            color: AppTheme.textDim, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        ClipRRect(borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
                value: project.progress, minHeight: 8,
                backgroundColor: AppTheme.border,
                valueColor: const AlwaysStoppedAnimation(AppTheme.accent))),
        const SizedBox(height: 6),
        Text('${(project.progress * 100).round()}% complete'
            ' (${project.taskCount - project.openTaskCount}/${project.taskCount} tasks)',
            style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted)),
        const SizedBox(height: 20),

        // Details
        _InfoRow(Icons.business_outlined, 'Client', project.client),
        _InfoRow(Icons.flag_outlined, 'Priority', project.priority),
        if (project.endDate != null)
          _InfoRow(Icons.calendar_today_outlined, 'Due Date',
              DateFormat('dd MMM yyyy').format(project.endDate!)),
        _InfoRow(Icons.person_outline_rounded, 'Created by',
            project.createdByName),
        _InfoRow(Icons.calendar_month_outlined, 'Created',
            DateFormat('dd MMM yyyy').format(project.createdAt)),
        const SizedBox(height: 16),

        // Description
        if (project.description.isNotEmpty) ...[
          const Text('DESCRIPTION', style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700,
              color: AppTheme.textDim, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text(project.description,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textMuted, height: 1.5)),
          const SizedBox(height: 16),
        ],

        // Members
        const Text('TEAM', style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w700,
            color: AppTheme.textDim, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        if (project.memberUids.isEmpty)
          const Text('No members assigned',
              style: TextStyle(fontSize: 12, color: AppTheme.textDim))
        else
          Text('${project.memberUids.length} member(s) assigned',
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Icon(icon, size: 14, color: AppTheme.textDim),
      const SizedBox(width: 8),
      Text('$label: ', style: const TextStyle(
          fontSize: 12, color: AppTheme.textMuted)),
      Expanded(child: Text(value, style: const TextStyle(
          fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textColor),
          overflow: TextOverflow.ellipsis)),
    ]),
  );
}

class _TasksPanel extends StatelessWidget {
  final List<TaskEntity> tasks, allTasks;
  final String filter, projectId, projectName;
  final bool isAdmin;
  final ProjectViewModel projVm;
  final ValueChanged<String> onFilterChange;
  const _TasksPanel({required this.tasks, required this.allTasks,
    required this.filter, required this.projectId, required this.projectName,
    required this.isAdmin, required this.projVm, required this.onFilterChange});

  @override
  Widget build(BuildContext context) {
    const statuses = ['All', 'todo', 'in_progress', 'review', 'done', 'cancelled'];
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: statuses.map((s) {
            final count = s == 'All' ? allTasks.length
                : allTasks.where((t) => t.status == s).length;
            final selected = filter == s;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                label: Text('${_statusLabel(s)} ($count)'),
                selected: selected,
                onSelected: (_) => onFilterChange(s),
                selectedColor: AppTheme.accent.withOpacity(0.15),
                checkmarkColor: AppTheme.accent,
                labelStyle: TextStyle(fontSize: 11.5,
                    color: selected ? AppTheme.accent : AppTheme.textMuted),
              ),
            );
          }).toList()),
        ),
        const SizedBox(height: 16),

        if (tasks.isEmpty)
          const Expanded(child: Center(child: Text('No tasks',
              style: TextStyle(color: AppTheme.textDim))))
        else
          Expanded(child: ListView.separated(
            itemCount: tasks.length,
            separatorBuilder: (_, __) =>
            const Divider(height: 1, color: AppTheme.border),
            itemBuilder: (_, i) => _TaskRow(
                task: tasks[i], isAdmin: isAdmin, projVm: projVm,
                projectId: projectId, projectName: projectName),
          )),
      ]),
    );
  }

  String _statusLabel(String s) => switch (s) {
    'All'         => 'All',
    'todo'        => 'To Do',
    'in_progress' => 'In Progress',
    'review'      => 'Review',
    'done'        => 'Done',
    'cancelled'   => 'Cancelled',
    _             => s,
  };
}

class _TaskRow extends StatelessWidget {
  final TaskEntity task;
  final bool isAdmin;
  final ProjectViewModel projVm;
  final String projectId;
  final String projectName;
  const _TaskRow({required this.task, required this.isAdmin,
    required this.projVm, required this.projectId, required this.projectName});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(task.status);
    final authVm = context.read<AuthViewModel>();
    final canEdit = isAdmin ||
        authVm.currentUser?.uid == task.assignedToUid;

    return Container(
      color: AppTheme.card,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        // Status indicator
        Container(width: 4, height: 40,
            decoration: BoxDecoration(
                color: statusColor, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 12),

        // Content
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(task.title,
                  style: TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w600,
                      color: AppTheme.textColor,
                      decoration: task.isDone
                          ? TextDecoration.lineThrough : null))),
              _PriorityChip(task.priority),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.person_outline_rounded, size: 12, color: AppTheme.textDim),
              const SizedBox(width: 4),
              Text(task.assignedToName,
                  style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted)),
              if (task.dueDate != null) ...[
                const SizedBox(width: 12),
                Icon(Icons.schedule_rounded, size: 12,
                    color: task.isOverdue ? AppTheme.red : AppTheme.textDim),
                const SizedBox(width: 3),
                Text(DateFormat('dd MMM').format(task.dueDate!),
                    style: TextStyle(fontSize: 11.5,
                        color: task.isOverdue ? AppTheme.red : AppTheme.textMuted)),
              ],
            ]),
          ],
        )),
        const SizedBox(width: 12),

        // Status dropdown
        if (canEdit)
          DropdownButton<String>(
            value: task.status,
            isDense: true,
            underline: const SizedBox(),
            style: const TextStyle(fontSize: 12, color: AppTheme.textColor),
            items: ['todo','in_progress','review','done','cancelled']
                .map((s) => DropdownMenuItem(
                value: s,
                child: Text(_statusLabel(s),
                    style: TextStyle(color: _statusColor(s)))))
                .toList(),
            onChanged: (s) {
              if (s != null) projVm.updateTaskStatus(task.id, s);
            },
          ),

        // Edit/Delete (admin only)
        if (isAdmin)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded,
                size: 16, color: AppTheme.textDim),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit',
                  child: Text('Edit Task')),
              const PopupMenuItem(value: 'delete',
                  child: Text('Delete', style: TextStyle(color: AppTheme.red))),
            ],
            onSelected: (v) {
              if (v == 'edit') {
                Navigator.push(context, MaterialPageRoute(
                    builder: (_) => CreateTaskScreen(
                        projectId: projectId, projectName: projectName, existing: task)));
              } else {
                projVm.deleteTask(task.id);
              }
            },
          ),
      ]),
    );
  }

  Color _statusColor(String s) => switch (s) {
    'todo'        => AppTheme.textDim,
    'in_progress' => AppTheme.blue,
    'review'      => AppTheme.orange,
    'done'        => AppTheme.green,
    'cancelled'   => AppTheme.red,
    _             => AppTheme.textDim,
  };
  String _statusLabel(String s) => switch (s) {
    'todo'        => 'To Do',
    'in_progress' => 'In Progress',
    'review'      => 'Review',
    'done'        => 'Done',
    'cancelled'   => 'Cancelled',
    _             => s,
  };
}

class _PriorityChip extends StatelessWidget {
  final String priority;
  const _PriorityChip(this.priority);
  Color get color => switch (priority) {
    'Critical' => AppTheme.red,
    'High'     => AppTheme.orange,
    'Medium'   => AppTheme.blue,
    _          => AppTheme.textDim,
  };
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10)),
    child: Text(priority,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
  );
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3))),
    child: Text(text, style: TextStyle(
        fontSize: 10.5, fontWeight: FontWeight.w600, color: color)),
  );
}