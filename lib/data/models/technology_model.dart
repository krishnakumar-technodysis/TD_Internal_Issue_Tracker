// lib/data/models/technology_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/technology_entity.dart';

class TechnologyModel extends TechnologyEntity {
  const TechnologyModel({
    required super.id, required super.name,
    super.description, super.isActive, required super.createdAt,
  });

  factory TechnologyModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return TechnologyModel(
      id:          doc.id,
      name:        d['name'] ?? '',
      description: d['description'],
      isActive:    d['isActive'] ?? true,
      createdAt:   _parseDate(d['createdAt']) ?? DateTime.now(),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String)    return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  Map<String, dynamic> toMap() => {
    'name':        name,
    'description': description,
    'isActive':    isActive,
    'createdAt':   Timestamp.fromDate(createdAt),
  };
}