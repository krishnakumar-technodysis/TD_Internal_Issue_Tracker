// lib/presentation/issues/issue_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/issue_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/issue_repository.dart';
import '../../data/models/issue_model.dart';

enum IssueViewState { idle, loading, success, error }

class IssueViewModel extends ChangeNotifier {
  final IssueRepository _repo;
  IssueViewModel(this._repo);

  List<IssueEntity> _all = [];
  IssueViewState _state = IssueViewState.idle;
  String? _error;
  String _search = '';
  String _filterStatus   = '';
  String _filterCustomer = '';
  String _filterPriority = '';

  List<IssueEntity> get allIssues     => _all;
  IssueViewState    get state         => _state;
  String?           get errorMessage  => _error;

  // Public filter state — read by UI to show active filters
  String get filterStatus   => _filterStatus;
  String get filterCustomer => _filterCustomer;
  String get filterPriority => _filterPriority;
  String get searchQuery    => _search;

  // Filtered list
  List<IssueEntity> get issues => _all.where((i) {
    final q = _search.toLowerCase();
    final ms = q.isEmpty || i.issueId.toLowerCase().contains(q)
        || i.issueSummary.toLowerCase().contains(q)
        || i.customer.toLowerCase().contains(q)
        || i.assignedTo.toLowerCase().contains(q);
    final mst = _filterStatus.isEmpty   || i.status   == _filterStatus;
    final mc  = _filterCustomer.isEmpty || i.customer == _filterCustomer;
    final mp  = _filterPriority.isEmpty || i.priority == _filterPriority;
    return ms && mst && mc && mp;
  }).toList();

  // ── Core counts ──────────────────────────────────────────────────────
  int get totalIssues      => _all.length;
  int get openIssues       => _all.where((i) => i.isOpen).length;
  int get inProgressIssues => _all.where((i) => i.status == 'In Progress').length;
  int get resolvedIssues   => _all.where((i) => i.status == 'Resolved').length;
  int get criticalIssues   => _all.where((i) => i.priority == 'Critical' && i.isOpen).length;

  // ── Dynamic trend strings (computed from real Firestore data) ─────────

  /// Issues created in the current calendar month
  String get totalTrend {
    final now   = DateTime.now();
    final count = _all.where((i) =>
    i.createdAt.year  == now.year &&
        i.createdAt.month == now.month).length;
    return count == 0 ? 'None this month' : '$count new this month';
  }

  /// Open issues created in the last 7 days
  String get openTrend {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final count  = _all.where((i) => i.isOpen && i.createdAt.isAfter(cutoff)).length;
    return count == 0 ? 'None this week' : '$count new this week';
  }

  /// Resolved / total as a percentage
  String get resolvedTrend {
    if (_all.isEmpty) return 'No data yet';
    final pct = (resolvedIssues / _all.length * 100).round();
    return '$pct% resolution rate';
  }

  /// Critical open issues created today
  String get criticalTrend {
    final today = DateTime.now();
    final count = _all.where((i) =>
    i.priority == 'Critical' &&
        i.isOpen   &&
        i.createdAt.year  == today.year &&
        i.createdAt.month == today.month &&
        i.createdAt.day   == today.day).length;
    return count == 0 ? 'None escalated today' : '$count escalated today';
  }

  void listenToIssues() {
    _repo.getIssues().listen(
          (list) { _all = list; notifyListeners(); },
      onError: (e) { _error = e.toString(); notifyListeners(); },
    );
  }

  void setSearch(String v)         { _search = v;          notifyListeners(); }
  void setFilterStatus(String v)   { _filterStatus = v;    notifyListeners(); }
  void setFilterCustomer(String v) { _filterCustomer = v;  notifyListeners(); }
  void setFilterPriority(String v) { _filterPriority = v;  notifyListeners(); }
  void clearFilters() {
    _search = ''; _filterStatus = '';
    _filterCustomer = ''; _filterPriority = '';
    notifyListeners();
  }

  // Analytics
  Map<String, int> get issuesByCustomer  => _groupBy((i) => i.customer);
  Map<String, int> get issuesByRootCause => _groupBy((i) => i.rootCauseCategory);
  Map<String, int> get issuesByStatus    => _groupBy((i) => i.status);
  Map<String, int> get issuesByPriority  => _groupBy((i) => i.priority);

  Map<String, int> _groupBy(String Function(IssueEntity) key) {
    final m = <String, int>{};
    for (final i in _all) m[key(i)] = (m[key(i)] ?? 0) + 1;
    return m;
  }

  // ── Bar chart data for Day / Week / Month / Year ─────────────────────

  /// Returns list of {label, count} for the selected period
  List<_ChartPoint> getBarChartData(ChartPeriod period) {
    final now = DateTime.now();
    switch (period) {
      case ChartPeriod.day:
      // Last 24 hours — grouped by hour (every 3h: 00,03,06...21)
        return List.generate(8, (i) {
          final hour  = i * 3;
          final label = '${hour.toString().padLeft(2, '0')}h';
          final count = _all.where((issue) {
            final diff = now.difference(issue.createdAt);
            return diff.inHours >= hour && diff.inHours < hour + 3;
          }).length;
          return _ChartPoint(label, count.toDouble());
        });

      case ChartPeriod.week:
      // Last 7 days — grouped by day name
        return List.generate(7, (i) {
          final day   = now.subtract(Duration(days: 6 - i));
          final label = _dayAbbr(day.weekday);
          final count = _all.where((issue) =>
          issue.createdAt.year  == day.year  &&
              issue.createdAt.month == day.month &&
              issue.createdAt.day   == day.day).length;
          return _ChartPoint(label, count.toDouble());
        });

      case ChartPeriod.month:
      // Current month — group every day into buckets of `step` days
      // so ALL issues are captured, not just issues on the first day
      // of each bucket.
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        final step = daysInMonth <= 15 ? 1 : (daysInMonth / 8).ceil();
        final points = <_ChartPoint>[];
        for (int start = 1; start <= daysInMonth; start += step) {
          final end = (start + step - 1).clamp(1, daysInMonth);
          final label = start == end
              ? start.toString().padLeft(2, '0')
              : '${start.toString().padLeft(2,'0')}–${end.toString().padLeft(2,'0')}';
          final count = _all.where((issue) =>
          issue.createdAt.year  == now.year  &&
              issue.createdAt.month == now.month &&
              issue.createdAt.day   >= start     &&
              issue.createdAt.day   <= end).length;
          points.add(_ChartPoint(label, count.toDouble()));
        }
        return points;

      case ChartPeriod.year:
      // Current year — grouped by month
        return List.generate(12, (i) {
          final month = i + 1;
          final label = _monthAbbr(month);
          final count = _all.where((issue) =>
          issue.createdAt.year  == now.year &&
              issue.createdAt.month == month).length;
          return _ChartPoint(label, count.toDouble());
        });
    }
  }

  static String _dayAbbr(int weekday) =>
      ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][weekday - 1];

  static String _monthAbbr(int month) =>
      ['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'][month - 1];

  Future<bool> createIssue({
    required Map<String, dynamic> data, required UserEntity by,
  }) async {
    _state = IssueViewState.loading; _error = null; notifyListeners();
    try {
      final id      = const Uuid().v4();
      final issueId = await _repo.generateIssueId();
      final issue = IssueModel(
        id: id, issueId: issueId,
        customer: data['customer'] ?? '',
        processName: data['processName'] ?? '',
        technology: data['technology'] ?? '',
        priority: data['priority'] ?? 'Medium',
        assignedTo: data['assignedTo'] ?? '',
        status: 'New',
        issueSummary: data['issueSummary'] ?? '',
        rootCauseCategory: data['rootCauseCategory'] ?? 'Unknown',
        startDate: data['startDate'] as DateTime?,
        closingDate: data['closingDate'] as DateTime?,
        actionTaken: data['actionTaken'] ?? '',
        createdByUid: by.uid, createdByName: by.displayName,
        createdAt: DateTime.now(),
      );
      await _repo.createIssue(issue, by);
      _state = IssueViewState.success; notifyListeners(); return true;
    } catch (e) {
      _state = IssueViewState.error; _error = e.toString(); notifyListeners(); return false;
    }
  }

  Future<bool> updateIssue({
    required IssueEntity existing,
    required Map<String, dynamic> data,
    required UserEntity by,
  }) async {
    _state = IssueViewState.loading; _error = null; notifyListeners();
    try {
      final updated = IssueModel(
        id: existing.id, issueId: existing.issueId,
        customer: data['customer'] ?? existing.customer,
        processName: data['processName'] ?? existing.processName,
        technology: data['technology'] ?? existing.technology,
        priority: data['priority'] ?? existing.priority,
        assignedTo: data['assignedTo'] ?? existing.assignedTo,
        status: data['status'] ?? existing.status,
        issueSummary: data['issueSummary'] ?? existing.issueSummary,
        rootCauseCategory: data['rootCauseCategory'] ?? existing.rootCauseCategory,
        startDate: data.containsKey('startDate')
            ? data['startDate'] as DateTime? : existing.startDate,
        closingDate: data.containsKey('closingDate')
            ? data['closingDate'] as DateTime? : existing.closingDate,
        actionTaken: data['actionTaken'] ?? existing.actionTaken,
        createdByUid: existing.createdByUid, createdByName: existing.createdByName,
        createdAt: existing.createdAt,
      );
      await _repo.updateIssue(updated, by);
      _state = IssueViewState.success; notifyListeners(); return true;
    } catch (e) {
      _state = IssueViewState.error; _error = e.toString(); notifyListeners(); return false;
    }
  }

  Future<bool> deleteIssue(String id) async {
    try { await _repo.deleteIssue(id); return true; }
    catch (e) { _error = e.toString(); notifyListeners(); return false; }
  }
}

// ── Supporting types ──────────────────────────────────────────────────
enum ChartPeriod { day, week, month, year }

class _ChartPoint {
  final String label;
  final double value;
  const _ChartPoint(this.label, this.value);
}