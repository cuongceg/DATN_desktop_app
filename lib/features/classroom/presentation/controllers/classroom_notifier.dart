import 'package:flutter/foundation.dart';

import '../../domain/entities/classroom_entity.dart';
import '../../domain/usecases/create_classroom_usecase.dart';
import '../../domain/usecases/delete_classroom_usecase.dart';
import '../../domain/usecases/get_classrooms_usecase.dart';
import '../../domain/usecases/join_classroom_usecase.dart';
import '../../domain/usecases/update_classroom_usecase.dart';

/// State for [ClassroomNotifier].
enum ClassroomStatus { initial, loading, success, failure }

/// Manages classroom list state for the entire application.
///
/// Consumed via [ChangeNotifierProvider]. Screens call:
/// - `context.watch<ClassroomNotifier>()` to rebuild on state changes.
/// - `context.read<ClassroomNotifier>()` to trigger actions.
class ClassroomNotifier extends ChangeNotifier {
  ClassroomNotifier({
    required GetClassroomsUseCase getClassroomsUseCase,
    required CreateClassroomUseCase createClassroomUseCase,
    required UpdateClassroomUseCase updateClassroomUseCase,
    required DeleteClassroomUseCase deleteClassroomUseCase,
    required JoinClassroomUseCase joinClassroomUseCase,
  }) : _getClassrooms = getClassroomsUseCase,
       _createClassroom = createClassroomUseCase,
       _updateClassroom = updateClassroomUseCase,
       _deleteClassroom = deleteClassroomUseCase,
       _joinClassroom = joinClassroomUseCase;

  final GetClassroomsUseCase _getClassrooms;
  final CreateClassroomUseCase _createClassroom;
  final UpdateClassroomUseCase _updateClassroom;
  final DeleteClassroomUseCase _deleteClassroom;
  final JoinClassroomUseCase _joinClassroom;

  List<ClassroomEntity> _classrooms = const [];
  ClassroomStatus _status = ClassroomStatus.initial;
  String? _error;

  /// The current list of classrooms.
  List<ClassroomEntity> get classrooms => _classrooms;

  /// Whether classrooms are being loaded or mutated.
  bool get isLoading => _status == ClassroomStatus.loading;

  /// The last error message, if any.
  String? get error => _error;

  /// Current status of the notifier.
  ClassroomStatus get status => _status;

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// Loads classrooms for the given [userId].
  ///
  /// Replaces the current list on success, sets [error] on failure.
  Future<void> loadClassrooms(String userId) async {
    _setLoading();
    try {
      _classrooms = await _getClassrooms(userId);
      _status = ClassroomStatus.success;
      _error = null;
    } catch (e) {
      _status = ClassroomStatus.failure;
      _error = e.toString();
    }
    notifyListeners();
  }

  /// Creates a new classroom and prepends it to the list.
  ///
  /// Throws on failure so the UI can show an error snackbar.
  Future<ClassroomEntity> createClassroom({
    required String name,
    String? description,
  }) async {
    final created = await _createClassroom(
      name: name,
      description: description,
    );
    _classrooms = [created, ..._classrooms];
    notifyListeners();
    return created;
  }

  /// Updates a classroom in place and notifies listeners.
  ///
  /// Throws on failure so the UI can show an error snackbar.
  Future<ClassroomEntity> updateClassroom({
    required String id,
    required String name,
    String? description,
  }) async {
    final updated = await _updateClassroom(
      id: id,
      name: name,
      description: description,
    );
    _classrooms = _classrooms
        .map((item) => item.id == updated.id ? updated : item)
        .toList(growable: false);
    notifyListeners();
    return updated;
  }

  /// Deletes a classroom by [classroomId] and removes it from the list.
  ///
  /// Throws on failure so the UI can show an error snackbar.
  Future<void> deleteClassroom(String classroomId) async {
    await _deleteClassroom(classroomId);
    _classrooms = _classrooms
        .where((item) => item.id != classroomId)
        .toList(growable: false);
    notifyListeners();
  }

  /// Joins a classroom using [classCode] and appends it to the list if new.
  ///
  /// Returns the joined [ClassroomEntity].
  /// Throws on failure so the UI can show an error snackbar.
  Future<ClassroomEntity> joinClassroom(String classCode) async {
    final joined = await _joinClassroom(classCode);
    final alreadyExists = _classrooms.any((item) => item.id == joined.id);
    if (!alreadyExists) {
      _classrooms = [joined, ..._classrooms];
      notifyListeners();
    }
    return joined;
  }

  /// Clears classroom data (called on logout).
  void clear() {
    _classrooms = const [];
    _status = ClassroomStatus.initial;
    _error = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _setLoading() {
    _status = ClassroomStatus.loading;
    _error = null;
    notifyListeners();
  }
}
