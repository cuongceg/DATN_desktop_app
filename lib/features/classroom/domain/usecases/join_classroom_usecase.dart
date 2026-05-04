import '../entities/classroom_entity.dart';
import '../repositories/classroom_repository.dart';

/// Joins a classroom using an invite code.
///
/// Student-only operation.
class JoinClassroomUseCase {
  const JoinClassroomUseCase(this._repository);

  final ClassroomRepository _repository;

  /// Executes the use case.
  ///
  /// [classCode] — the invite code provided by the teacher.
  /// Returns the [ClassroomEntity] that was joined.
  Future<ClassroomEntity> call(String classCode) {
    return _repository.joinClassroom(classCode);
  }
}
