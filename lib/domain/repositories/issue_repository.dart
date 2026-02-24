// lib/domain/repositories/issue_repository.dart
import '../entities/issue_entity.dart';
import '../entities/user_entity.dart';

abstract class IssueRepository {
  Stream<List<IssueEntity>> getIssues();
  Stream<List<IssueEntity>> getIssuesByStatus(String status);
  Future<IssueEntity> getIssueById(String id);
  Future<void> createIssue(IssueEntity issue, UserEntity createdBy);
  Future<void> updateIssue(IssueEntity issue, UserEntity updatedBy);
  Future<void> deleteIssue(String id);
  Future<String> generateIssueId();
}
