import '../repositories/classroom_repository.dart';

/// Permanently deletes a classroom by its ID.
///
/// Teacher-only operation. This action cannot be undone.
class DeleteClassroomUseCase {
  const DeleteClassroomUseCase(this._repository);

  final ClassroomRepository _repository;

  /// Executes the use case.
  ///
  /// [classroomId] — the unique identifier of the classroom to delete.
  Future<void> call(String classroomId) {
    return _repository.deleteClassroom(classroomId);
  }
}
