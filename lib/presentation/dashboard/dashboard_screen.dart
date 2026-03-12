// lib/presentation/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/project_entity.dart';
import '../issues/issue_viewmodel.dart';
import '../projects/project_view_model.dart';
import '../widgets/app_button.dart';
import '../widgets/app_shell.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/stat_card.dart';

// ─────────────────────────────────────────────────────────────────────
// Dashboard Mode — scalable enum, add new modes here freely
// ─────────────────────────────────────────────────────────────────────
enum DashboardMode {
  issues   ('Issues',   '🐛'),
  projects ('Projects', '📁'),
  tasks    ('Tasks',    '✅');

  final String label;
  final String icon;
  const DashboardMode(this.label, this.icon);
}

class _BP {
  static const double mobile  = 480;
  static const double desktop = 1000;
}

// ─────────────────────────────────────────────────────────────────────
// Dashboard Screen — top-level stateful to hold mode
// ─────────────────────────────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardMode _mode = DashboardMode.issues;

  @override
  Widget build(BuildContext context) {
    final issueVm   = context.watch<IssueViewModel>();
    final projectVm = context.watch<ProjectViewModel>();
    final width     = MediaQuery.of(context).size.width;
    final isMobile  = width < _BP.mobile;
    final isDesktop = width >= _BP.desktop;
    final hPad      = isMobile ? 14.0 : 28.0;

    return AppShell(
      activePage: SidebarPage.dashboard,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 60),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Header + mode switcher ──────────────────────────────
          _Header(isMobile: isMobile, mode: _mode,
              onModeChanged: (m) => setState(() => _mode = m)),
          const SizedBox(height: 20),

          // ── Mode-aware stat cards ───────────────────────────────
          _StatSection(mode: _mode, issueVm: issueVm,
              projectVm: projectVm, isMobile: isMobile),
          const SizedBox(height: 20),

          // ── Mode-aware charts ───────────────────────────────────
          _ChartsSection(mode: _mode, issueVm: issueVm,
              projectVm: projectVm, isDesktop: isDesktop, isMobile: isMobile),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Header with mode switcher dropdown
// ─────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final bool isMobile;
  final DashboardMode mode;
  final ValueChanged<DashboardMode> onModeChanged;
  const _Header({required this.isMobile, required this.mode,
    required this.onModeChanged});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Dashboard',
            style: GoogleFonts.dmSans(
                fontSize: isMobile ? 20 : 24, fontWeight: FontWeight.w700,
                color: AppTheme.textColor, letterSpacing: -0.5)),
        const SizedBox(height: 3),
        Text(DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
      ])),

      // Mode switcher
      _ModeSwitcher(selected: mode, onChanged: onModeChanged, compact: isMobile),
      const SizedBox(width: 10),

      if (!isMobile)
        AppButton(label: 'New Issue', icon: Icons.add, height: 40,
            onPressed: () => Navigator.pushNamed(context, '/create')),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────
// Mode switcher — segmented buttons
// ─────────────────────────────────────────────────────────────────────
class _ModeSwitcher extends StatelessWidget {
  final DashboardMode selected;
  final ValueChanged<DashboardMode> onChanged;
  final bool compact;
  const _ModeSwitcher({required this.selected, required this.onChanged,
    this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
          color: AppTheme.cardAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border)),
      child: Row(mainAxisSize: MainAxisSize.min, children: DashboardMode.values.map((m) {
        final active = m == selected;
        return GestureDetector(
          onTap: () => onChanged(m),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.symmetric(
                horizontal: compact ? 8 : 12, vertical: 6),
            decoration: BoxDecoration(
                color: active ? AppTheme.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(7)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(m.icon, style: const TextStyle(fontSize: 13)),
              if (!compact) ...[
                const SizedBox(width: 5),
                Text(m.label,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: active ? Colors.white : AppTheme.textMuted)),
              ],
            ]),
          ),
        );
      }).toList()),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Stat cards — switches based on mode
// ─────────────────────────────────────────────────────────────────────
class _StatSection extends StatelessWidget {
  final DashboardMode mode;
  final IssueViewModel issueVm;
  final ProjectViewModel projectVm;
  final bool isMobile;
  const _StatSection({required this.mode, required this.issueVm,
    required this.projectVm, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return switch (mode) {
      DashboardMode.issues   => _IssueStatCards(
          vm: issueVm, isMobile: isMobile),
      DashboardMode.projects => _ProjectStatCards(
          vm: projectVm, isMobile: isMobile),
      DashboardMode.tasks    => _TaskStatCards(
          vm: projectVm, isMobile: isMobile),
    };
  }
}

// ── Issue stat cards (sync) ────────────────────────────────────────
class _IssueStatCards extends StatelessWidget {
  final IssueViewModel vm; final bool isMobile;
  const _IssueStatCards({required this.vm, required this.isMobile});
  @override
  Widget build(BuildContext context) => _CardRow(isMobile: isMobile, cards: [
    StatCard(title: 'Total Issues', value: vm.totalIssues.toString(),
        trend: vm.totalTrend, trendUp: vm.totalIssues > 0,
        accentColor: AppTheme.blue, accentColorEnd: AppTheme.accent, emoji: '📋',
        onTap: () => Navigator.pushNamed(context, '/issues')),
    StatCard(title: 'Open', value: vm.openIssues.toString(),
        trend: vm.openTrend, trendUp: false,
        accentColor: AppTheme.orange, accentColorEnd: AppTheme.yellow, emoji: '🔓'),
    StatCard(title: 'Resolved', value: vm.resolvedIssues.toString(),
        trend: vm.resolvedTrend, trendUp: vm.resolvedIssues > 0,
        accentColor: AppTheme.green, accentColorEnd: AppTheme.accent, emoji: '✅'),
    StatCard(title: 'Critical', value: vm.criticalIssues.toString(),
        trend: vm.criticalTrend, trendUp: false,
        accentColor: AppTheme.red, accentColorEnd: AppTheme.orange, emoji: '🚨'),
  ]);
}

// ── Project stat cards (stream) ────────────────────────────────────
class _ProjectStatCards extends StatelessWidget {
  final ProjectViewModel vm; final bool isMobile;
  const _ProjectStatCards({required this.vm, required this.isMobile});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ProjectEntity>>(
      stream: vm.getAllProjects(),
      builder: (ctx, snap) {
        final all       = snap.data ?? [];
        final active    = all.where((p) => p.isActive).length;
        final completed = all.where((p) => p.isCompleted).length;
        final overdue   = all.where((p) => p.isOverdue).length;
        return _CardRow(isMobile: isMobile, cards: [
          StatCard(title: 'Total Projects', value: all.length.toString(),
              accentColor: AppTheme.blue, accentColorEnd: AppTheme.accent,
              emoji: '📁', onTap: () => Navigator.pushNamed(ctx, '/projects')),
          StatCard(title: 'Active', value: active.toString(),
              accentColor: AppTheme.green, accentColorEnd: AppTheme.accent,
              emoji: '🟢'),
          StatCard(title: 'Overdue', value: overdue.toString(),
              accentColor: AppTheme.red, accentColorEnd: AppTheme.orange,
              emoji: '⚠️'),
          StatCard(title: 'Completed', value: completed.toString(),
              accentColor: AppTheme.accent, accentColorEnd: AppTheme.blue,
              emoji: '🏁'),
        ]);
      },
    );
  }
}

// ── Task stat cards (stream) ───────────────────────────────────────
class _TaskStatCards extends StatelessWidget {
  final ProjectViewModel vm; final bool isMobile;
  const _TaskStatCards({required this.vm, required this.isMobile});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ProjectEntity>>(
      stream: vm.getAllProjects(),
      builder: (_, snap) {
        final projects = snap.data ?? [];
        final total   = projects.fold(0, (s, p) => s + p.taskCount);
        final open    = projects.fold(0, (s, p) => s + p.openTaskCount);
        final overdue = projects.fold(0, (s, p) => s + p.overdueTaskCount);
        final done    = total - open;
        return _CardRow(isMobile: isMobile, cards: [
          StatCard(title: 'Total Tasks', value: total.toString(),
              accentColor: AppTheme.blue, accentColorEnd: AppTheme.accent,
              emoji: '📝'),
          StatCard(title: 'Open', value: open.toString(),
              accentColor: AppTheme.orange, accentColorEnd: AppTheme.yellow,
              emoji: '🔓'),
          StatCard(title: 'Overdue', value: overdue.toString(),
              accentColor: AppTheme.red, accentColorEnd: AppTheme.orange,
              emoji: '⏰'),
          StatCard(title: 'Completed', value: done.toString(),
              accentColor: AppTheme.green, accentColorEnd: AppTheme.accent,
              emoji: '✅'),
        ]);
      },
    );
  }
}

// Helper to lay out 4 stat cards without repeating LayoutBuilder
class _CardRow extends StatelessWidget {
  final List<Widget> cards;
  final bool isMobile;
  const _CardRow({required this.cards, required this.isMobile});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
      builder: (_, constraints) {
        final cols  = isMobile ? 2 : 4;
        final gap   = isMobile ? 10.0 : 12.0;
        final cardW = (constraints.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(spacing: gap, runSpacing: gap,
            children: cards.map((c) => SizedBox(width: cardW, child: c)).toList());
      });
}

// ─────────────────────────────────────────────────────────────────────
// Charts section — switches based on mode
// ─────────────────────────────────────────────────────────────────────
class _ChartsSection extends StatelessWidget {
  final DashboardMode mode;
  final IssueViewModel issueVm;
  final ProjectViewModel projectVm;
  final bool isDesktop, isMobile;
  const _ChartsSection({required this.mode, required this.issueVm,
    required this.projectVm, required this.isDesktop, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return switch (mode) {
      DashboardMode.issues   => _IssueCharts(vm: issueVm,
          isDesktop: isDesktop, isMobile: isMobile),
      DashboardMode.projects => _ProjectCharts(vm: projectVm,
          isDesktop: isDesktop, isMobile: isMobile),
      DashboardMode.tasks    => _TaskCharts(vm: projectVm,
          isDesktop: isDesktop, isMobile: isMobile),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────
// ISSUES charts (original layout)
// ─────────────────────────────────────────────────────────────────────
class _IssueCharts extends StatelessWidget {
  final IssueViewModel vm;
  final bool isDesktop, isMobile;
  const _IssueCharts({required this.vm, required this.isDesktop,
    required this.isMobile});

  @override
  Widget build(BuildContext context) {
    if (isDesktop) return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(flex: 3, child: Column(children: [
        _IssueBarChart(vm: vm),
        const SizedBox(height: 16),
        _RootCauseCard(vm: vm),
      ])),
      const SizedBox(width: 16),
      SizedBox(width: 300, child: Column(children: [
        _ClientDonut(vm: vm),
        const SizedBox(height: 16),
        _IssueActivityFeed(vm: vm),
      ])),
    ]);

    return Column(children: [
      _IssueBarChart(vm: vm, compact: isMobile),
      const SizedBox(height: 14),
      if (!isMobile)
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _ClientDonut(vm: vm)),
          const SizedBox(width: 14),
          Expanded(child: _IssueActivityFeed(vm: vm)),
        ])
      else ...[
        _ClientDonut(vm: vm),
        const SizedBox(height: 12),
        _IssueActivityFeed(vm: vm),
      ],
      const SizedBox(height: 14),
      _RootCauseCard(vm: vm),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────
// PROJECTS charts
// ─────────────────────────────────────────────────────────────────────
class _ProjectCharts extends StatelessWidget {
  final ProjectViewModel vm;
  final bool isDesktop, isMobile;
  const _ProjectCharts({required this.vm, required this.isDesktop,
    required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ProjectEntity>>(
      stream: vm.getAllProjects(),
      builder: (_, snap) {
        final projects = snap.data ?? [];

        if (isDesktop) return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: Column(children: [
              _ProjectStatusChart(projects: projects),
              const SizedBox(height: 16),
              _ProjectPriorityBreakdown(projects: projects),
            ])),
            const SizedBox(width: 16),
            SizedBox(width: 300, child: Column(children: [
              _ProjectClientDonut(projects: projects),
              const SizedBox(height: 16),
              _ProjectTimeline(projects: projects),
            ])),
          ],
        );

        return Column(children: [
          _ProjectStatusChart(projects: projects),
          const SizedBox(height: 14),
          _ProjectClientDonut(projects: projects),
          const SizedBox(height: 14),
          _ProjectPriorityBreakdown(projects: projects),
          const SizedBox(height: 14),
          _ProjectTimeline(projects: projects),
        ]);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// TASKS charts
// ─────────────────────────────────────────────────────────────────────
class _TaskCharts extends StatelessWidget {
  final ProjectViewModel vm;
  final bool isDesktop, isMobile;
  const _TaskCharts({required this.vm, required this.isDesktop,
    required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ProjectEntity>>(
      stream: vm.getAllProjects(),
      builder: (_, snap) {
        final projects = snap.data ?? [];

        if (isDesktop) return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: Column(children: [
              _TaskStatusBreakdown(projects: projects),
              const SizedBox(height: 16),
              _TasksByProjectChart(projects: projects),
            ])),
            const SizedBox(width: 16),
            SizedBox(width: 300, child: Column(children: [
              _OverdueSummary(projects: projects),
              const SizedBox(height: 16),
              _TaskPriorityNote(projects: projects),
            ])),
          ],
        );

        return Column(children: [
          _TaskStatusBreakdown(projects: projects),
          const SizedBox(height: 14),
          _TasksByProjectChart(projects: projects),
          const SizedBox(height: 14),
          _OverdueSummary(projects: projects),
        ]);
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// ISSUE CHARTS WIDGETS
// ═════════════════════════════════════════════════════════════════════

class _IssueBarChart extends StatefulWidget {
  final IssueViewModel vm;
  final bool compact;
  const _IssueBarChart({required this.vm, this.compact = false});
  @override State<_IssueBarChart> createState() => _IssueBarChartState();
}
class _IssueBarChartState extends State<_IssueBarChart> {
  ChartPeriod _period = ChartPeriod.month;

  String get _subtitle {
    final now = DateTime.now();
    return switch (_period) {
      ChartPeriod.day   => 'Today · ${DateFormat('dd MMM').format(now)}',
      ChartPeriod.week  => 'Last 7 days',
      ChartPeriod.month => DateFormat('MMMM yyyy').format(now),
      ChartPeriod.year  => now.year.toString(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final points = widget.vm.getBarChartData(_period);
    final maxVal = points.isEmpty ? 0.0
        : points.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    final maxY   = maxVal == 0 ? 5.0 : maxVal + (maxVal * 0.3).ceilToDouble();
    final isEmpty = points.every((p) => p.value == 0);

    return _ChartCard(
      title: 'Issues Over Time', subtitle: _subtitle,
      trailing: _PeriodTabs(selected: _period,
          onChanged: (p) => setState(() => _period = p)),
      child: isEmpty
          ? _emptyState('No issues in this period')
          : SizedBox(height: widget.compact ? 140 : 170,
          child: BarChart(_buildBarData(points, maxY))),
    );
  }

  BarChartData _buildBarData(List<dynamic> points, double maxY) =>
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: AppTheme.inkSoft,
            tooltipRoundedRadius: 6,
            getTooltipItem: (group, _, rod, __) {
              final label = points[group.x].label;
              final count = rod.toY.toInt();
              return BarTooltipItem('$label\n',
                  const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                  children: [TextSpan(
                      text: '$count issue${count != 1 ? 's' : ''}',
                      style: const TextStyle(color: AppTheme.textColor,
                          fontWeight: FontWeight.w600, fontSize: 12))]);
            },
          ),
        ),
        barGroups: points.asMap().entries.map((e) {
          final isMax   = e.value.value == points.map((p) => p.value).reduce((a,b) => a>b?a:b) && e.value.value > 0;
          final hasData = e.value.value > 0;
          return BarChartGroupData(x: e.key, barRods: [
            BarChartRodData(
                toY: e.value.value,
                color: isMax ? AppTheme.accent
                    : hasData ? AppTheme.blue.withOpacity(0.7) : AppTheme.border,
                width: _barW(points.length),
                borderRadius: BorderRadius.circular(3)),
          ]);
        }).toList(),
        titlesData: _titles(points),
        gridData: FlGridData(show: true,
            getDrawingHorizontalLine: (_) => const FlLine(
                color: AppTheme.border, strokeWidth: 1),
            drawVerticalLine: false),
        borderData: FlBorderData(show: false),
      );

  double _barW(int n) => n <= 7 ? 28 : n <= 12 ? 20 : n <= 20 ? 14 : 9;

  FlTitlesData _titles(List<dynamic> points) => FlTitlesData(
    bottomTitles: AxisTitles(sideTitles: SideTitles(
      showTitles: true, reservedSize: 24,
      getTitlesWidget: (v, _) {
        final idx = v.toInt();
        if (idx < 0 || idx >= points.length) return const SizedBox.shrink();
        final total = points.length;
        final skip  = total > 24 ? 3 : total > 15 ? 2 : 1;
        if (idx % skip != 0) return const SizedBox.shrink();
        return Padding(padding: const EdgeInsets.only(top: 5),
            child: Text(points[idx].label,
                style: const TextStyle(fontSize: 8.5, color: AppTheme.textDim),
                overflow: TextOverflow.ellipsis));
      },
    )),
    leftTitles: AxisTitles(sideTitles: SideTitles(
      showTitles: true, reservedSize: 26,
      getTitlesWidget: (v, _) {
        if (v == 0 || v % 1 != 0) return const SizedBox.shrink();
        return Padding(padding: const EdgeInsets.only(right: 4),
            child: Text('${v.toInt()}',
                style: const TextStyle(fontSize: 9, color: AppTheme.textDim)));
      },
    )),
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
  );
}

class _RootCauseCard extends StatelessWidget {
  final IssueViewModel vm;
  const _RootCauseCard({required this.vm});

  static const _colors = [
    AppTheme.red, AppTheme.orange, AppTheme.yellow,
    AppTheme.blue, AppTheme.accent, AppTheme.purple, AppTheme.green,
  ];

  @override
  Widget build(BuildContext context) {
    final data  = vm.issuesByRootCause;
    final total = vm.totalIssues;
    if (data.isEmpty) return _ChartCard(title: 'Root Cause Breakdown',
        subtitle: 'All time', child: _emptyState('No issues recorded yet'));
    final sorted = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return _ChartCard(
      title: 'Root Cause Breakdown',
      subtitle: '$total issue${total != 1 ? 's' : ''} total',
      child: Column(children: sorted.asMap().entries.map((entry) {
        final color = _colors[entry.key % _colors.length];
        final count = entry.value.value;
        final pct   = total == 0 ? 0.0 : count / total;
        return _BreakdownRow(
            label: entry.value.key, count: count,
            pct: pct, color: color);
      }).toList()),
    );
  }
}

class _ClientDonut extends StatefulWidget {
  final IssueViewModel vm;
  const _ClientDonut({required this.vm});
  @override State<_ClientDonut> createState() => _ClientDonutState();
}
class _ClientDonutState extends State<_ClientDonut> {
  int _touched = -1;
  @override
  Widget build(BuildContext context) {
    final data = widget.vm.issuesByCustomer;
    if (data.isEmpty) return _ChartCard(title: 'Issues by Client', subtitle: '',
        child: _emptyState('No client data yet'));
    final clients = AppConstants.customers
        .where((c) => (data[c] ?? 0) > 0).toList()
      ..sort((a, b) => (data[b] ?? 0).compareTo(data[a] ?? 0));
    final total = clients.fold(0, (s, c) => s + (data[c] ?? 0));
    final sections = clients.asMap().entries.map((e) {
      final isTouched = _touched == e.key;
      final count = data[e.value] ?? 0;
      final pct   = total == 0 ? 0.0 : count / total;
      return PieChartSectionData(
          value: count.toDouble(),
          color: AppTheme.clientColor(e.value),
          radius: isTouched ? 68 : 54,
          title: pct > 0.08 ? '${(pct * 100).round()}%' : '',
          titleStyle: GoogleFonts.dmSans(
              fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.ink));
    }).toList();
    return _ChartCard(
      title: 'Issues by Client', subtitle: '$total total',
      child: Column(children: [
        SizedBox(height: 200,
            child: PieChart(PieChartData(
                sections: sections, sectionsSpace: 3, centerSpaceRadius: 46,
                pieTouchData: PieTouchData(touchCallback: (event, response) {
                  setState(() {
                    _touched = (event.isInterestedForInteractions &&
                        response?.touchedSection != null)
                        ? response!.touchedSection!.touchedSectionIndex : -1;
                  });
                })))),
        const SizedBox(height: 14),
        const Divider(color: AppTheme.border, height: 1),
        const SizedBox(height: 14),
        ...clients.asMap().entries.map((e) {
          final count  = data[e.value] ?? 0;
          final pct    = total == 0 ? 0.0 : count / total;
          final color  = AppTheme.clientColor(e.value);
          final active = _touched == e.key;
          return GestureDetector(
            onTap: () => setState(() => _touched = active ? -1 : e.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              decoration: BoxDecoration(
                  color: active ? color.withOpacity(0.08) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: active
                      ? color.withOpacity(0.35) : Colors.transparent)),
              child: Row(children: [
                Container(width: 10, height: 10,
                    decoration: BoxDecoration(color: color,
                        borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 10),
                Expanded(child: Text(e.value,
                    style: TextStyle(fontSize: 12.5,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                        color: active ? AppTheme.textColor : AppTheme.textMuted),
                    overflow: TextOverflow.ellipsis)),
                SizedBox(width: 56,
                    child: ClipRRect(borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(value: pct,
                            backgroundColor: AppTheme.border, color: color,
                            minHeight: 4))),
                const SizedBox(width: 10),
                SizedBox(width: 22,
                    child: Text('$count', textAlign: TextAlign.right,
                        style: GoogleFonts.jetBrainsMono(fontSize: 12,
                            fontWeight: FontWeight.w600, color: AppTheme.textColor))),
              ]),
            ),
          );
        }),
      ]),
    );
  }
}

class _IssueActivityFeed extends StatelessWidget {
  final IssueViewModel vm;
  const _IssueActivityFeed({required this.vm});
  @override
  Widget build(BuildContext context) {
    final recent = [...vm.allIssues]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final display = recent.take(5).toList();
    return _ChartCard(
      title: 'Recent Activity', subtitle: '${vm.totalIssues} total',
      child: display.isEmpty ? _emptyState('No activity yet')
          : Column(children: display.map((issue) {
        final color = AppTheme.statusColor(issue.status);
        return _ActivityRow(
          icon: issue.priority == 'Critical' ? '🚨'
              : issue.status == 'Resolved' ? '✓' : '+',
          color: color,
          title: '${issue.issueId} · ${issue.issueSummary}',
          subtitle: '${issue.customer} · ${_relTime(issue.createdAt)}',
          badge: issue.status,
        );
      }).toList()),
    );
  }
  String _relTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24) return '${diff.inHours}h ago';
    if (diff.inDays    == 1) return 'Yesterday';
    return DateFormat('dd MMM').format(dt);
  }
}

// ═════════════════════════════════════════════════════════════════════
// PROJECT CHARTS WIDGETS
// ═════════════════════════════════════════════════════════════════════

class _ProjectStatusChart extends StatelessWidget {
  final List<ProjectEntity> projects;
  const _ProjectStatusChart({required this.projects});

  @override
  Widget build(BuildContext context) {
    final statuses = AppConstants.projectStatuses;
    final counts   = {for (var s in statuses)
      s: projects.where((p) => p.status == s).length};
    final total = projects.length;

    return _ChartCard(
      title: 'Projects by Status',
      subtitle: '$total project${total != 1 ? 's' : ''} total',
      child: total == 0 ? _emptyState('No projects yet')
          : Column(children: statuses.map((s) {
        final count = counts[s] ?? 0;
        final pct   = total == 0 ? 0.0 : count / total;
        final color = _statusColor(s);
        return _BreakdownRow(
            label: AppConstants.projectStatusLabel(s),
            count: count, pct: pct, color: color);
      }).toList()),
    );
  }

  Color _statusColor(String s) => switch (s) {
    'active'    => AppTheme.green,
    'on_hold'   => AppTheme.orange,
    'completed' => AppTheme.accent,
    _           => AppTheme.red,
  };
}

class _ProjectPriorityBreakdown extends StatelessWidget {
  final List<ProjectEntity> projects;
  const _ProjectPriorityBreakdown({required this.projects});

  @override
  Widget build(BuildContext context) {
    final priorities = AppConstants.priorities;
    final total = projects.length;
    final counts = {for (var p in priorities)
      p: projects.where((proj) => proj.priority == p).length};

    return _ChartCard(
      title: 'Projects by Priority', subtitle: 'All projects',
      child: total == 0 ? _emptyState('No projects yet')
          : Column(children: priorities.map((p) {
        final count = counts[p] ?? 0;
        final pct   = total == 0 ? 0.0 : count / total;
        final color = _priorityColor(p);
        return _BreakdownRow(
            label: p, count: count, pct: pct, color: color);
      }).toList()),
    );
  }

  Color _priorityColor(String p) => switch (p) {
    'Critical' => AppTheme.red,
    'High'     => AppTheme.orange,
    'Medium'   => AppTheme.yellow,
    _          => AppTheme.blue,
  };
}

class _ProjectClientDonut extends StatefulWidget {
  final List<ProjectEntity> projects;
  const _ProjectClientDonut({required this.projects});
  @override State<_ProjectClientDonut> createState() => _ProjectClientDonutState();
}
class _ProjectClientDonutState extends State<_ProjectClientDonut> {
  int _touched = -1;
  @override
  Widget build(BuildContext context) {
    final grouped = <String, int>{};
    for (final p in widget.projects) {
      grouped[p.client] = (grouped[p.client] ?? 0) + 1;
    }
    final clients = grouped.keys.toList()
      ..sort((a, b) => grouped[b]!.compareTo(grouped[a]!));
    final total = widget.projects.length;

    if (clients.isEmpty) return _ChartCard(
        title: 'Projects by Client', subtitle: '',
        child: _emptyState('No projects yet'));

    final sections = clients.asMap().entries.map((e) {
      final isTouched = _touched == e.key;
      final count = grouped[e.value] ?? 0;
      final pct   = total == 0 ? 0.0 : count / total;
      final colors = [AppTheme.accent, AppTheme.blue, AppTheme.orange,
        AppTheme.green, AppTheme.purple, AppTheme.red];
      final color = colors[e.key % colors.length];
      return PieChartSectionData(
          value: count.toDouble(), color: color,
          radius: isTouched ? 68 : 54,
          title: pct > 0.08 ? '${(pct * 100).round()}%' : '',
          titleStyle: GoogleFonts.dmSans(fontSize: 10,
              fontWeight: FontWeight.w700, color: AppTheme.ink));
    }).toList();

    return _ChartCard(
      title: 'Projects by Client', subtitle: '$total total',
      child: Column(children: [
        SizedBox(height: 180,
            child: PieChart(PieChartData(
                sections: sections, sectionsSpace: 3, centerSpaceRadius: 40,
                pieTouchData: PieTouchData(touchCallback: (event, resp) {
                  setState(() {
                    _touched = (event.isInterestedForInteractions &&
                        resp?.touchedSection != null)
                        ? resp!.touchedSection!.touchedSectionIndex : -1;
                  });
                })))),
        const SizedBox(height: 12),
        ...clients.asMap().entries.map((e) {
          final colors = [AppTheme.accent, AppTheme.blue, AppTheme.orange,
            AppTheme.green, AppTheme.purple, AppTheme.red];
          final color = colors[e.key % colors.length];
          final count = grouped[e.value] ?? 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              Container(width: 8, height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(child: Text(e.value,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted))),
              Text('$count', style: GoogleFonts.jetBrainsMono(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: AppTheme.textColor)),
            ]),
          );
        }).toList(),
      ]),
    );
  }
}

class _ProjectTimeline extends StatelessWidget {
  final List<ProjectEntity> projects;
  const _ProjectTimeline({required this.projects});

  @override
  Widget build(BuildContext context) {
    final active = projects.where((p) => p.isActive).toList()
      ..sort((a, b) {
        if (a.endDate == null && b.endDate == null) return 0;
        if (a.endDate == null) return 1;
        if (b.endDate == null) return -1;
        return a.endDate!.compareTo(b.endDate!);
      });
    final fmt = DateFormat('dd MMM');

    return _ChartCard(
      title: 'Upcoming Deadlines',
      subtitle: '${active.length} active project${active.length != 1 ? 's' : ''}',
      child: active.isEmpty ? _emptyState('No active projects')
          : Column(children: active.take(6).map((p) {
        final isOverdue = p.isOverdue;
        final daysLeft  = p.daysRemaining;
        final color = isOverdue ? AppTheme.red
            : daysLeft <= 7 ? AppTheme.orange
            : AppTheme.green;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            Container(width: 8, height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w600,
                    color: AppTheme.textColor),
                    overflow: TextOverflow.ellipsis),
                Text(p.client, style: const TextStyle(
                    fontSize: 11, color: AppTheme.textDim)),
              ],
            )),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(p.endDate != null ? fmt.format(p.endDate!) : '—',
                  style: TextStyle(fontSize: 11.5,
                      fontWeight: FontWeight.w600, color: color)),
              Text(isOverdue ? 'OVERDUE'
                  : daysLeft == 0 ? 'TODAY'
                  : '${daysLeft}d left',
                  style: TextStyle(fontSize: 10, color: color)),
            ]),
          ]),
        );
      }).toList()),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// TASK CHARTS WIDGETS
// ═════════════════════════════════════════════════════════════════════

class _TaskStatusBreakdown extends StatelessWidget {
  final List<ProjectEntity> projects;
  const _TaskStatusBreakdown({required this.projects});

  @override
  Widget build(BuildContext context) {
    final total    = projects.fold(0, (s, p) => s + p.taskCount);
    final open     = projects.fold(0, (s, p) => s + p.openTaskCount);
    final done     = total - open;
    final overdue  = projects.fold(0, (s, p) => s + p.overdueTaskCount);

    final rows = [
      ('Open Tasks',     open,    AppTheme.orange),
      ('Completed',      done,    AppTheme.green),
      ('Overdue',        overdue, AppTheme.red),
    ];

    return _ChartCard(
      title: 'Task Status Overview',
      subtitle: '$total task${total != 1 ? 's' : ''} across all projects',
      child: total == 0 ? _emptyState('No tasks yet')
          : Column(children: rows.map((r) => _BreakdownRow(
          label: r.$1, count: r.$2,
          pct: total == 0 ? 0 : r.$2 / total,
          color: r.$3)).toList()),
    );
  }
}

class _TasksByProjectChart extends StatelessWidget {
  final List<ProjectEntity> projects;
  const _TasksByProjectChart({required this.projects});

  @override
  Widget build(BuildContext context) {
    final sorted = [...projects]
      ..sort((a, b) => b.taskCount.compareTo(a.taskCount));
    final display = sorted.take(8).toList();
    final maxCount = display.isEmpty ? 1
        : display.map((p) => p.taskCount).reduce((a, b) => a > b ? a : b);

    return _ChartCard(
      title: 'Tasks by Project',
      subtitle: 'Top projects by task count',
      child: display.isEmpty ? _emptyState('No tasks yet')
          : Column(children: display.map((p) {
        final pct  = maxCount == 0 ? 0.0 : p.taskCount / maxCount;
        final open = p.openTaskCount;
        final done = p.taskCount - open;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(p.name,
                      style: const TextStyle(fontSize: 12.5,
                          fontWeight: FontWeight.w500, color: AppTheme.textColor),
                      overflow: TextOverflow.ellipsis)),
                  Text('$done/${p.taskCount}',
                      style: GoogleFonts.jetBrainsMono(fontSize: 11,
                          color: AppTheme.textMuted)),
                ]),
                const SizedBox(height: 5),
                // Stacked progress: done (green) + open (blue)
                ClipRRect(borderRadius: BorderRadius.circular(4),
                    child: Stack(children: [
                      LinearProgressIndicator(value: pct,
                          backgroundColor: AppTheme.border,
                          color: AppTheme.blue.withOpacity(0.4),
                          minHeight: 7),
                      if (p.taskCount > 0)
                        LinearProgressIndicator(
                            value: done / p.taskCount,
                            backgroundColor: Colors.transparent,
                            color: AppTheme.accent,
                            minHeight: 7),
                    ])),
                if (p.overdueTaskCount > 0) ...[
                  const SizedBox(height: 3),
                  Text('${p.overdueTaskCount} overdue',
                      style: const TextStyle(fontSize: 10, color: AppTheme.red)),
                ],
              ]),
        );
      }).toList()),
    );
  }
}

class _OverdueSummary extends StatelessWidget {
  final List<ProjectEntity> projects;
  const _OverdueSummary({required this.projects});

  @override
  Widget build(BuildContext context) {
    final overdueProjects = projects
        .where((p) => p.overdueTaskCount > 0)
        .toList()
      ..sort((a, b) => b.overdueTaskCount.compareTo(a.overdueTaskCount));

    return _ChartCard(
      title: 'Overdue by Project',
      subtitle: '${overdueProjects.length} project${overdueProjects.length != 1 ? 's' : ''} with overdue tasks',
      child: overdueProjects.isEmpty
          ? Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(children: [
            const Text('🎉', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Expanded(child: Text('All tasks on track!',
                style: const TextStyle(fontSize: 13,
                    fontWeight: FontWeight.w600, color: AppTheme.green))),
          ]))
          : Column(children: overdueProjects.take(6).map((p) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: AppTheme.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6)),
                child: Text('${p.overdueTaskCount}',
                    style: const TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w700, color: AppTheme.red))),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w600,
                    color: AppTheme.textColor),
                    overflow: TextOverflow.ellipsis),
                Text(p.client, style: const TextStyle(
                    fontSize: 11, color: AppTheme.textDim)),
              ],
            )),
          ]),
        );
      }).toList()),
    );
  }
}

class _TaskPriorityNote extends StatelessWidget {
  final List<ProjectEntity> projects;
  const _TaskPriorityNote({required this.projects});
  @override
  Widget build(BuildContext context) {
    final total   = projects.fold(0, (s, p) => s + p.taskCount);
    final open    = projects.fold(0, (s, p) => s + p.openTaskCount);
    final done    = total - open;
    final pct     = total == 0 ? 0.0 : done / total;
    return _ChartCard(
      title: 'Overall Progress', subtitle: 'Across all projects',
      child: total == 0 ? _emptyState('No tasks yet')
          : Column(children: [
        const SizedBox(height: 8),
        Stack(alignment: Alignment.center, children: [
          SizedBox(width: 120, height: 120,
              child: CircularProgressIndicator(
                  value: pct,
                  strokeWidth: 12,
                  backgroundColor: AppTheme.border,
                  color: AppTheme.accent)),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text('${(pct * 100).round()}%',
                style: const TextStyle(fontSize: 22,
                    fontWeight: FontWeight.w800, color: AppTheme.textColor)),
            const Text('done', style: TextStyle(
                fontSize: 11, color: AppTheme.textMuted)),
          ]),
        ]),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _Chip('$done Done', AppTheme.green),
          const SizedBox(width: 8),
          _Chip('$open Open', AppTheme.orange),
        ]),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text; final Color color;
  const _Chip(this.text, this.color);
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Text(text, style: TextStyle(fontSize: 12,
          fontWeight: FontWeight.w600, color: color)));
}

// ═════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═════════════════════════════════════════════════════════════════════

class _BreakdownRow extends StatelessWidget {
  final String label; final int count; final double pct; final Color color;
  const _BreakdownRow({required this.label, required this.count,
    required this.pct, required this.color});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(label,
            style: const TextStyle(fontSize: 12.5, color: AppTheme.textColor,
                fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis)),
        Text('$count', style: GoogleFonts.jetBrainsMono(
            fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textColor)),
        const SizedBox(width: 8),
        SizedBox(width: 36, child: Text('${(pct * 100).round()}%',
            textAlign: TextAlign.right,
            style: GoogleFonts.jetBrainsMono(fontSize: 11, color: AppTheme.textMuted))),
      ]),
      const SizedBox(height: 6),
      ClipRRect(borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: pct,
              backgroundColor: AppTheme.border, color: color, minHeight: 5)),
    ]),
  );
}

class _ActivityRow extends StatelessWidget {
  final String icon, title, subtitle, badge; final Color color;
  const _ActivityRow({required this.icon, required this.color,
    required this.title, required this.subtitle, required this.badge});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 30, height: 30,
          decoration: BoxDecoration(shape: BoxShape.circle,
              color: color.withOpacity(0.12),
              border: Border.all(color: color.withOpacity(0.35))),
          child: Center(child: Text(icon,
              style: TextStyle(fontSize: 12, color: color)))),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Flexible(child: Text(badge,
              style: TextStyle(fontSize: 9.5, color: color,
                  fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis)),
        ]),
        const SizedBox(height: 2),
        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppTheme.textColor)),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(
            fontSize: 11, color: AppTheme.textMuted)),
      ])),
    ]),
  );
}

class _PeriodTabs extends StatelessWidget {
  final ChartPeriod selected;
  final void Function(ChartPeriod) onChanged;
  const _PeriodTabs({required this.selected, required this.onChanged});
  @override
  Widget build(BuildContext context) => Wrap(spacing: 4, runSpacing: 4,
      children: ChartPeriod.values.map((p) {
        final label  = p.name[0].toUpperCase() + p.name.substring(1);
        final active = selected == p;
        return GestureDetector(
          onTap: () => onChanged(p),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
                color: active ? AppTheme.accent.withOpacity(0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: active ? AppTheme.accent : AppTheme.border)),
            child: Text(label,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: active ? AppTheme.accent : AppTheme.textDim)),
          ),
        );
      }).toList());
}

class _ChartCard extends StatelessWidget {
  final String title, subtitle;
  final Widget child;
  final Widget? trailing;
  const _ChartCard({required this.title, required this.subtitle,
    required this.child, this.trailing});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.dmSans(fontSize: 14,
                  fontWeight: FontWeight.w700, color: AppTheme.textColor)),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(
                    fontSize: 11.5, color: AppTheme.textMuted)),
              ],
            ])),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ]),
      const SizedBox(height: 14),
      child,
    ]),
  );
}

Widget _emptyState(String msg) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 24),
  child: Center(child: Column(children: [
    const Text('📭', style: TextStyle(fontSize: 26)),
    const SizedBox(height: 8),
    Text(msg, style: const TextStyle(fontSize: 13, color: AppTheme.textDim),
        textAlign: TextAlign.center),
  ])),
);