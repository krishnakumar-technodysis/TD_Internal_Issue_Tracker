// lib/domain/entities/technology_entity.dart
import 'package:equatable/equatable.dart';

class TechnologyEntity extends Equatable {
  final String id;
  final String name;
  final String? description;
  final bool isActive;
  final DateTime createdAt;

  const TechnologyEntity({
    required this.id,
    required this.name,
    this.description,
    this.isActive = true,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name];
}