// lib/domain/entities/client_entity.dart
import 'package:equatable/equatable.dart';

class ClientEntity extends Equatable {
  final String id;
  final String name;
  final String? description;
  final bool isActive;
  final DateTime createdAt;

  const ClientEntity({
    required this.id,
    required this.name,
    this.description,
    this.isActive = true,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name];
}