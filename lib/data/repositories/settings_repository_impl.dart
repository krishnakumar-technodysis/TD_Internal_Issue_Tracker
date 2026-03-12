// lib/data/repositories/settings_repository_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/client_entity.dart';
import '../../domain/entities/technology_entity.dart';
import '../../domain/entities/department_entity.dart';
import '../../domain/repositories/settings_repository.dart';
import '../models/client_model.dart';
import '../models/technology_model.dart';
import '../models/department_model.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final FirebaseFirestore _db;
  SettingsRepositoryImpl({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference get _clients  => _db.collection('clients');
  CollectionReference get _techs    => _db.collection('technologies');
  CollectionReference get _depts    => _db.collection('departments');

  // ── Clients ───────────────────────────────────────────
  @override
  Stream<List<ClientEntity>> get clientsStream => _clients.orderBy('name')
      .snapshots().map((s) => s.docs.map(ClientModel.fromFirestore).toList());

  @override Future<void> addClient(String name, {String? description}) =>
      _clients.add({'name': name, 'description': description,
        'isActive': true, 'createdAt': Timestamp.now()});
  @override Future<void> updateClient(String id, String name, {String? description}) =>
      _clients.doc(id).update({'name': name, 'description': description});
  @override Future<void> toggleClient(String id, bool v) =>
      _clients.doc(id).update({'isActive': v});
  @override Future<void> deleteClient(String id) => _clients.doc(id).delete();

  // ── Technologies ──────────────────────────────────────
  @override
  Stream<List<TechnologyEntity>> get technologiesStream => _techs.orderBy('name')
      .snapshots().map((s) => s.docs.map(TechnologyModel.fromFirestore).toList());

  @override Future<void> addTechnology(String name, {String? description}) =>
      _techs.add({'name': name, 'description': description,
        'isActive': true, 'createdAt': Timestamp.now()});
  @override Future<void> updateTechnology(String id, String name, {String? description}) =>
      _techs.doc(id).update({'name': name, 'description': description});
  @override Future<void> toggleTechnology(String id, bool v) =>
      _techs.doc(id).update({'isActive': v});
  @override Future<void> deleteTechnology(String id) => _techs.doc(id).delete();

  // ── Departments ───────────────────────────────────────
  @override
  Stream<List<DepartmentEntity>> get departmentsStream => _depts.orderBy('name')
      .snapshots().map((s) => s.docs.map(DepartmentModel.fromFirestore).toList());

  @override Future<void> addDepartment(String name, {String? description}) =>
      _depts.add({'name': name, 'description': description,
        'isActive': true, 'createdAt': Timestamp.now()});
  @override Future<void> updateDepartment(String id, String name, {String? description}) =>
      _depts.doc(id).update({'name': name, 'description': description});
  @override Future<void> toggleDepartment(String id, bool v) =>
      _depts.doc(id).update({'isActive': v});
  @override Future<void> deleteDepartment(String id) => _depts.doc(id).delete();
}