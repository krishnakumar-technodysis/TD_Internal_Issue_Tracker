// lib/presentation/dashboard/super_admin_dashboard.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/project_entity.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../admin/admin_screen.dart';
import '../auth/auth_viewmodel.dart';
import '../issues/issue_viewmodel.dart';
import '../projects/create_project_screen.dart';
import '../projects/project_screen.dart';
import '../projects/project_detail_screen.dart';
import '../projects/project_view_model.dart';
import '../widgets/app_shell.dart';
import '../widgets/app_sidebar.dart';

class SuperAdminDashboard extends StatelessWidget {
  const SuperAdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm  = context.watch<AuthViewModel>();
    final projVm  = context.watch<ProjectViewModel>();
    final issueVm = context.watch<IssueViewModel>();
    final name    = authVm.currentUser?.displayName ?? 'Admin';

    return AppShell(
      activePage: SidebarPage.superAdminDashboard,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Header with greeting ───────────────────────────────────────
            _Header(name: name),
            const SizedBox(height: 20),

            // ── Pending approvals alert ────────────────────────────────────
            StreamBuilder<List<UserEntity>>(
              stream: authVm.pendingUsersStream,
              builder: (context, snap) {
                final pending = snap.data ?? [];
                if (pending.isEmpty) return const SizedBox.shrink();
                return _PendingAlert(count: pending.length, context: context);
              },
            ),

            // ── All data streams ──────────────────────────────────────────
            StreamBuilder<List<UserEntity>>(
              stream: authVm.allUsersStream,
              builder: (context, userSnap) {
                final users = userSnap.data ?? [];

                return StreamBuilder<List<ProjectEntity>>(
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

                            // ── System stats ──────────────────────────
                            _SystemStats(
                                users: users,
                                projects: projects,
                                tasks: tasks,
                                issueVm: issueVm),
                            const SizedBox(height: 28),

                            // ── Activity chart ─────────────────────────
                            const _SectionHeader(
                                title: 'Issue Activity', icon: '📊'),
                            const SizedBox(height: 12),
                            _ActivityChart(issueVm: issueVm),
                            const SizedBox(height: 28),

                            // ── Quick actions ──────────────────────────
                            const _SectionHeader(
                                title: 'Quick Actions', icon: '⚡'),
                            const SizedBox(height: 12),
                            _QuickActions(),
                            const SizedBox(height: 28),

                            // ── User breakdown ─────────────────────────
                            const _SectionHeader(
                                title: 'User Breakdown', icon: '👥'),
                            const SizedBox(height: 12),
                            _UserBreakdown(users: users),
                            const SizedBox(height: 28),

                            // ── Active projects ────────────────────────
                            _SectionHeader(
                              title: 'Active Projects',
                              icon: '📁',
                              action: TextButton(
                                onPressed: () => Navigator.push(context,
                                    MaterialPageRoute(
                                        builder: (_) => const ProjectsScreen())),
                                child: const Text('View all',
                                    style: TextStyle(color: AppTheme.accent)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (projects.isEmpty)
                              _EmptyBox(
                                icon: '📁',
                                message: 'No projects yet.',
                                action: ElevatedButton.icon(
                                  onPressed: () => Navigator.push(context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                          const CreateProjectScreen())),
                                  icon: const Icon(Icons.add_rounded, size: 16),
                                  label: const Text('Create Project'),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.accent,
                                      foregroundColor: Colors.white),
                                ),
                              )
                            else
                              _ProjectList(
                                  projects: projects
                                      .where((p) => p.isActive)
                                      .take(5)
                                      .toList()),
                            const SizedBox(height: 28),

                            // ── Overdue tasks ──────────────────────────
                            if (tasks.any((t) => t.isOverdue)) ...[
                              const _SectionHeader(
                                  title: 'Overdue Tasks', icon: '🔴'),
                              const SizedBox(height: 12),
                              _OverdueList(
                                  tasks: tasks
                                      .where((t) => t.isOverdue)
                                      .take(5)
                                      .toList()),
                              const SizedBox(height: 24),
                            ],
                          ],
                        );
                      },
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
class _Header extends StatelessWidget {
  final String name;
  const _Header({required this.name});

  @override
  Widget build(BuildContext context) {
    final hour     = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    return Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$greeting, ${name.split(' ').first}',
            style: GoogleFonts.dmSans(
                fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textColor)),
        const SizedBox(height: 4),
        Text(DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
            style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
      ])),
      // Super admin badge
      Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppTheme.accent, AppTheme.blue],
                  begin: Alignment.centerLeft, end: Alignment.centerRight),
              borderRadius: BorderRadius.circular(20)),
          child: const Text('Super Admin',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                  color: Colors.white))),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pending approval alert banner
// ─────────────────────────────────────────────────────────────────────────────
class _PendingAlert extends StatelessWidget {
  final int count;
  final BuildContext context;
  const _PendingAlert({required this.count, required this.context});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.pushNamed(context, '/admin'),
    child: Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppTheme.orangeBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.orange.withOpacity(0.4))),
      child: Row(children: [
        const Icon(Icons.pending_actions_rounded,
            color: AppTheme.orange, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(
            '$count user${count > 1 ? 's' : ''} pending approval — tap to review',
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600,
                color: AppTheme.orange))),
        const Icon(Icons.chevron_right_rounded,
            size: 18, color: AppTheme.orange),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// System stats
// ─────────────────────────────────────────────────────────────────────────────
class _SystemStats extends StatelessWidget {
  final List<UserEntity> users;
  final List<ProjectEntity> projects;
  final List<TaskEntity> tasks;
  final IssueViewModel issueVm;
  const _SystemStats({
    required this.users, required this.projects,
    required this.tasks, required this.issueVm,
  });

  @override
  Widget build(BuildContext context) {
    final totalUsers    = users.length;
    final activeProj    = projects.where((p) => p.isActive).length;
    final openTasks     = tasks.where((t) => t.isOpen).length;
    final openIssues    = issueVm.openIssues;
    final pendingUsers  = users.where((u) => u.isPending).length;

    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth > 900 ? 5 : constraints.maxWidth > 600 ? 3 : 2;
      return GridView.count(
        crossAxisCount: cols,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _StatCard('👥', 'Total Users',    '$totalUsers', AppTheme.accent),
          _StatCard('📁', 'Active Projects', '$activeProj', AppTheme.blue),
          _StatCard('✅', 'Open Tasks',      '$openTasks',  AppTheme.purple),
          _StatCard('🐛', 'Open Issues',     '$openIssues', AppTheme.orange),
          _StatCard('⏳', 'Pending Approvals', '$pendingUsers',
              pendingUsers > 0 ? AppTheme.red : AppTheme.textDim),
        ],
      );
    });
  }
}

class _StatCard extends StatelessWidget {
  final String emoji, label, value;
  final Color color;
  const _StatCard(this.emoji, this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
      ]),
      const Spacer(),
      Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
          overflow: TextOverflow.ellipsis),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// User breakdown (role distribution)
// ─────────────────────────────────────────────────────────────────────────────
class _UserBreakdown extends StatelessWidget {
  final List<UserEntity> users;
  const _UserBreakdown({required this.users});

  @override
  Widget build(BuildContext context) {
    final admins   = users.where((u) => u.isAdmin && !u.isSuperAdmin).length;
    final managers = users.where((u) => u.isManager).length;
    final regular  = users.where((u) => u.isRegularUser).length;
    final pending  = users.where((u) => u.isPending).length;
    final disabled = users.where((u) => u.isDisabled).length;

    return Wrap(spacing: 8, runSpacing: 8, children: [
      _RoleChip('Admins',   '$admins',   AppTheme.accent),
      _RoleChip('Managers', '$managers', AppTheme.blue),
      _RoleChip('Users',    '$regular',  AppTheme.purple),
      if (pending  > 0) _RoleChip('Pending',  '$pending',  AppTheme.orange),
      if (disabled > 0) _RoleChip('Disabled', '$disabled', AppTheme.textDim),
      _RoleChip('Total', '${users.length}', AppTheme.textColor),
    ]);
  }
}

class _RoleChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _RoleChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(value, style: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w700, color: color)),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick actions
// ─────────────────────────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) => Wrap(spacing: 10, runSpacing: 10, children: [
    _ActionBtn(Icons.add_rounded,          'New Project',  AppTheme.accent,
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CreateProjectScreen()))),
    _ActionBtn(Icons.folder_open_rounded,  'All Projects', AppTheme.blue,
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ProjectsScreen()))),
    _ActionBtn(Icons.people_outline_rounded, 'Admin Panel', AppTheme.purple,
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AdminScreen()))),
    _ActionBtn(Icons.bug_report_outlined,  'All Issues',   AppTheme.orange,
        () => Navigator.pushNamed(context, '/issues')),
    _ActionBtn(Icons.settings_outlined,    'Settings',     AppTheme.textMuted,
        () => Navigator.pushNamed(context, '/settings')),
  ]);
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(this.icon, this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: 16, color: color),
    label: Text(label, style: TextStyle(color: color, fontSize: 13)),
    style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        side: BorderSide(color: color.withOpacity(0.4)),
        backgroundColor: color.withOpacity(0.06)),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Project list
// ─────────────────────────────────────────────────────────────────────────────
class _ProjectList extends StatelessWidget {
  final List<ProjectEntity> projects;
  const _ProjectList({required this.projects});

  @override
  Widget build(BuildContext context) => Column(
    children: projects.map((p) => _ProjectRow(project: p)).toList(),
  );
}

class _ProjectRow extends StatelessWidget {
  final ProjectEntity project;
  const _ProjectRow({required this.project});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.push(context,
        MaterialPageRoute(
            builder: (_) => ProjectDetailScreen(projectId: project.id))),
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
          const SizedBox(height: 2),
          Text(project.client,
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        ])),
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
// Overdue list
// ─────────────────────────────────────────────────────────────────────────────
class _OverdueList extends StatelessWidget {
  final List<TaskEntity> tasks;
  const _OverdueList({required this.tasks});

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
          Text(t.title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: AppTheme.textColor),
              overflow: TextOverflow.ellipsis),
          Row(children: [
            if (t.dueDate != null)
              Text('Due ${DateFormat('dd MMM').format(t.dueDate!)}',
                  style: const TextStyle(fontSize: 11.5, color: AppTheme.red)),
            if (t.projectName.isNotEmpty) ...[
              const Text(' · ', style: TextStyle(color: AppTheme.textDim)),
              Text(t.projectName,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textDim)),
            ],
          ]),
        ])),
        const SizedBox(width: 8),
        Text(t.assignedToName,
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
            overflow: TextOverflow.ellipsis),
      ]),
    )).toList(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Activity Bar Chart
// ─────────────────────────────────────────────────────────────────────────────
class _ActivityChart extends StatefulWidget {
  final IssueViewModel issueVm;
  const _ActivityChart({required this.issueVm});
  @override
  State<_ActivityChart> createState() => _ActivityChartState();
}

class _ActivityChartState extends State<_ActivityChart> {
  ChartPeriod _period = ChartPeriod.week;

  static const _tabs = [
    (ChartPeriod.day,   'Day'),
    (ChartPeriod.week,  'Week'),
    (ChartPeriod.month, 'Month'),
    (ChartPeriod.year,  'Year'),
  ];

  @override
  Widget build(BuildContext context) {
    final data  = widget.issueVm.getBarChartData(_period);
    final maxY  = data.isEmpty ? 1.0
        : (data.map((p) => p.value).reduce((a, b) => a > b ? a : b) + 1)
            .clamp(1.0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Period selector tabs
        Row(children: [
          Expanded(child: Text('Issues created per period',
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted))),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
                color: AppTheme.inkSoft,
                borderRadius: BorderRadius.circular(8)),
            child: Row(mainAxisSize: MainAxisSize.min,
              children: _tabs.map((tab) {
                final (period, label) = tab;
                final selected = _period == period;
                return GestureDetector(
                  onTap: () => setState(() => _period = period),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.accent
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6)),
                    child: Text(label,
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: selected
                                ? FontWeight.w700 : FontWeight.w400,
                            color: selected
                                ? Colors.white : AppTheme.textMuted)),
                  ),
                );
              }).toList(),
            ),
          ),
        ]),
        const SizedBox(height: 20),

        // Bar chart
        SizedBox(
          height: 180,
          child: data.isEmpty
              ? const Center(child: Text('No data',
                  style: TextStyle(color: AppTheme.textDim)))
              : BarChart(
            BarChartData(
              maxY: maxY,
              minY: 0,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY > 5 ? (maxY / 5).ceilToDouble() : 1,
                getDrawingHorizontalLine: (_) => FlLine(
                    color: AppTheme.border, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: maxY > 5
                        ? (maxY / 5).ceilToDouble() : 1,
                    getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.textDim)),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (v, _) {
                      final idx = v.toInt();
                      if (idx < 0 || idx >= data.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(data[idx].label,
                            style: const TextStyle(
                                fontSize: 9.5,
                                color: AppTheme.textDim)),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              barGroups: List.generate(data.length, (i) {
                final value = data[i].value;
                return BarChartGroupData(x: i, barRods: [
                  BarChartRodData(
                    toY: value,
                    width: data.length > 12 ? 8 : 14,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4)),
                    color: value == 0
                        ? AppTheme.border
                        : AppTheme.accent,
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: maxY,
                      color: AppTheme.accent.withOpacity(0.05),
                    ),
                  ),
                ]);
              }),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AppTheme.card,
                  tooltipBorder: const BorderSide(color: AppTheme.border),
                  getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                    '${data[group.x].label}\n',
                    const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                    children: [
                      TextSpan(
                          text: '${rod.toY.toInt()} issues',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.accent)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
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
