// lib/data/models/department_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/department_entity.dart';

class DepartmentModel extends DepartmentEntity {
  const DepartmentModel({
    required super.id, required super.name,
    super.description, super.isActive, required super.createdAt,
  });

  static DateTime _d(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is String)    return DateTime.tryParse(v) ?? DateTime.now();
    return DateTime.now();
  }

  factory DepartmentModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return DepartmentModel(
      id:          doc.id,
      name:        d['name']        ?? '',
      description: d['description'],
      isActive:    d['isActive']    ?? true,
      createdAt:   _d(d['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'name':        name,
    'description': description,
    'isActive':    isActive,
    'createdAt':   Timestamp.fromDate(createdAt),
  };
}