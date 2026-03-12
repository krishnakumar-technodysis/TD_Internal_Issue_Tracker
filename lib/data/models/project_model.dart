// lib/data/models/project_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/project_entity.dart';

class ProjectModel extends ProjectEntity {
  const ProjectModel({
    required super.id, required super.name, required super.description,
    required super.client, required super.status, required super.priority,
    required super.createdByUid, required super.createdByName,
    required super.createdAt, super.startDate, super.endDate,
    required super.memberUids, super.taskCount, super.openTaskCount,
    super.overdueTaskCount,
  });

  static DateTime? _d(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is String)    return DateTime.tryParse(v);
    return null;
  }

  factory ProjectModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ProjectModel(
      id:              doc.id,
      name:            d['name']          ?? '',
      description:     d['description']   ?? '',
      client:          d['client']        ?? '',
      status:          d['status']        ?? 'active',
      priority:        d['priority']      ?? 'Medium',
      createdByUid:    d['createdByUid']  ?? '',
      createdByName:   d['createdByName'] ?? '',
      createdAt:       _d(d['createdAt']) ?? DateTime.now(),
      startDate:       _d(d['startDate']),
      endDate:         _d(d['endDate']),
      memberUids:      List<String>.from(d['memberUids'] ?? []),
      taskCount:       d['taskCount']        ?? 0,
      openTaskCount:   d['openTaskCount']    ?? 0,
      overdueTaskCount: d['overdueTaskCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'name':             name,
    'description':      description,
    'client':           client,
    'status':           status,
    'priority':         priority,
    'createdByUid':     createdByUid,
    'createdByName':    createdByName,
    'createdAt':        Timestamp.fromDate(createdAt),
    'startDate':        startDate != null ? Timestamp.fromDate(startDate!) : null,
    'endDate':          endDate   != null ? Timestamp.fromDate(endDate!)   : null,
    'memberUids':       memberUids,
    'taskCount':        taskCount,
    'openTaskCount':    openTaskCount,
    'overdueTaskCount': overdueTaskCount,
  };
}