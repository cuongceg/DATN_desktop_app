import '../entities/classroom_entity.dart';
import '../entities/classroom_member_entity.dart';

/// Abstract interface for classroom data operations.
///
/// Implementations live in the data layer. The domain layer depends only on
/// this interface, never on a concrete class.
abstract interface class ClassroomRepository {
  /// Returns classrooms relevant to [userId].
  ///
  /// - Teacher: classrooms they created.
  /// - Student: classrooms they have joined.
  Future<List<ClassroomEntity>> getClassrooms(String userId);

  /// Creates a new classroom with [name] and optional [description].
  ///
  /// Teacher-only operation.
  Future<ClassroomEntity> createClassroom({
    required String name,
    String? description,
  });

  /// Updates [name] and/or [description] of the classroom identified by [id].
  ///
  /// Teacher-only operation.
  Future<ClassroomEntity> updateClassroom({
    required String id,
    required String name,
    String? description,
  });

  /// Permanently deletes the classroom identified by [id].
  ///
  /// Teacher-only operation.
  Future<void> deleteClassroom(String id);

  /// Joins a classroom using the invite [classCode].
  ///
  /// Student-only operation. Returns the joined [ClassroomEntity].
  Future<ClassroomEntity> joinClassroom(String classCode);

  /// Fetches the full details of a classroom including its [members].
  Future<(ClassroomEntity, List<ClassroomMemberEntity>)> fetchClassroomDetails(
    String classroomId,
  );

  /// Adds a single member by [userId] to classroom [classId].
  Future<ClassroomMemberEntity> addMember({
    required String classId,
    required String userId,
    String permission,
  });

  /// Adds multiple members by [studentIds] to classroom [classId].
  Future<void> addMembersBulk({
    required String classId,
    required List<String> studentIds,
  });

  /// Updates the [role] of [userId] in classroom [classId].
  Future<ClassroomMemberEntity> updateMemberRole({
    required String classId,
    required String userId,
    required String role,
  });

  /// Removes [userId] from classroom [classId].
  Future<void> removeMember({required String classId, required String userId});
}
