// lib/presentation/reports/report_screen.dart
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:excel/excel.dart' hide Border;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/issue_entity.dart';
import '../../domain/entities/project_entity.dart';
import '../../domain/entities/task_entity.dart';
import '../auth/auth_viewmodel.dart';
import '../issues/issue_viewmodel.dart';
import '../projects/project_view_model.dart';
import '../widgets/app_shell.dart';
import '../widgets/app_sidebar.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm  = context.watch<AuthViewModel>();
    final issueVm = context.watch<IssueViewModel>();
    final projVm  = context.watch<ProjectViewModel>();
    final name    = authVm.currentUser?.displayName ?? '';

    return AppShell(
      activePage: SidebarPage.reports,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Header ────────────────────────────────────────────────────
            Row(children: [
              const Icon(Icons.download_rounded,
                  color: AppTheme.accent, size: 22),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Download Reports',
                    style: GoogleFonts.dmSans(
                        fontSize: 20, fontWeight: FontWeight.w700,
                        color: AppTheme.textColor)),
                const Text('Export data as Excel (.xlsx) files',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              ]),
            ]),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppTheme.accentBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppTheme.accent.withOpacity(0.25))),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded,
                    size: 15, color: AppTheme.accent),
                const SizedBox(width: 8),
                Expanded(child: Text(
                    'Reports are generated from live data and '
                    'downloaded directly to your browser.',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.accent))),
              ]),
            ),
            const SizedBox(height: 24),

            // ── Report cards grid ─────────────────────────────────────────
            LayoutBuilder(builder: (context, constraints) {
              final wide = constraints.maxWidth > 700;
              final cards = [
                _ReportCard(
                  icon: Icons.bug_report_outlined,
                  color: AppTheme.orange,
                  title: 'Issues Report',
                  description:
                      'All issues with status, priority, customer, '
                      'assigned engineer, root cause, and dates.',
                  filename: 'issues_report',
                  onDownload: () async => _downloadIssues(issueVm.allIssues),
                ),
                _ReportCard(
                  icon: Icons.folder_open_rounded,
                  color: AppTheme.blue,
                  title: 'Projects Report',
                  description:
                      'All projects with client, status, priority, '
                      'progress, team size, and task counts.',
                  filename: 'projects_report',
                  onDownload: () async {
                    // Build projects list from stream (use already-loaded cache)
                    final projects = <ProjectEntity>[];
                    await for (final p in projVm.getAllProjects().take(1)) {
                      projects.addAll(p);
                    }
                    _downloadProjects(projects);
                  },
                ),
                _ReportCard(
                  icon: Icons.task_alt_rounded,
                  color: AppTheme.purple,
                  title: 'Tasks Report',
                  description:
                      'All tasks with project, status, priority, '
                      'assigned member, due date, and overdue status.',
                  filename: 'tasks_report',
                  onDownload: () async {
                    final tasks = <TaskEntity>[];
                    await for (final t in projVm.getAllTasks().take(1)) {
                      tasks.addAll(t);
                    }
                    _downloadTasks(tasks);
                  },
                ),
                _ReportCard(
                  icon: Icons.person_outline_rounded,
                  color: AppTheme.accent,
                  title: 'Combined Report',
                  description:
                      'Full workbook with Issues, Projects, and Tasks '
                      'on separate sheets.',
                  filename: 'combined_report',
                  onDownload: () async {
                    final projects = <ProjectEntity>[];
                    final tasks    = <TaskEntity>[];
                    await for (final p in projVm.getAllProjects().take(1)) {
                      projects.addAll(p);
                    }
                    await for (final t in projVm.getAllTasks().take(1)) {
                      tasks.addAll(t);
                    }
                    _downloadCombined(
                        issueVm.allIssues, projects, tasks);
                  },
                ),
              ];

              if (wide) {
                return Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: cards[0]),
                        const SizedBox(width: 16),
                        Expanded(child: cards[1]),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: cards[2]),
                        const SizedBox(width: 16),
                        Expanded(child: cards[3]),
                      ],
                    ),
                  ],
                );
              }

              return Column(
                children: cards.expand((c) => [c, const SizedBox(height: 14)]).toList(),
              );
            }),
            const SizedBox(height: 32),

            // ── Summary stats ─────────────────────────────────────────────
            Text('Data Summary',
                style: GoogleFonts.dmSans(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: AppTheme.textColor)),
            const SizedBox(height: 12),
            _SummaryRow(
              items: [
                _SummaryItem('Total Issues', '${issueVm.allIssues.length}',
                    AppTheme.orange),
                _SummaryItem('Open Issues', '${issueVm.openIssues}',
                    AppTheme.red),
                _SummaryItem('Resolved', '${issueVm.resolvedIssues}',
                    AppTheme.green),
                _SummaryItem('In Progress',
                    '${issueVm.inProgressIssues}', AppTheme.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Excel generators ──────────────────────────────────────────────────────

  static void _downloadIssues(List<IssueEntity> issues) {
    final excel = Excel.createExcel();
    final sheet = excel['Issues'];
    excel.delete('Sheet1');

    // Header row
    _addHeaderRow(sheet, [
      'Issue ID', 'Customer', 'Process Name', 'Technology',
      'Priority', 'Status', 'Assigned To', 'Issue Summary',
      'Root Cause Category', 'Action Taken',
      'Start Date', 'Closing Date',
      'Created By', 'Created At',
      'Resolved By', 'Resolved At',
    ]);

    final fmt = DateFormat('dd MMM yyyy');
    for (final i in issues) {
      sheet.appendRow([
        TextCellValue(i.issueId),
        TextCellValue(i.customer),
        TextCellValue(i.processName),
        TextCellValue(i.technology),
        TextCellValue(i.priority),
        TextCellValue(i.status),
        TextCellValue(i.assignedTo),
        TextCellValue(i.issueSummary),
        TextCellValue(i.rootCauseCategory),
        TextCellValue(i.actionTaken),
        TextCellValue(i.startDate != null ? fmt.format(i.startDate!) : ''),
        TextCellValue(i.closingDate != null ? fmt.format(i.closingDate!) : ''),
        TextCellValue(i.createdByName),
        TextCellValue(fmt.format(i.createdAt)),
        TextCellValue(i.resolvedByName ?? ''),
        TextCellValue(i.resolvedAt != null ? fmt.format(i.resolvedAt!) : ''),
      ]);
    }
    _triggerDownload(excel, 'issues_report');
  }

  static void _downloadProjects(List<ProjectEntity> projects) {
    final excel = Excel.createExcel();
    final sheet = excel['Projects'];
    excel.delete('Sheet1');

    _addHeaderRow(sheet, [
      'Project Name', 'Client', 'Priority', 'Status',
      'Progress %', 'Total Tasks', 'Open Tasks', 'Done Tasks',
      'Members', 'Created By', 'Created At',
      'Start Date', 'End Date',
    ]);

    final fmt = DateFormat('dd MMM yyyy');
    for (final p in projects) {
      sheet.appendRow([
        TextCellValue(p.name),
        TextCellValue(p.client),
        TextCellValue(p.priority),
        TextCellValue(p.status),
        IntCellValue((p.progress * 100).round()),
        IntCellValue(p.taskCount),
        IntCellValue(p.openTaskCount),
        IntCellValue(p.taskCount - p.openTaskCount),
        IntCellValue(p.memberUids.length),
        TextCellValue(p.createdByName),
        TextCellValue(fmt.format(p.createdAt)),
        TextCellValue(p.startDate != null ? fmt.format(p.startDate!) : ''),
        TextCellValue(p.endDate != null ? fmt.format(p.endDate!) : ''),
      ]);
    }
    _triggerDownload(excel, 'projects_report');
  }

  static void _downloadTasks(List<TaskEntity> tasks) {
    final excel = Excel.createExcel();
    final sheet = excel['Tasks'];
    excel.delete('Sheet1');

    _addHeaderRow(sheet, [
      'Task Title', 'Project', 'Status', 'Priority',
      'Assigned To', 'Start Date', 'Due Date', 'Overdue',
      'Description',
    ]);

    final fmt = DateFormat('dd MMM yyyy');
    for (final t in tasks) {
      sheet.appendRow([
        TextCellValue(t.title),
        TextCellValue(t.projectName),
        TextCellValue(t.status),
        TextCellValue(t.priority),
        TextCellValue(t.assignedToName),
        TextCellValue(t.startDate != null ? fmt.format(t.startDate!) : ''),
        TextCellValue(t.dueDate != null ? fmt.format(t.dueDate!) : ''),
        TextCellValue(t.isOverdue ? 'Yes' : 'No'),
        TextCellValue(t.description),
      ]);
    }
    _triggerDownload(excel, 'tasks_report');
  }

  static void _downloadCombined(
      List<IssueEntity> issues,
      List<ProjectEntity> projects,
      List<TaskEntity> tasks) {
    final excel = Excel.createExcel();

    // Issues sheet
    final issueSheet = excel['Issues'];
    _addHeaderRow(issueSheet, [
      'Issue ID', 'Customer', 'Process', 'Technology',
      'Priority', 'Status', 'Assigned To', 'Summary',
      'Root Cause', 'Created At',
    ]);
    final fmt = DateFormat('dd MMM yyyy');
    for (final i in issues) {
      issueSheet.appendRow([
        TextCellValue(i.issueId), TextCellValue(i.customer),
        TextCellValue(i.processName), TextCellValue(i.technology),
        TextCellValue(i.priority), TextCellValue(i.status),
        TextCellValue(i.assignedTo), TextCellValue(i.issueSummary),
        TextCellValue(i.rootCauseCategory), TextCellValue(fmt.format(i.createdAt)),
      ]);
    }

    // Projects sheet
    final projSheet = excel['Projects'];
    _addHeaderRow(projSheet, [
      'Project Name', 'Client', 'Priority', 'Status',
      'Progress %', 'Total Tasks', 'Open Tasks',
    ]);
    for (final p in projects) {
      projSheet.appendRow([
        TextCellValue(p.name), TextCellValue(p.client),
        TextCellValue(p.priority), TextCellValue(p.status),
        IntCellValue((p.progress * 100).round()),
        IntCellValue(p.taskCount), IntCellValue(p.openTaskCount),
      ]);
    }

    // Tasks sheet
    final taskSheet = excel['Tasks'];
    _addHeaderRow(taskSheet, [
      'Task Title', 'Project', 'Status', 'Priority',
      'Assigned To', 'Due Date', 'Overdue',
    ]);
    for (final t in tasks) {
      taskSheet.appendRow([
        TextCellValue(t.title), TextCellValue(t.projectName),
        TextCellValue(t.status), TextCellValue(t.priority),
        TextCellValue(t.assignedToName),
        TextCellValue(t.dueDate != null ? fmt.format(t.dueDate!) : ''),
        TextCellValue(t.isOverdue ? 'Yes' : 'No'),
      ]);
    }

    excel.delete('Sheet1');
    excel.setDefaultSheet('Issues');
    _triggerDownload(excel, 'combined_report');
  }

  static void _addHeaderRow(Sheet sheet, List<String> headers) {
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#1A2234'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    );
    final cells = headers
        .map((h) => TextCellValue(h))
        .toList();
    sheet.appendRow(cells);
    // Apply style to header cells
    for (int col = 0; col < headers.length; col++) {
      sheet
          .cell(CellIndex.indexByColumnRow(
              columnIndex: col, rowIndex: 0))
          .cellStyle = headerStyle;
    }
  }

  static void _triggerDownload(Excel excel, String baseName) {
    final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final fileName = '${baseName}_$dateStr.xlsx';
    final bytes = excel.save(fileName: fileName);
    if (bytes == null) return;

    final blob = html.Blob([bytes]);
    final url  = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = fileName;
    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Report Card
// ─────────────────────────────────────────────────────────────────────────────
class _ReportCard extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String title, description, filename;
  final Future<void> Function() onDownload;

  const _ReportCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.filename,
    required this.onDownload,
  });

  @override
  State<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<_ReportCard> {
  bool _loading = false;
  String? _error;
  bool _done = false;

  Future<void> _handle() async {
    setState(() { _loading = true; _error = null; _done = false; });
    try {
      await widget.onDownload();
      if (mounted) setState(() { _done = true; _loading = false; });
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) setState(() => _done = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Download failed. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(widget.icon, color: color, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Text(widget.title,
              style: const TextStyle(fontSize: 15,
                  fontWeight: FontWeight.w700, color: AppTheme.textColor))),
        ]),
        const SizedBox(height: 12),
        Text(widget.description,
            style: const TextStyle(
                fontSize: 12.5, color: AppTheme.textMuted, height: 1.5)),
        const SizedBox(height: 16),

        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: AppTheme.redBg,
                borderRadius: BorderRadius.circular(6)),
            child: Text(_error!,
                style: const TextStyle(fontSize: 12, color: AppTheme.red)),
          ),
          const SizedBox(height: 10),
        ],

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _loading ? null : _handle,
            icon: _loading
                ? const SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Icon(
                    _done
                        ? Icons.check_circle_outline_rounded
                        : Icons.download_rounded,
                    size: 16),
            label: Text(
              _loading ? 'Generating…'
                  : _done ? 'Downloaded!'
                  : 'Download Excel',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
                backgroundColor: _done ? AppTheme.green : color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary row
// ─────────────────────────────────────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final List<_SummaryItem> items;
  const _SummaryRow({required this.items});

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 10, runSpacing: 10,
        children: items.map((item) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
              color: item.color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: item.color.withOpacity(0.2))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(item.value, style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800,
                color: item.color)),
            const SizedBox(width: 8),
            Text(item.label,
                style: TextStyle(fontSize: 12,
                    color: item.color.withOpacity(0.8))),
          ]),
        )).toList());
  }
}

class _SummaryItem {
  final String label, value;
  final Color color;
  const _SummaryItem(this.label, this.value, this.color);
}
