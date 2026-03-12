// lib/presentation/projects/project_viewmodel.dart
import 'package:flutter/material.dart';
import '../../domain/entities/project_entity.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/project_repository.dart';
import '../../data/models/project_model.dart';
import '../../data/models/task_model.dart';

class ProjectViewModel extends ChangeNotifier {
  final ProjectRepository _repo;
  ProjectViewModel(this._repo);

  bool _loading = false;
  bool get isLoading => _loading;

  // ── Streams ───────────────────────────────────────────
  Stream<List<ProjectEntity>> getAllProjects()           => _repo.getProjects();
  Stream<List<ProjectEntity>> getMyProjects(String uid) => _repo.getProjectsByMember(uid);
  Future<ProjectEntity>       getProject(String id)     => _repo.getProjectById(id);

  Stream<List<TaskEntity>> getAllTasks()            => _repo.getAllTasks();
  Stream<List<TaskEntity>> getProjectTasks(String projectId) =>
      _repo.getTasksByProject(projectId);
  Stream<List<TaskEntity>> getMyTasks(String uid) =>
      _repo.getTasksByAssignee(uid);

  // ── Projects CRUD ─────────────────────────────────────
  Future<bool> createProject({
    required Map<String, dynamic> data,
    required UserEntity by,
  }) async {
    _loading = true; notifyListeners();
    try {
      final project = ProjectModel(
        id:            '',
        name:          data['name'] ?? '',
        description:   data['description'] ?? '',
        client:        data['client'] ?? '',
        status:        data['status'] ?? 'active',
        priority:      data['priority'] ?? 'Medium',
        createdByUid:  by.uid,
        createdByName: by.displayName,
        createdAt:     DateTime.now(),
        startDate:     data['startDate'] as DateTime?,
        endDate:       data['endDate']   as DateTime?,
        memberUids:    List<String>.from(data['memberUids'] ?? []),
      );
      await _repo.createProject(project);
      return true;
    } catch (e) {
      debugPrint('createProject error: $e');
      return false;
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<bool> updateProject({
    required String id,
    required Map<String, dynamic> data,
    required UserEntity by,
  }) async {
    _loading = true; notifyListeners();
    try {
      final existing = await _repo.getProjectById(id);
      final updated = ProjectModel(
        id:            id,
        name:          data['name']        ?? existing.name,
        description:   data['description'] ?? existing.description,
        client:        data['client']      ?? existing.client,
        status:        data['status']      ?? existing.status,
        priority:      data['priority']    ?? existing.priority,
        createdByUid:  existing.createdByUid,
        createdByName: existing.createdByName,
        createdAt:     existing.createdAt,
        startDate:     data.containsKey('startDate')
            ? data['startDate'] as DateTime?
            : existing.startDate,
        endDate:       data.containsKey('endDate')
            ? data['endDate'] as DateTime?
            : existing.endDate,
        memberUids:    List<String>.from(data['memberUids'] ?? existing.memberUids),
        taskCount:     existing.taskCount,
        openTaskCount: existing.openTaskCount,
        overdueTaskCount: existing.overdueTaskCount,
      );
      await _repo.updateProject(updated);
      return true;
    } catch (e) {
      debugPrint('updateProject error: $e');
      return false;
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<void> deleteProject(String id) => _repo.deleteProject(id);
  Future<void> updateProjectStatus(String id, String status) =>
      _repo.updateProjectStatus(id, status);

  // ── Tasks CRUD ────────────────────────────────────────
  Future<bool> createTask({
    required Map<String, dynamic> data,
    required UserEntity by,
  }) async {
    _loading = true; notifyListeners();
    try {
      final task = TaskModel(
        id:             '',
        projectId:      data['projectId']      ?? '',
        projectName:    data['projectName']    ?? '',
        title:          data['title']          ?? '',
        description:    data['description']    ?? '',
        status:         data['status']         ?? 'todo',
        priority:       data['priority']       ?? 'Medium',
        assignedToUid:  data['assignedToUid']  ?? '',
        assignedToName: data['assignedToName'] ?? '',
        createdByUid:   by.uid,
        createdByName:  by.displayName,
        createdAt:      DateTime.now(),
        startDate:      data['startDate'] as DateTime?,
        dueDate:        data['dueDate']   as DateTime?,
        notes:          data['notes'] as String?,
      );
      await _repo.createTask(task);
      return true;
    } catch (e) {
      debugPrint('createTask error: $e');
      return false;
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<bool> updateTask({
    required String id,
    required Map<String, dynamic> data,
    required UserEntity by,
  }) async {
    _loading = true; notifyListeners();
    try {
      final updated = TaskModel(
        id:             id,
        projectId:      data['projectId']      ?? '',
        projectName:    data['projectName']    ?? '',
        title:          data['title']          ?? '',
        description:    data['description']    ?? '',
        status:         data['status']         ?? 'todo',
        priority:       data['priority']       ?? 'Medium',
        assignedToUid:  data['assignedToUid']  ?? '',
        assignedToName: data['assignedToName'] ?? '',
        createdByUid:   by.uid,
        createdByName:  by.displayName,
        createdAt:      DateTime.now(),
        startDate:      data['startDate'] as DateTime?,
        dueDate:        data['dueDate']   as DateTime?,
        notes:          data['notes'] as String?,
      );
      await _repo.updateTask(updated);
      return true;
    } catch (e) {
      debugPrint('updateTask error: $e');
      return false;
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<void> updateTaskStatus(String id, String status) =>
      _repo.updateTaskStatus(id, status);
  Future<void> deleteTask(String id) => _repo.deleteTask(id);
}