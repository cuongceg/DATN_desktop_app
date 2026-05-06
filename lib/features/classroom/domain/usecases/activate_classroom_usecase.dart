import '../entities/classroom_entity.dart';
import '../repositories/classroom_repository.dart';

/// Activates a classroom (archived → active).
///
/// Teacher-only operation.
class ActivateClassroomUseCase {
  const ActivateClassroomUseCase(this._repository);

  final ClassroomRepository _repository;

  /// Executes the use case.
  ///
  /// [id] — the classroom's unique identifier.
  Future<ClassroomEntity> call(String id) {
    return _repository.activateClassroom(id);
  }
}
