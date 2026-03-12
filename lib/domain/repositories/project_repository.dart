// lib/domain/repositories/project_repository.dart
import '../entities/project_entity.dart';
import '../entities/task_entity.dart';

abstract class ProjectRepository {
  // ── Projects ──────────────────────────────────────────
  Stream<List<ProjectEntity>> getProjects();
  Stream<List<ProjectEntity>> getProjectsByMember(String uid);
  Future<ProjectEntity> getProjectById(String id);
  Future<String> createProject(ProjectEntity project);
  Future<void> updateProject(ProjectEntity project);
  Future<void> deleteProject(String id);
  Future<void> updateProjectStatus(String id, String status);

  // ── Tasks ─────────────────────────────────────────────
  Stream<List<TaskEntity>> getAllTasks();
  Stream<List<TaskEntity>> getTasksByProject(String projectId);
  Stream<List<TaskEntity>> getTasksByAssignee(String uid);
  Future<void> createTask(TaskEntity task);
  Future<void> updateTask(TaskEntity task);
  Future<void> updateTaskStatus(String id, String status);
  Future<void> deleteTask(String id);
}