// lib/data/repositories/project_repository_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/project_entity.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/project_repository.dart';
import '../models/project_model.dart';
import '../models/task_model.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  final FirebaseFirestore _db;
  ProjectRepositoryImpl({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference get _projects => _db.collection('projects');
  CollectionReference get _tasks    => _db.collection('tasks');

  // ── Projects ──────────────────────────────────────────
  @override
  Stream<List<ProjectEntity>> getProjects() => _projects
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(ProjectModel.fromFirestore).toList())
      .handleError((e) => print('getProjects error: $e'));

  @override
  Stream<List<ProjectEntity>> getProjectsByMember(String uid) => _projects
      .where('memberUids', arrayContains: uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(ProjectModel.fromFirestore).toList())
      .handleError((e) => print('getProjectsByMember error: $e'));

  @override
  Future<ProjectEntity> getProjectById(String id) async {
    final doc = await _projects.doc(id).get();
    return ProjectModel.fromFirestore(doc);
  }

  @override
  Future<String> createProject(ProjectEntity p) async {
    final ref = await _projects.add(ProjectModel(
      id:            '',
      name:          p.name,
      description:   p.description,
      client:        p.client,
      status:        p.status,
      priority:      p.priority,
      createdByUid:  p.createdByUid,
      createdByName: p.createdByName,
      createdAt:     p.createdAt,
      startDate:     p.startDate,
      endDate:       p.endDate,
      memberUids:    p.memberUids,
    ).toMap());
    return ref.id;
  }

  @override
  Future<void> updateProject(ProjectEntity p) => _projects.doc(p.id).update(
      ProjectModel(
        id:              p.id,
        name:            p.name,
        description:     p.description,
        client:          p.client,
        status:          p.status,
        priority:        p.priority,
        createdByUid:    p.createdByUid,
        createdByName:   p.createdByName,
        createdAt:       p.createdAt,
        startDate:       p.startDate,
        endDate:         p.endDate,
        memberUids:      p.memberUids,
        taskCount:       p.taskCount,
        openTaskCount:   p.openTaskCount,
        overdueTaskCount: p.overdueTaskCount,
      ).toMap());

  @override
  Future<void> updateProjectStatus(String id, String status) =>
      _projects.doc(id).update({'status': status});

  @override
  Future<void> deleteProject(String id) async {
    final tasks = await _tasks.where('projectId', isEqualTo: id).get();
    final batch = _db.batch();
    for (final doc in tasks.docs) batch.delete(doc.reference);
    batch.delete(_projects.doc(id));
    await batch.commit();
  }

  // ── Tasks ─────────────────────────────────────────────
  @override
  Stream<List<TaskEntity>> getAllTasks() => _tasks
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(TaskModel.fromFirestore).toList())
      .handleError((e) => print('getAllTasks error: $e'));

  @override
  Stream<List<TaskEntity>> getTasksByProject(String projectId) => _tasks
      .where('projectId', isEqualTo: projectId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(TaskModel.fromFirestore).toList())
      .handleError((e) => print('getTasksByProject error: $e'));

  @override
  Stream<List<TaskEntity>> getTasksByAssignee(String uid) => _tasks
      .where('assignedToUid', isEqualTo: uid)
      .where('status', whereNotIn: ['done', 'cancelled'])
      .orderBy('status')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(TaskModel.fromFirestore).toList())
      .handleError((e) => print('getTasksByAssignee error: $e'));

  @override
  Future<void> createTask(TaskEntity t) async {
    await _tasks.add(TaskModel(
      id:             '',
      projectId:      t.projectId,
      projectName:    t.projectName,
      title:          t.title,
      description:    t.description,
      status:         t.status,
      priority:       t.priority,
      assignedToUid:  t.assignedToUid,
      assignedToName: t.assignedToName,
      createdByUid:   t.createdByUid,
      createdByName:  t.createdByName,
      createdAt:      t.createdAt,
      startDate:      t.startDate,
      dueDate:        t.dueDate,
      notes:          t.notes,
    ).toMap());
    await _updateProjectTaskCounts(t.projectId);
  }

  @override
  Future<void> updateTask(TaskEntity t) async {
    await _tasks.doc(t.id).update(TaskModel(
      id:             t.id,
      projectId:      t.projectId,
      projectName:    t.projectName,
      title:          t.title,
      description:    t.description,
      status:         t.status,
      priority:       t.priority,
      assignedToUid:  t.assignedToUid,
      assignedToName: t.assignedToName,
      createdByUid:   t.createdByUid,
      createdByName:  t.createdByName,
      createdAt:      t.createdAt,
      startDate:      t.startDate,
      dueDate:        t.dueDate,
      completedAt:    t.completedAt,
      notes:          t.notes,
    ).toMap());
    await _updateProjectTaskCounts(t.projectId);
  }

  @override
  Future<void> updateTaskStatus(String id, String status) async {
    final doc = await _tasks.doc(id).get();
    final projectId = (doc.data() as Map)['projectId'] as String;
    await _tasks.doc(id).update({
      'status': status,
      if (status == 'done')
        'completedAt': Timestamp.fromDate(DateTime.now()),
    });
    await _updateProjectTaskCounts(projectId);
  }

  @override
  Future<void> deleteTask(String id) async {
    final doc = await _tasks.doc(id).get();
    final projectId = (doc.data() as Map)['projectId'] as String;
    await _tasks.doc(id).delete();
    await _updateProjectTaskCounts(projectId);
  }

  Future<void> _updateProjectTaskCounts(String projectId) async {
    final all  = await _tasks.where('projectId', isEqualTo: projectId).get();
    final now  = DateTime.now();
    int open    = 0;
    int overdue = 0;
    for (final d in all.docs) {
      final data   = d.data() as Map;
      final status = data['status'] as String? ?? '';
      final isOpen = !['done', 'cancelled'].contains(status);
      if (isOpen) open++;
      // Check overdue: has dueDate and dueDate is in the past and still open
      final dueDateRaw = data['dueDate'];
      DateTime? dueDate;
      if (dueDateRaw is Timestamp) dueDate = dueDateRaw.toDate();
      if (dueDateRaw is String)    dueDate = DateTime.tryParse(dueDateRaw);
      if (isOpen && dueDate != null && dueDate.isBefore(now)) overdue++;
    }
    await _projects.doc(projectId).update({
      'taskCount':        all.docs.length,
      'openTaskCount':    open,
      'overdueTaskCount': overdue,
    });
  }
}