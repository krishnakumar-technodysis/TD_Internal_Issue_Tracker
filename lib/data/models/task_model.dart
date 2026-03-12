// lib/data/models/task_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/task_entity.dart';

class TaskModel extends TaskEntity {
  const TaskModel({
    required super.id, required super.projectId, super.projectName,
    required super.title, required super.description,
    required super.status, required super.priority,
    required super.assignedToUid, required super.assignedToName,
    required super.createdByUid, required super.createdByName,
    required super.createdAt, super.startDate, super.dueDate,
    super.completedAt, super.notes,
  });

  static DateTime? _d(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is String)    return DateTime.tryParse(v);
    return null;
  }

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return TaskModel(
      id:             doc.id,
      projectId:      d['projectId']      ?? '',
      projectName:    d['projectName']    ?? '',
      title:          d['title']          ?? '',
      description:    d['description']    ?? '',
      status:         d['status']         ?? 'todo',
      priority:       d['priority']       ?? 'Medium',
      assignedToUid:  d['assignedToUid']  ?? '',
      assignedToName: d['assignedToName'] ?? '',
      createdByUid:   d['createdByUid']   ?? '',
      createdByName:  d['createdByName']  ?? '',
      createdAt:      _d(d['createdAt'])  ?? DateTime.now(),
      startDate:      _d(d['startDate']),
      dueDate:        _d(d['dueDate']),
      completedAt:    _d(d['completedAt']),
      notes:          d['notes'],
    );
  }

  Map<String, dynamic> toMap() => {
    'projectId':      projectId,
    'projectName':    projectName,
    'title':          title,
    'description':    description,
    'status':         status,
    'priority':       priority,
    'assignedToUid':  assignedToUid,
    'assignedToName': assignedToName,
    'createdByUid':   createdByUid,
    'createdByName':  createdByName,
    'createdAt':      Timestamp.fromDate(createdAt),
    'startDate':      startDate   != null ? Timestamp.fromDate(startDate!)   : null,
    'dueDate':        dueDate     != null ? Timestamp.fromDate(dueDate!)     : null,
    'completedAt':    completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    'notes':          notes,
  };
}