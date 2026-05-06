import '../entities/classroom_entity.dart';
import '../repositories/classroom_repository.dart';

/// Archives a classroom (active → archived).
///
/// Teacher-only operation.
class ArchiveClassroomUseCase {
  const ArchiveClassroomUseCase(this._repository);

  final ClassroomRepository _repository;

  /// Executes the use case.
  ///
  /// [id] — the classroom's unique identifier.
  Future<ClassroomEntity> call(String id) {
    return _repository.archiveClassroom(id);
  }
}
