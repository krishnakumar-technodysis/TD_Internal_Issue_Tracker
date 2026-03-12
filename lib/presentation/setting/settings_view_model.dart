// lib/presentation/settings/settings_viewmodel.dart
import 'package:flutter/material.dart';
import '../../domain/entities/client_entity.dart';
import '../../domain/entities/technology_entity.dart';
import '../../domain/entities/department_entity.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsViewModel extends ChangeNotifier {
  final SettingsRepository _repo;
  SettingsViewModel(this._repo);

  Stream<List<ClientEntity>>     get clientsStream     => _repo.clientsStream;
  Stream<List<TechnologyEntity>> get technologiesStream => _repo.technologiesStream;
  Stream<List<DepartmentEntity>> get departmentsStream  => _repo.departmentsStream;

  Future<void> addClient(String name, {String? desc})               => _repo.addClient(name, description: desc);
  Future<void> updateClient(String id, String name, {String? desc}) => _repo.updateClient(id, name, description: desc);
  Future<void> toggleClient(String id, bool v)                      => _repo.toggleClient(id, v);
  Future<void> deleteClient(String id)                              => _repo.deleteClient(id);

  Future<void> addTechnology(String name, {String? desc})               => _repo.addTechnology(name, description: desc);
  Future<void> updateTechnology(String id, String name, {String? desc}) => _repo.updateTechnology(id, name, description: desc);
  Future<void> toggleTechnology(String id, bool v)                      => _repo.toggleTechnology(id, v);
  Future<void> deleteTechnology(String id)                              => _repo.deleteTechnology(id);

  Future<void> addDepartment(String name, {String? desc})               => _repo.addDepartment(name, description: desc);
  Future<void> updateDepartment(String id, String name, {String? desc}) => _repo.updateDepartment(id, name, description: desc);
  Future<void> toggleDepartment(String id, bool v)                      => _repo.toggleDepartment(id, v);
  Future<void> deleteDepartment(String id)                              => _repo.deleteDepartment(id);
}