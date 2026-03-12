// lib/domain/entities/task_entity.dart
import 'package:equatable/equatable.dart';

class TaskEntity extends Equatable {
  final String id;
  final String projectId;
  final String projectName;
  final String title;
  final String description;
  final String status;       // 'todo' | 'in_progress' | 'review' | 'done' | 'cancelled'
  final String priority;
  final String assignedToUid;
  final String assignedToName;
  final String createdByUid;
  final String createdByName;
  final DateTime createdAt;
  final DateTime? startDate;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final String? notes;

  const TaskEntity({
    required this.id,
    required this.projectId,
    this.projectName = '',
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.assignedToUid,
    required this.assignedToName,
    required this.createdByUid,
    required this.createdByName,
    required this.createdAt,
    this.startDate,
    this.dueDate,
    this.completedAt,
    this.notes,
  });

  bool get isOpen     => !['done', 'cancelled'].contains(status);
  bool get isDone     => status == 'done';
  bool get isCancelled => status == 'cancelled';

  bool get isOverdue  => dueDate != null
      && dueDate!.isBefore(DateTime.now())
      && isOpen;

  int get daysUntilDue {
    if (dueDate == null) return 9999;
    return dueDate!.difference(DateTime.now()).inDays;
  }

  bool get isDueSoon  => !isOverdue && daysUntilDue <= 3 && isOpen;

  @override
  List<Object?> get props => [id, projectId, status];
}