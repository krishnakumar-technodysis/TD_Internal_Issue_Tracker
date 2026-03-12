// lib/domain/entities/project_entity.dart
import 'package:equatable/equatable.dart';

class ProjectEntity extends Equatable {
  final String id;
  final String name;
  final String description;
  final String client;
  final String status;       // 'active' | 'on_hold' | 'completed' | 'cancelled'
  final String priority;
  final String createdByUid;
  final String createdByName;
  final DateTime createdAt;
  final DateTime? startDate;  // project kick-off date
  final DateTime? endDate;    // project deadline
  final List<String> memberUids;
  final int taskCount;
  final int openTaskCount;
  final int overdueTaskCount;

  const ProjectEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.client,
    required this.status,
    required this.priority,
    required this.createdByUid,
    required this.createdByName,
    required this.createdAt,
    this.startDate,
    this.endDate,
    required this.memberUids,
    this.taskCount = 0,
    this.openTaskCount = 0,
    this.overdueTaskCount = 0,
  });

  bool get isActive    => status == 'active';
  bool get isCompleted => status == 'completed';

  double get progress => taskCount == 0 ? 0
      : ((taskCount - openTaskCount) / taskCount).clamp(0.0, 1.0);

  bool get isOverdue => endDate != null
      && endDate!.isBefore(DateTime.now())
      && !isCompleted
      && status != 'cancelled';

  int get daysRemaining {
    if (endDate == null) return 0;
    return endDate!.difference(DateTime.now()).inDays;
  }

  @override
  List<Object?> get props => [id, name, status];
}