// lib/presentation/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../issues/issue_viewmodel.dart';
import '../widgets/app_button.dart';
import '../widgets/app_shell.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/stat_card.dart';

// ─────────────────────────────────────────────────────────────────────
// Breakpoints
// ─────────────────────────────────────────────────────────────────────
class _BP {
  static const double mobile  = 480;  // < 480  : phone
  static const double tablet  = 700;  // < 700  : narrow tablet / web
  static const double desktop = 1000; // >= 1000: wide desktop
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm    = context.watch<IssueViewModel>();
    final width = MediaQuery.of(context).size.width;
    final isMobile  = width <  _BP.mobile;
    final isTablet  = width >= _BP.mobile  && width < _BP.desktop;
    final isDesktop = width >= _BP.desktop;

    final hPad = isMobile ? 14.0 : 28.0;

    return AppShell(
      activePage: SidebarPage.dashboard,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Header ──────────────────────────────────────────────
            _Header(isMobile: isMobile),
            const SizedBox(height: 20),

            // ── Stat cards ──────────────────────────────────────────
            _StatGrid(vm: vm, isMobile: isMobile),
            const SizedBox(height: 20),

            // ── Charts layout ────────────────────────────────────────
            if (isDesktop)
            // Desktop: bar+rootcause left, donut+activity right
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 3, child: Column(children: [
                  _BarChartCard(vm: vm),
                  const SizedBox(height: 16),
                  _RootCauseCard(vm: vm),
                ])),
                const SizedBox(width: 16),
                SizedBox(width: 300, child: Column(children: [
                  _ClientDonut(vm: vm),
                  const SizedBox(height: 16),
                  _ActivityFeed(vm: vm),
                ])),
              ])
            else if (isTablet)
            // Tablet: bar full width, then donut+activity side-by-side,
            // then root cause full width
              Column(children: [
                _BarChartCard(vm: vm),
                const SizedBox(height: 14),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: _ClientDonut(vm: vm)),
                  const SizedBox(width: 14),
                  Expanded(child: _ActivityFeed(vm: vm)),
                ]),
                const SizedBox(height: 14),
                _RootCauseCard(vm: vm),
              ])
            else
            // Mobile: all cards stacked, bar chart compact
              Column(children: [
                _BarChartCard(vm: vm, compact: true),
                const SizedBox(height: 12),
                _ClientDonut(vm: vm),
                const SizedBox(height: 12),
                _RootCauseCard(vm: vm),
                const SizedBox(height: 12),
                _ActivityFeed(vm: vm),
              ]),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final bool isMobile;
  const _Header({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dashboard',
              style: GoogleFonts.dmSans(
                  fontSize: isMobile ? 20 : 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textColor,
                  letterSpacing: -0.5)),
          const SizedBox(height: 3),
          Text(
              DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textMuted)),
        ],
      )),
      AppButton(
        label:     isMobile ? '' : 'New Issue',
        icon:      Icons.add,
        height:    isMobile ? 36 : 40,
        width:     isMobile ? 40 : null,
        onPressed: () => Navigator.pushNamed(context, '/create'),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────
// Stat grid — 2×2 on mobile, 4×1 on wider
// ─────────────────────────────────────────────────────────────────────
class _StatGrid extends StatelessWidget {
  final IssueViewModel vm;
  final bool isMobile;
  const _StatGrid({required this.vm, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final cards = [
      StatCard(
        title: 'Total Issues',
        value: vm.totalIssues.toString(),
        trend: vm.totalTrend,
        trendUp: vm.totalIssues > 0,
        accentColor: AppTheme.blue,
        accentColorEnd: AppTheme.accent,
        emoji: '📋',
        onTap: () => Navigator.pushNamed(context, '/issues'),
      ),
      StatCard(
        title: 'Open',
        value: vm.openIssues.toString(),
        trend: vm.openTrend,
        trendUp: false,
        accentColor: AppTheme.orange,
        accentColorEnd: AppTheme.yellow,
        emoji: '🔓',
      ),
      StatCard(
        title: 'Resolved',
        value: vm.resolvedIssues.toString(),
        trend: vm.resolvedTrend,
        trendUp: vm.resolvedIssues > 0,
        accentColor: AppTheme.green,
        accentColorEnd: AppTheme.accent,
        emoji: '✅',
      ),
      StatCard(
        title: 'Critical',
        value: vm.criticalIssues.toString(),
        trend: vm.criticalTrend,
        trendUp: false,
        accentColor: AppTheme.red,
        accentColorEnd: AppTheme.orange,
        emoji: '🚨',
      ),
    ];

    // Wrap lays out cards without ever constraining their height.
    // Each card is given an exact width via SizedBox; height is free.
    return LayoutBuilder(builder: (context, constraints) {
      final cols  = isMobile ? 2 : 4;
      final gap   = isMobile ? 10.0 : 12.0;
      final cardW = (constraints.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(
        spacing:   gap,
        runSpacing: gap,
        children: cards.map((c) =>
            SizedBox(width: cardW, child: c),
        ).toList(),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────
// Bar Chart
// ─────────────────────────────────────────────────────────────────────
class _BarChartCard extends StatefulWidget {
  final IssueViewModel vm;
  final bool compact;   // true = mobile, reduced height
  const _BarChartCard({required this.vm, this.compact = false});

  @override
  State<_BarChartCard> createState() => _BarChartCardState();
}

class _BarChartCardState extends State<_BarChartCard> {
  ChartPeriod _period = ChartPeriod.month;

  String get _subtitle {
    final now = DateTime.now();
    switch (_period) {
      case ChartPeriod.day:   return 'Today · ${DateFormat('dd MMM').format(now)}';
      case ChartPeriod.week:  return 'Last 7 days';
      case ChartPeriod.month: return DateFormat('MMMM yyyy').format(now);
      case ChartPeriod.year:  return now.year.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final points  = widget.vm.getBarChartData(_period);
    final maxVal  = points.isEmpty ? 0.0
        : points.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    final maxY    = maxVal == 0 ? 5.0 : maxVal + (maxVal * 0.3).ceilToDouble();
    final isEmpty = points.every((p) => p.value == 0);
    final chartH  = widget.compact ? 140.0 : 170.0;

    return _ChartCard(
      title:    'Issues Over Time',
      subtitle: _subtitle,
      // On mobile the period tabs go BELOW the title (not trailing)
      // to avoid cramping the header row
      mobileTrailing: widget.compact
          ? _PeriodTabs(
          selected: _period,
          compact:  true,
          onChanged: (p) => setState(() => _period = p))
          : null,
      trailing: widget.compact
          ? null
          : _PeriodTabs(
          selected: _period,
          onChanged: (p) => setState(() => _period = p)),
      child: isEmpty
          ? _emptyState('No issues in this period')
          : SizedBox(
        height: chartH,
        child: BarChart(BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: AppTheme.inkSoft,
              tooltipRoundedRadius: 6,
              getTooltipItem: (group, _, rod, __) {
                final label = points[group.x].label;
                final count = rod.toY.toInt();
                return BarTooltipItem(
                  '$label\n',
                  const TextStyle(
                      color: AppTheme.textMuted, fontSize: 10),
                  children: [TextSpan(
                      text: '$count issue${count != 1 ? 's' : ''}',
                      style: const TextStyle(
                          color: AppTheme.textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12))],
                );
              },
            ),
          ),
          barGroups: points.asMap().entries.map((e) {
            final isMax   = e.value.value == maxVal && maxVal > 0;
            final hasData = e.value.value > 0;
            return BarChartGroupData(x: e.key, barRods: [
              BarChartRodData(
                toY:   e.value.value,
                color: isMax
                    ? AppTheme.accent
                    : hasData
                    ? AppTheme.blue.withOpacity(0.7)
                    : AppTheme.border,
                width: _barWidth(points.length, widget.compact),
                borderRadius: BorderRadius.circular(3),
              ),
            ]);
          }).toList(),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true,
              reservedSize: widget.compact ? 28 : 24,
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= points.length)
                  return const SizedBox.shrink();
                // On mobile show fewer labels to avoid overlap
                final total = points.length;
                final skip  = widget.compact
                    ? (total > 6 ? 2 : 1)
                    : (total > 24 ? 3 : total > 15 ? 2 : 1);
                if (idx % skip != 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    points[idx].label,
                    style: const TextStyle(
                        fontSize: 8.5, color: AppTheme.textDim),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            )),
            leftTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: !widget.compact, // hide on mobile
              reservedSize: 26,
              getTitlesWidget: (v, _) {
                if (v == 0 || v % 1 != 0) return const SizedBox.shrink();
                return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text('${v.toInt()}',
                        style: const TextStyle(
                            fontSize: 9, color: AppTheme.textDim)));
              },
            )),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            getDrawingHorizontalLine: (_) => FlLine(
                color: AppTheme.border, strokeWidth: 1),
            drawVerticalLine: false,
          ),
          borderData: FlBorderData(show: false),
        )),
      ),
    );
  }

  double _barWidth(int count, bool compact) {
    if (compact) {
      if (count <= 7)  return 22;
      if (count <= 12) return 16;
      return 10;
    }
    if (count <= 7)  return 28;
    if (count <= 12) return 20;
    if (count <= 20) return 14;
    return 9;
  }
}

// ─────────────────────────────────────────────────────────────────────
// Period tab selector
// ─────────────────────────────────────────────────────────────────────
class _PeriodTabs extends StatelessWidget {
  final ChartPeriod selected;
  final void Function(ChartPeriod) onChanged;
  final bool compact;
  const _PeriodTabs({
    required this.selected,
    required this.onChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: compact ? 3 : 4,
      runSpacing: 4,
      children: ChartPeriod.values.map((p) {
        final label  = p.name[0].toUpperCase() + p.name.substring(1);
        final active = selected == p;
        return GestureDetector(
          onTap: () => onChanged(p),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 7 : 9,
              vertical:   compact ? 3 : 4,
            ),
            decoration: BoxDecoration(
              color: active
                  ? AppTheme.accent.withOpacity(0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: active ? AppTheme.accent : AppTheme.border),
            ),
            child: Text(label,
                style: TextStyle(
                    fontSize: compact ? 10 : 11,
                    fontWeight: FontWeight.w600,
                    color: active ? AppTheme.accent : AppTheme.textDim)),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Root Cause Breakdown
// ─────────────────────────────────────────────────────────────────────
class _RootCauseCard extends StatelessWidget {
  final IssueViewModel vm;
  const _RootCauseCard({required this.vm});

  static const _colors = [
    AppTheme.red,    AppTheme.orange, AppTheme.yellow,
    AppTheme.blue,   AppTheme.accent, AppTheme.purple,
    AppTheme.green,
  ];

  @override
  Widget build(BuildContext context) {
    final data  = vm.issuesByRootCause;
    final total = vm.totalIssues;

    if (data.isEmpty) {
      return _ChartCard(
          title: 'Root Cause Breakdown', subtitle: 'All time',
          child: _emptyState('No issues recorded yet'));
    }

    final sorted = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _ChartCard(
      title:    'Root Cause Breakdown',
      subtitle: '$total issue${total != 1 ? 's' : ''} total',
      child: Column(
        children: sorted.asMap().entries.map((entry) {
          final idx   = entry.key;
          final label = entry.value.key;
          final count = entry.value.value;
          final pct   = total == 0 ? 0.0 : count / total;
          final color = _colors[idx % _colors.length];

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(width: 8, height: 8,
                      decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(label,
                      style: const TextStyle(
                          fontSize: 12.5, color: AppTheme.textColor,
                          fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis)),
                  Text('$count',
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: AppTheme.textColor)),
                  const SizedBox(width: 8),
                  SizedBox(width: 36, child: Text(
                      '${(pct * 100).round()}%',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 11, color: AppTheme.textMuted))),
                ]),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: AppTheme.border,
                    color: color,
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Client Donut
// ─────────────────────────────────────────────────────────────────────
class _ClientDonut extends StatefulWidget {
  final IssueViewModel vm;
  const _ClientDonut({required this.vm});

  @override
  State<_ClientDonut> createState() => _ClientDonutState();
}

class _ClientDonutState extends State<_ClientDonut> {
  int _touched = -1;

  @override
  Widget build(BuildContext context) {
    final data = widget.vm.issuesByCustomer;

    if (data.isEmpty) {
      return _ChartCard(
          title: 'Issues by Client', subtitle: '',
          child: _emptyState('No client data yet'));
    }

    final clients = AppConstants.customers
        .where((c) => (data[c] ?? 0) > 0)
        .toList()
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
            fontSize: 10, fontWeight: FontWeight.w700,
            color: AppTheme.ink),
      );
    }).toList();

    return _ChartCard(
      title:    'Issues by Client',
      subtitle: '$total total',
      child: Column(children: [
        SizedBox(
            height: 200,
            child: PieChart(PieChartData(
              sections: sections,
              sectionsSpace: 3,
              centerSpaceRadius: 46,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    _touched = (event.isInterestedForInteractions &&
                        response?.touchedSection != null)
                        ? response!.touchedSection!.touchedSectionIndex
                        : -1;
                  });
                },
              ),
            ))),
        const SizedBox(height: 14),
        const Divider(color: AppTheme.border, height: 1),
        const SizedBox(height: 14),

        // Legend
        ...clients.asMap().entries.map((e) {
          final idx    = e.key;
          final client = e.value;
          final count  = data[client] ?? 0;
          final pct    = total == 0 ? 0.0 : count / total;
          final color  = AppTheme.clientColor(client);
          final active = _touched == idx;

          return GestureDetector(
            onTap: () => setState(() => _touched = active ? -1 : idx),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 7),
              decoration: BoxDecoration(
                color: active
                    ? color.withOpacity(0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: active
                        ? color.withOpacity(0.35)
                        : Colors.transparent),
              ),
              child: Row(children: [
                Container(width: 10, height: 10,
                    decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 10),
                Expanded(child: Text(client,
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: active
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: active
                            ? AppTheme.textColor
                            : AppTheme.textMuted),
                    overflow: TextOverflow.ellipsis)),
                // Mini bar
                SizedBox(width: 56,
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                            value: pct,
                            backgroundColor: AppTheme.border,
                            color: color,
                            minHeight: 4))),
                const SizedBox(width: 10),
                SizedBox(width: 22,
                    child: Text('$count',
                        textAlign: TextAlign.right,
                        style: GoogleFonts.jetBrainsMono(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: AppTheme.textColor))),
              ]),
            ),
          );
        }),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Activity Feed
// ─────────────────────────────────────────────────────────────────────
class _ActivityFeed extends StatelessWidget {
  final IssueViewModel vm;
  const _ActivityFeed({required this.vm});

  @override
  Widget build(BuildContext context) {
    final recent = [...vm.allIssues]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final display = recent.take(5).toList();

    return _ChartCard(
      title:    'Recent Activity',
      subtitle: '${vm.totalIssues} total',
      child: display.isEmpty
          ? _emptyState('No activity yet')
          : Column(children: display.map((issue) {
        final color = AppTheme.statusColor(issue.status);
        final icon  = issue.status == 'Resolved'    ? '✓'
            : issue.status == 'Closed'      ? '🔒'
            : issue.priority == 'Critical'  ? '🚨'
            : issue.status == 'In Progress' ? '⚙'
            : '+';
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 30, height: 30,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withOpacity(0.12),
                      border: Border.all(
                          color: color.withOpacity(0.35))),
                  child: Center(child: Text(icon,
                      style: TextStyle(
                          fontSize: 12, color: color)))),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Flexible(child: Text(issue.issueId,
                        style: GoogleFonts.jetBrainsMono(
                            fontSize: 11, color: AppTheme.accent,
                            fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 6),
                    Flexible(child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4)),
                        child: Text(issue.status,
                            style: TextStyle(
                                fontSize: 9.5, color: color,
                                fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis))),
                  ]),
                  const SizedBox(height: 3),
                  Text(issue.issueSummary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textColor)),
                  const SizedBox(height: 2),
                  Text(
                      '${issue.customer} · ${_relTime(issue.createdAt)}',
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textMuted)),
                ],
              )),
            ],
          ),
        );
      }).toList(),
      ),
    );
  }

  String _relTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24) return '${diff.inHours}h ago';
    if (diff.inDays    == 1) return 'Yesterday';
    if (diff.inDays    <  7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM').format(dt);
  }
}

// ─────────────────────────────────────────────────────────────────────
// Shared base card
// ─────────────────────────────────────────────────────────────────────
class _ChartCard extends StatelessWidget {
  final String  title;
  final String  subtitle;
  final Widget  child;
  final Widget? trailing;
  /// If set, this is shown BELOW the title row (used on mobile for period tabs)
  final Widget? mobileTrailing;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
    this.mobileTrailing,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.card,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title + optional trailing
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.dmSans(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: AppTheme.textColor)),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11.5, color: AppTheme.textMuted)),
              ],
            ],
          )),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ]),
        // Period tabs below title on mobile
        if (mobileTrailing != null) ...[
          const SizedBox(height: 10),
          mobileTrailing!,
        ],
        const SizedBox(height: 14),
        child,
      ],
    ),
  );
}

// ── Empty state ───────────────────────────────────────────────────────
Widget _emptyState(String msg) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 24),
  child: Center(child: Column(children: [
    const Text('📭', style: TextStyle(fontSize: 26)),
    const SizedBox(height: 8),
    Text(msg,
        style: const TextStyle(fontSize: 13, color: AppTheme.textDim),
        textAlign: TextAlign.center),
  ])),
);