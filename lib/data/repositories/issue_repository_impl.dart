// lib/data/repositories/issue_repository_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/issue_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/issue_repository.dart';
import '../models/issue_model.dart';

class IssueRepositoryImpl implements IssueRepository {
  final FirebaseFirestore _firestore;

  IssueRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _issuesRef =>
      _firestore.collection(AppConstants.issuesCollection);

  @override
  Stream<List<IssueEntity>> getIssues() {
    return _issuesRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => IssueModel.fromFirestore(doc))
            .toList());
  }

  @override
  Stream<List<IssueEntity>> getIssuesByStatus(String status) {
    return _issuesRef
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => IssueModel.fromFirestore(doc))
            .toList());
  }

  @override
  Future<IssueEntity> getIssueById(String id) async {
    final doc = await _issuesRef.doc(id).get();
    return IssueModel.fromFirestore(doc);
  }

  @override
  Future<void> createIssue(IssueEntity issue, UserEntity createdBy) async {
    final model = IssueModel(
      id: issue.id,
      issueId: issue.issueId,
      customer: issue.customer,
      processName: issue.processName,
      technology: issue.technology,
      priority: issue.priority,
      assignedTo: issue.assignedTo,
      status: issue.status,
      issueSummary: issue.issueSummary,
      rootCauseCategory: issue.rootCauseCategory,
      startDate: issue.startDate,
      closingDate: issue.closingDate,
      actionTaken: issue.actionTaken,
      createdByUid: createdBy.uid,
      createdByName: createdBy.displayName,
      createdAt: DateTime.now(),
    );
    await _issuesRef.doc(issue.id).set(model.toMap());
  }

  @override
  Future<void> updateIssue(IssueEntity issue, UserEntity updatedBy) async {
    final existingDoc = await _issuesRef.doc(issue.id).get();
    final existing = IssueModel.fromFirestore(existingDoc);

    final updated = existing.copyWithUpdate(
      updatedByUid: updatedBy.uid,
      updatedByName: updatedBy.displayName,
      changes: {
        'customer': issue.customer,
        'processName': issue.processName,
        'technology': issue.technology,
        'priority': issue.priority,
        'assignedTo': issue.assignedTo,
        'status': issue.status,
        'issueSummary': issue.issueSummary,
        'rootCauseCategory': issue.rootCauseCategory,
        'startDate': issue.startDate,
        'closingDate': issue.closingDate,
        'actionTaken': issue.actionTaken,
      },
    );

    await _issuesRef.doc(issue.id).update(updated.toMap());
  }

  @override
  Future<void> deleteIssue(String id) async {
    await _issuesRef.doc(id).delete();
  }

  @override
  Future<String> generateIssueId() async {
    // Get count of all issues to generate sequential ID
    final snapshot = await _issuesRef.count().get();
    final count = (snapshot.count ?? 0) + 1;
    return 'ISS-${count.toString().padLeft(4, '0')}';
  }
}
