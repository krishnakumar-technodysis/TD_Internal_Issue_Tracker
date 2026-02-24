// lib/domain/entities/issue_entity.dart
import 'package:equatable/equatable.dart';

class IssueEntity extends Equatable {
  final String id;
  final String issueId;       // Auto-generated display ID e.g. ISS-0001
  final String customer;
  final String processName;
  final String technology;
  final String priority;
  final String assignedTo;
  final String status;
  final String issueSummary;
  final String rootCauseCategory;
  final DateTime? startDate;
  final DateTime? closingDate;
  final String actionTaken;

  // Audit fields
  final String createdByUid;
  final String createdByName;
  final DateTime createdAt;

  final String? lastUpdatedByUid;
  final String? lastUpdatedByName;
  final DateTime? lastUpdatedAt;

  final String? resolvedByUid;
  final String? resolvedByName;
  final DateTime? resolvedAt;

  final String? closedByUid;
  final String? closedByName;
  final DateTime? closedAt;

  const IssueEntity({
    required this.id,
    required this.issueId,
    required this.customer,
    required this.processName,
    required this.technology,
    required this.priority,
    required this.assignedTo,
    required this.status,
    required this.issueSummary,
    required this.rootCauseCategory,
    this.startDate,
    this.closingDate,
    required this.actionTaken,
    required this.createdByUid,
    required this.createdByName,
    required this.createdAt,
    this.lastUpdatedByUid,
    this.lastUpdatedByName,
    this.lastUpdatedAt,
    this.resolvedByUid,
    this.resolvedByName,
    this.resolvedAt,
    this.closedByUid,
    this.closedByName,
    this.closedAt,
  });

  bool get isOpen => ['New', 'In Progress', 'Waiting for Client'].contains(status);
  bool get isClosed => ['Resolved', 'Closed'].contains(status);

  @override
  List<Object?> get props => [id, issueId, status];
}
