// lib/presentation/projects/projects_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:issue_tracker/presentation/projects/project_view_model.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/project_entity.dart';
import '../auth/auth_viewmodel.dart';
import '../widgets/app_shell.dart';
import '../widgets/app_sidebar.dart';
import 'project_detail_screen.dart';
import 'create_project_screen.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});
  @override State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  String _filter = 'All';
  final _filters = ['All', 'Active', 'On Hold', 'Completed', 'Cancelled'];

  List<ProjectEntity> _applyFilter(List<ProjectEntity> all) {
    if (_filter == 'All') return all;
    final statusMap = {
      'Active': 'active', 'On Hold': 'on_hold',
      'Completed': 'completed', 'Cancelled': 'cancelled',
    };
    return all.where((p) => p.status == statusMap[_filter]).toList();
  }

  void _openCreate() {
    Navigator.push(context,
      MaterialPageRoute(builder: (_) => const CreateProjectScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authVm  = context.watch<AuthViewModel>();
    final projVm  = context.watch<ProjectViewModel>();
    final user    = authVm.currentUser;
    final isAdmin = user?.canCreateProject ?? false;

    final stream = isAdmin
        ? projVm.getAllProjects()
        : projVm.getMyProjects(user?.uid ?? '');

    return AppShell(
      activePage: SidebarPage.projects,
      child: StreamBuilder<List<ProjectEntity>>(
        stream: stream,
        builder: (context, snap) {
          final allProjects = snap.data ?? [];
          final projects    = _applyFilter(allProjects);
          final isLoading   = snap.connectionState == ConnectionState.waiting
              && allProjects.isEmpty;

          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Header ────────────────────────────────────────
                Row(children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Projects',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                            color: AppTheme.textColor)),
                    Text(isAdmin
                        ? 'All projects (${allProjects.length})'
                        : 'Projects you\'re assigned to',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                  ]),
                  const Spacer(),
                  if (isAdmin)
                    ElevatedButton.icon(
                      onPressed: _openCreate,
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('New Project'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10)),
                    ),
                ]),
                const SizedBox(height: 16),

                // ── Stats row ─────────────────────────────────────
                if (allProjects.isNotEmpty) ...[
                  _StatsRow(projects: allProjects),
                  const SizedBox(height: 16),
                ],

                // ── Filter chips ──────────────────────────────────
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: _filters.map((f) {
                    final selected = _filter == f;
                    final count = f == 'All' ? allProjects.length
                        : _applyFilter(allProjects).length == projects.length && selected
                        ? projects.length
                        : (() {
                      final sm = {'Active': 'active', 'On Hold': 'on_hold',
                        'Completed': 'completed', 'Cancelled': 'cancelled'};
                      return allProjects.where(
                              (p) => p.status == sm[f]).length;
                    })();
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text('$f ($count)'),
                        selected: selected,
                        onSelected: (_) => setState(() => _filter = f),
                        selectedColor: AppTheme.accent.withOpacity(0.15),
                        checkmarkColor: AppTheme.accent,
                        labelStyle: TextStyle(fontSize: 12,
                            color: selected ? AppTheme.accent : AppTheme.textMuted,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.normal),
                      ),
                    );
                  }).toList()),
                ),
                const SizedBox(height: 16),

                // ── Body ──────────────────────────────────────────
                if (isLoading)
                  const Expanded(child: Center(
                      child: CircularProgressIndicator()))
                else if (allProjects.isEmpty)
                  Expanded(child: _EmptyProjects(
                      isAdmin: isAdmin, onCreate: isAdmin ? _openCreate : null))
                else if (projects.isEmpty)
                    Expanded(child: Center(child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🗂️', style: TextStyle(fontSize: 40)),
                          const SizedBox(height: 12),
                          Text('No $_filter projects',
                              style: const TextStyle(fontSize: 15,
                                  fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
                          const SizedBox(height: 6),
                          TextButton(
                              onPressed: () => setState(() => _filter = 'All'),
                              child: const Text('Show all projects')),
                        ])))
                  else
                    Expanded(child: _ProjectGrid(
                        projects: projects, isAdmin: isAdmin)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Stats row
// ─────────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final List<ProjectEntity> projects;
  const _StatsRow({required this.projects});

  @override
  Widget build(BuildContext context) {
    final active    = projects.where((p) => p.status == 'active').length;
    final completed = projects.where((p) => p.status == 'completed').length;
    final onHold    = projects.where((p) => p.status == 'on_hold').length;
    final totalTasks = projects.fold<int>(0, (s, p) => s + p.taskCount);
    final openTasks  = projects.fold<int>(0, (s, p) => s + p.openTaskCount);

    return Wrap(spacing: 8, runSpacing: 8, children: [
      _StatChip('${projects.length}', 'Total', AppTheme.textDim),
      _StatChip('$active', 'Active', AppTheme.green),
      _StatChip('$completed', 'Done', AppTheme.accent),
      _StatChip('$onHold', 'On Hold', AppTheme.orange),
      _StatChip('$openTasks/$totalTasks', 'Open Tasks', AppTheme.blue),
    ]);
  }
}

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
      Text(value, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(
          fontSize: 12, color: color.withOpacity(0.8))),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────
// Project grid
// ─────────────────────────────────────────────────────────────────────
class _ProjectGrid extends StatelessWidget {
  final List<ProjectEntity> projects;
  final bool isAdmin;
  const _ProjectGrid({required this.projects, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final cols  = width > 1100 ? 3 : width > 700 ? 2 : 1;
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.6,
      ),
      itemCount: projects.length,
      itemBuilder: (_, i) => _ProjectCard(
          project: projects[i], isAdmin: isAdmin),
    );
  }
}

class _ProjectCard extends StatefulWidget {
  final ProjectEntity project;
  final bool isAdmin;
  const _ProjectCard({required this.project, required this.isAdmin});
  @override State<_ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<_ProjectCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final project     = widget.project;
    final statusColor = _statusColor(project.status);
    final progress    = project.progress;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => ProjectDetailScreen(projectId: project.id))),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _hover ? AppTheme.cardAlt : AppTheme.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: _hover
                    ? AppTheme.accent.withOpacity(0.35)
                    : AppTheme.border),
            boxShadow: _hover ? [BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12, offset: const Offset(0, 4))] : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row
              Row(children: [
                _Badge(_statusLabel(project.status), statusColor),
                const Spacer(),
                _PriorityDot(project.priority),
                const SizedBox(width: 5),
                Text(project.priority,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textDim)),
                if (widget.isAdmin) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => CreateProjectScreen(
                              existing: project))),
                      child: const Icon(Icons.edit_outlined,
                          size: 14, color: AppTheme.textDim)),
                ],
              ]),
              const SizedBox(height: 10),

              // Name + client
              Text(project.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15,
                      fontWeight: FontWeight.w700, color: AppTheme.textColor)),
              Text(project.client,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textMuted)),
              const Spacer(),

              // Progress bar
              Row(children: [
                Expanded(child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                        value: progress, minHeight: 5,
                        backgroundColor: AppTheme.border,
                        valueColor: AlwaysStoppedAnimation(statusColor)))),
                const SizedBox(width: 8),
                Text('${(progress * 100).round()}%',
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textDim)),
              ]),
              const SizedBox(height: 8),

              // Footer
              Row(children: [
                Icon(Icons.task_alt_rounded, size: 13,
                    color: AppTheme.textDim),
                const SizedBox(width: 4),
                Text(
                    '${project.taskCount - project.openTaskCount}/${project.taskCount} tasks',
                    style: const TextStyle(
                        fontSize: 11.5, color: AppTheme.textMuted)),
                if (project.overdueTaskCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                          color: AppTheme.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4)),
                      child: Text(
                          '${project.overdueTaskCount} overdue',
                          style: const TextStyle(
                              fontSize: 10, color: AppTheme.red,
                              fontWeight: FontWeight.w600))),
                ],
                const Spacer(),
                if (project.endDate != null) ...[
                  Icon(Icons.calendar_today_outlined,
                      size: 11,
                      color: _dueDateColor(project.endDate!)),
                  const SizedBox(width: 3),
                  Text(DateFormat('dd MMM').format(project.endDate!),
                      style: TextStyle(fontSize: 11,
                          color: _dueDateColor(project.endDate!))),
                ],
              ]),
            ],
          ),
        ),
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
    'completed' => 'Completed',
    _           => 'Cancelled',
  };
  Color _dueDateColor(DateTime d) =>
      d.isBefore(DateTime.now()) ? AppTheme.red : AppTheme.textDim;
}

// ─────────────────────────────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────────────────────────────
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

class _PriorityDot extends StatelessWidget {
  final String priority;
  const _PriorityDot(this.priority);
  Color get color => switch (priority) {
    'Critical' => AppTheme.red,
    'High'     => AppTheme.orange,
    'Medium'   => AppTheme.blue,
    _          => AppTheme.textDim,
  };
  @override
  Widget build(BuildContext context) => Container(
      width: 8, height: 8,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color));
}

class _EmptyProjects extends StatelessWidget {
  final bool isAdmin;
  final VoidCallback? onCreate;
  const _EmptyProjects({required this.isAdmin, this.onCreate});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.folder_open_rounded, size: 56, color: AppTheme.textDim),
      const SizedBox(height: 16),
      const Text('No projects yet',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
              color: AppTheme.textMuted)),
      const SizedBox(height: 6),
      Text(isAdmin
          ? 'Create your first project to get started'
          : 'You haven\'t been added to any projects yet',
          style: const TextStyle(fontSize: 13, color: AppTheme.textDim)),
      if (isAdmin && onCreate != null) ...[
        const SizedBox(height: 20),
        ElevatedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Create Project'),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.white)),
      ],
    ]),
  );
}