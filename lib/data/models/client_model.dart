// lib/data/models/client_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/client_entity.dart';

class ClientModel extends ClientEntity {
  const ClientModel({
    required super.id, required super.name,
    super.description, super.isActive, required super.createdAt,
  });

  factory ClientModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ClientModel(
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