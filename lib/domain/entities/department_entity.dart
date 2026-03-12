// lib/domain/entities/department_entity.dart
import 'package:equatable/equatable.dart';

class DepartmentEntity extends Equatable {
  final String id;
  final String name;
  final String? description;
  final bool isActive;
  final DateTime createdAt;

  const DepartmentEntity({
    required this.id, required this.name,
    this.description, this.isActive = true, required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name];
}