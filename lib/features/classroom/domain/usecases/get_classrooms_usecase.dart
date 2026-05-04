import '../entities/classroom_entity.dart';
import '../repositories/classroom_repository.dart';

/// Retrieves the list of classrooms for a given user.
///
/// Works for both teachers (their created classes) and students
/// (their joined classes). The repository implementation determines
/// which endpoint to call based on the backend.
class GetClassroomsUseCase {
  const GetClassroomsUseCase(this._repository);

  final ClassroomRepository _repository;

  /// Executes the use case.
  ///
  /// [userId] — the ID of the currently authenticated user.
  Future<List<ClassroomEntity>> call(String userId) {
    return _repository.getClassrooms(userId);
  }
}
