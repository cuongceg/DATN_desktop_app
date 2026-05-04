import '../entities/classroom_entity.dart';
import '../repositories/classroom_repository.dart';

/// Creates a new classroom.
///
/// Teacher-only operation.
class CreateClassroomUseCase {
  const CreateClassroomUseCase(this._repository);

  final ClassroomRepository _repository;

  /// Executes the use case.
  ///
  /// [name] — required display name for the classroom.
  /// [description] — optional description.
  Future<ClassroomEntity> call({required String name, String? description}) {
    return _repository.createClassroom(name: name, description: description);
  }
}
