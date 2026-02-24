// lib/data/models/issue_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/issue_entity.dart';

class IssueModel extends IssueEntity {
  const IssueModel({
    required super.id,
    required super.issueId,
    required super.customer,
    required super.processName,
    required super.technology,
    required super.priority,
    required super.assignedTo,
    required super.status,
    required super.issueSummary,
    required super.rootCauseCategory,
    super.startDate,
    super.closingDate,
    required super.actionTaken,
    required super.createdByUid,
    required super.createdByName,
    required super.createdAt,
    super.lastUpdatedByUid,
    super.lastUpdatedByName,
    super.lastUpdatedAt,
    super.resolvedByUid,
    super.resolvedByName,
    super.resolvedAt,
    super.closedByUid,
    super.closedByName,
    super.closedAt,
  });

  factory IssueModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return IssueModel(
      id: doc.id,
      issueId: data['issueId'] ?? '',
      customer: data['customer'] ?? '',
      processName: data['processName'] ?? '',
      technology: data['technology'] ?? '',
      priority: data['priority'] ?? 'Low',
      assignedTo: data['assignedTo'] ?? '',
      status: data['status'] ?? 'New',
      issueSummary: data['issueSummary'] ?? '',
      rootCauseCategory: data['rootCauseCategory'] ?? 'Unknown',
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      closingDate: (data['closingDate'] as Timestamp?)?.toDate(),
      actionTaken: data['actionTaken'] ?? '',
      createdByUid: data['createdByUid'] ?? '',
      createdByName: data['createdByName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUpdatedByUid: data['lastUpdatedByUid'],
      lastUpdatedByName: data['lastUpdatedByName'],
      lastUpdatedAt: (data['lastUpdatedAt'] as Timestamp?)?.toDate(),
      resolvedByUid: data['resolvedByUid'],
      resolvedByName: data['resolvedByName'],
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
      closedByUid: data['closedByUid'],
      closedByName: data['closedByName'],
      closedAt: (data['closedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'issueId': issueId,
      'customer': customer,
      'processName': processName,
      'technology': technology,
      'priority': priority,
      'assignedTo': assignedTo,
      'status': status,
      'issueSummary': issueSummary,
      'rootCauseCategory': rootCauseCategory,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'closingDate': closingDate != null ? Timestamp.fromDate(closingDate!) : null,
      'actionTaken': actionTaken,
      'createdByUid': createdByUid,
      'createdByName': createdByName,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdatedByUid': lastUpdatedByUid,
      'lastUpdatedByName': lastUpdatedByName,
      'lastUpdatedAt': lastUpdatedAt != null ? Timestamp.fromDate(lastUpdatedAt!) : null,
      'resolvedByUid': resolvedByUid,
      'resolvedByName': resolvedByName,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'closedByUid': closedByUid,
      'closedByName': closedByName,
      'closedAt': closedAt != null ? Timestamp.fromDate(closedAt!) : null,
    };
  }

  /// Creates a copy with updated audit info based on new status
  IssueModel copyWithUpdate({
    required String updatedByUid,
    required String updatedByName,
    required Map<String, dynamic> changes,
  }) {
    final newStatus = changes['status'] as String? ?? status;
    final now = DateTime.now();

    return IssueModel(
      id: id,
      issueId: issueId,
      customer: changes['customer'] as String? ?? customer,
      processName: changes['processName'] as String? ?? processName,
      technology: changes['technology'] as String? ?? technology,
      priority: changes['priority'] as String? ?? priority,
      assignedTo: changes['assignedTo'] as String? ?? assignedTo,
      status: newStatus,
      issueSummary: changes['issueSummary'] as String? ?? issueSummary,
      rootCauseCategory: changes['rootCauseCategory'] as String? ?? rootCauseCategory,
      startDate: changes.containsKey('startDate') ? changes['startDate'] as DateTime? : startDate,
      closingDate: changes.containsKey('closingDate') ? changes['closingDate'] as DateTime? : closingDate,
      actionTaken: changes['actionTaken'] as String? ?? actionTaken,
      createdByUid: createdByUid,
      createdByName: createdByName,
      createdAt: createdAt,
      lastUpdatedByUid: updatedByUid,
      lastUpdatedByName: updatedByName,
      lastUpdatedAt: now,
      resolvedByUid: newStatus == 'Resolved' ? updatedByUid : resolvedByUid,
      resolvedByName: newStatus == 'Resolved' ? updatedByName : resolvedByName,
      resolvedAt: newStatus == 'Resolved' && resolvedAt == null ? now : resolvedAt,
      closedByUid: newStatus == 'Closed' ? updatedByUid : closedByUid,
      closedByName: newStatus == 'Closed' ? updatedByName : closedByName,
      closedAt: newStatus == 'Closed' && closedAt == null ? now : closedAt,
    );
  }
}
