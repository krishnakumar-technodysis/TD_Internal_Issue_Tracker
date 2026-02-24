// lib/presentation/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../issues/issue_viewmodel.dart';
import '../widgets/app_shell.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<IssueViewModel>();

    return AppShell(
      activePage: SidebarPage.dashboard,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Dashboard',
                style: GoogleFonts.syne(
                  fontSize: 24, fontWeight: FontWeight.w700,
                  color: AppTheme.textColor, letterSpacing: -0.5)),
              const SizedBox(height: 4),
              Text(
                '${DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now())} — Overview of all active issues',
                style: const TextStyle(fontSize: 12.5, color: AppTheme.textMuted)),
            ]),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/create'),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('New Issue'),
            ),
          ]),
          const SizedBox(height: 24),

          // Stats grid
          LayoutBuilder(builder: (ctx, box) {
            final cols = box.maxWidth > 700 ? 4 : 2;
            return GridView.count(
              crossAxisCount: cols,
              crossAxisSpacing: 14, mainAxisSpacing: 14,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: box.maxWidth > 700 ? 1.6 : 1.5,
              children: [
                StatCard(
                  title: 'Total Issues',
                  value: vm.totalIssues.toString(),
                  trend: '12 this month',
                  trendUp: true,
                  accentColor: AppTheme.blue,
                  accentColorEnd: AppTheme.accent,
                  emoji: '📋',
                  onTap: () => Navigator.pushNamed(context, '/issues'),
                ),
                StatCard(
                  title: 'Open',
                  value: vm.openIssues.toString(),
                  trend: '8 new this week',
                  trendUp: false,
                  accentColor: AppTheme.orange,
                  accentColorEnd: AppTheme.yellow,
                  emoji: '🔓',
                ),
                StatCard(
                  title: 'Resolved',
                  value: vm.resolvedIssues.toString(),
                  trend: '76% resolution rate',
                  trendUp: true,
                  accentColor: AppTheme.green,
                  accentColorEnd: AppTheme.accent,
                  emoji: '✅',
                ),
                StatCard(
                  title: 'Critical',
                  value: vm.criticalIssues.toString(),
                  trend: 'Needs attention',
                  trendUp: false,
                  accentColor: AppTheme.red,
                  accentColorEnd: AppTheme.orange,
                  emoji: '🚨',
                ),
              ],
            );
          }),
          const SizedBox(height: 20),

          // Charts row
          LayoutBuilder(builder: (ctx, box) {
            final wide = box.maxWidth > 800;
            return wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3,
                        child: Column(children: [
                          _BarChartCard(vm: vm),
                          const SizedBox(height: 16),
                          _RootCauseCard(vm: vm),
                        ])),
                      const SizedBox(width: 16),
                      SizedBox(width: 290,
                        child: Column(children: [
                          _ClientDonut(vm: vm),
                          const SizedBox(height: 16),
                          _ActivityFeed(vm: vm),
                        ])),
                    ])
                : Column(children: [
                    _BarChartCard(vm: vm),
                    const SizedBox(height: 16),
                    _ClientDonut(vm: vm),
                    const SizedBox(height: 16),
                    _RootCauseCard(vm: vm),
                    const SizedBox(height: 16),
                    _ActivityFeed(vm: vm),
                  ]);
          }),
          const SizedBox(height: 60),
        ]),
      ),
    );
  }
}

// ── Bar Chart ─────────────────────────────────────────────────────────
class _BarChartCard extends StatelessWidget {
  final IssueViewModel vm;
  const _BarChartCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    final data = [4.0, 7.0, 3.0, 9.0, 5.0, 11.0, 6.0, 7.0];
    final labels = ['02','05','08','11','14','17','20','23'];

    return _ChartCard(
      title: 'Issues This Month',
      subtitle: DateFormat('MMM yyyy').format(DateTime.now()),
      child: SizedBox(
        height: 130,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: 14,
            barGroups: data.asMap().entries.map((e) {
              final isLast = e.key == data.length - 1;
              return BarChartGroupData(x: e.key, barRods: [
                BarChartRodData(
                  toY: e.value,
                  color: isLast ? AppTheme.accent
                    : e.key > 4 ? AppTheme.orange : AppTheme.blue,
                  width: 18,
                  borderRadius: BorderRadius.circular(4),
                ),
              ]);
            }).toList(),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true, reservedSize: 22,
                  getTitlesWidget: (v, _) => Text(
                    labels[v.toInt()],
                    style: const TextStyle(
                      fontSize: 10, color: AppTheme.textDim)),
                ),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true,
              getDrawingHorizontalLine: (v) => FlLine(
                color: AppTheme.border, strokeWidth: 1),
              drawVerticalLine: false,
            ),
            borderData: FlBorderData(show: false),
          ),
        ),
      ),
    );
  }
}

// ── Root Cause Card ───────────────────────────────────────────────────
class _RootCauseCard extends StatelessWidget {
  final IssueViewModel vm;
  const _RootCauseCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    final data = vm.issuesByRootCause;
    final total = vm.totalIssues;
    if (data.isEmpty) return const SizedBox.shrink();

    final sorted = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topItems = sorted.take(5).toList();
    final colors = [AppTheme.red, AppTheme.orange, AppTheme.yellow,
                    AppTheme.blue, AppTheme.accent];

    return _ChartCard(
      title: 'Root Cause Breakdown',
      subtitle: 'All time',
      child: Column(
        children: topItems.asMap().entries.map((e) {
          final pct = total == 0 ? 0.0 : e.value.value / total;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              SizedBox(width: 90,
                child: Text(e.value.key,
                  style: const TextStyle(
                    fontSize: 12, color: AppTheme.textMuted))),
              const SizedBox(width: 10),
              Expanded(child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  backgroundColor: AppTheme.inkSoft,
                  color: colors[e.key % colors.length],
                  minHeight: 6,
                ),
              )),
              const SizedBox(width: 10),
              Text('${(pct * 100).round()}%',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11, color: AppTheme.textColor,
                  fontWeight: FontWeight.w500)),
            ]),
          );
        }).toList(),
      ),
    );
  }
}

// ── Client Donut ──────────────────────────────────────────────────────
class _ClientDonut extends StatelessWidget {
  final IssueViewModel vm;
  const _ClientDonut({required this.vm});

  @override
  Widget build(BuildContext context) {
    final data = vm.issuesByCustomer;
    if (data.isEmpty) {
      return _ChartCard(
        title: 'By Client', subtitle: '',
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('No data', style: TextStyle(color: AppTheme.textDim)))));
    }

    final sections = AppConstants.customers
        .where((c) => data.containsKey(c))
        .map((c) => PieChartSectionData(
          value: data[c]!.toDouble(),
          color: AppTheme.clientColor(c),
          radius: 50,
          title: '${data[c]}',
          titleStyle: GoogleFonts.dmSans(
            fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.ink),
        )).toList();

    return _ChartCard(
      title: 'By Client', subtitle: '',
      child: Row(children: [
        SizedBox(height: 160, width: 160,
          child: PieChart(PieChartData(
            sections: sections, sectionsSpace: 2,
            centerSpaceRadius: 30,
          ))),
        const SizedBox(width: 20),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: AppConstants.customers
              .where((c) => data.containsKey(c))
              .map((c) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(children: [
              Container(width: 8, height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.clientColor(c),
                  borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Expanded(child: Text(c,
                style: const TextStyle(
                  fontSize: 12, color: AppTheme.textMuted))),
              Text('${data[c]}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11, fontWeight: FontWeight.w500,
                  color: AppTheme.textColor)),
            ]),
          )).toList(),
        )),
      ]),
    );
  }
}

// ── Activity Feed ─────────────────────────────────────────────────────
class _ActivityFeed extends StatelessWidget {
  final IssueViewModel vm;
  const _ActivityFeed({required this.vm});

  @override
  Widget build(BuildContext context) {
    final recent = vm.allIssues.take(4).toList();
    return _ChartCard(
      title: 'Recent Activity', subtitle: '',
      child: Column(
        children: recent.isEmpty
            ? [const Text('No recent activity',
                style: TextStyle(color: AppTheme.textDim, fontSize: 12))]
            : recent.map((issue) {
                final color = AppTheme.statusColor(issue.status);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 28, height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withOpacity(0.12),
                          border: Border.all(color: color.withOpacity(0.4))),
                        child: Center(child: Text(
                          issue.status == 'Resolved' ? '✓' :
                          issue.status == 'Closed'   ? '🔒' : '+',
                          style: TextStyle(fontSize: 11, color: color)))),
                      const SizedBox(width: 10),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${issue.issueId} — ${issue.status}',
                            style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w500,
                              color: AppTheme.textColor)),
                          const SizedBox(height: 2),
                          Text('${issue.customer} • ${issue.createdByName}',
                            style: const TextStyle(
                              fontSize: 11, color: AppTheme.textMuted)),
                        ],
                      )),
                    ]),
                );
              }).toList(),
      ),
    );
  }
}

// ── Base card ─────────────────────────────────────────────────────────
class _ChartCard extends StatelessWidget {
  final String title, subtitle;
  final Widget child;
  const _ChartCard({required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppTheme.card,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppTheme.border),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(title,
          style: GoogleFonts.syne(
            fontSize: 14, fontWeight: FontWeight.w600,
            color: AppTheme.textColor)),
        const Spacer(),
        if (subtitle.isNotEmpty)
          Text(subtitle,
            style: const TextStyle(
              fontSize: 11.5, color: AppTheme.textMuted)),
      ]),
      const SizedBox(height: 16),
      child,
    ]),
  );
}
