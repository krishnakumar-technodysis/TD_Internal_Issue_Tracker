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

  List<IssueEntity> get allIssues  => _all;
  IssueViewState    get state      => _state;
  String?           get errorMessage => _error;

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

  // Stats
  int get totalIssues    => _all.length;
  int get openIssues     => _all.where((i) => i.isOpen).length;
  int get resolvedIssues => _all.where((i) => i.status == 'Resolved').length;
  int get criticalIssues => _all.where((i) => i.priority == 'Critical' && i.isOpen).length;

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
