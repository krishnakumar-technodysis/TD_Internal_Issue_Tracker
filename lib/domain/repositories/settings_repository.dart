// lib/domain/repositories/settings_repository.dart
import '../entities/client_entity.dart';
import '../entities/technology_entity.dart';
import '../entities/department_entity.dart';

abstract class SettingsRepository {
  // ── Clients ───────────────────────────────────────────
  Stream<List<ClientEntity>> get clientsStream;
  Future<void> addClient(String name, {String? description});
  Future<void> updateClient(String id, String name, {String? description});
  Future<void> toggleClient(String id, bool isActive);
  Future<void> deleteClient(String id);

  // ── Technologies ──────────────────────────────────────
  Stream<List<TechnologyEntity>> get technologiesStream;
  Future<void> addTechnology(String name, {String? description});
  Future<void> updateTechnology(String id, String name, {String? description});
  Future<void> toggleTechnology(String id, bool isActive);
  Future<void> deleteTechnology(String id);

  // ── Departments ───────────────────────────────────────
  Stream<List<DepartmentEntity>> get departmentsStream;
  Future<void> addDepartment(String name, {String? description});
  Future<void> updateDepartment(String id, String name, {String? description});
  Future<void> toggleDepartment(String id, bool isActive);
  Future<void> deleteDepartment(String id);
}