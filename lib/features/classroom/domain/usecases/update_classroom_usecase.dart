import '../entities/classroom_entity.dart';
import '../repositories/classroom_repository.dart';

/// Updates the name and/or description of an existing classroom.
///
/// Teacher-only operation.
class UpdateClassroomUseCase {
  const UpdateClassroomUseCase(this._repository);

  final ClassroomRepository _repository;

  /// Executes the use case.
  ///
  /// [id] — the classroom's unique identifier.
  /// [name] — the new display name.
  /// [description] — the new description (pass `null` to leave unchanged
  /// if the repository supports partial updates; otherwise pass the current value).
  Future<ClassroomEntity> call({
    required String id,
    required String name,
    String? description,
  }) {
    return _repository.updateClassroom(
      id: id,
      name: name,
      description: description,
    );
  }
}
