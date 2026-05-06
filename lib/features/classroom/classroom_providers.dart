import 'package:dio/dio.dart';

import 'data/datasources/classroom_remote_datasource.dart';
import 'data/repositories/classroom_repository_impl.dart';
import 'domain/usecases/activate_classroom_usecase.dart';
import 'domain/usecases/archive_classroom_usecase.dart';
import 'domain/usecases/create_classroom_usecase.dart';
import 'domain/usecases/delete_classroom_usecase.dart';
import 'domain/usecases/get_classrooms_usecase.dart';
import 'domain/usecases/join_classroom_usecase.dart';
import 'domain/usecases/update_classroom_usecase.dart';
import 'presentation/controllers/classroom_notifier.dart';

/// Factory that wires the classroom feature's dependency graph.
///
/// Call [ClassroomProviders.createNotifier] in `main.dart` when building the
/// [ChangeNotifierProvider] for [ClassroomNotifier].
abstract class ClassroomProviders {
  /// Creates a fully-wired [ClassroomNotifier] using the shared [dio] instance.
  static ClassroomNotifier createNotifier(Dio dio) {
    final remote = ClassroomRemoteDatasource(dio);
    final repo = ClassroomRepositoryImpl(remote);

    return ClassroomNotifier(
      getClassroomsUseCase: GetClassroomsUseCase(repo),
      createClassroomUseCase: CreateClassroomUseCase(repo),
      updateClassroomUseCase: UpdateClassroomUseCase(repo),
      deleteClassroomUseCase: DeleteClassroomUseCase(repo),
      archiveClassroomUseCase: ArchiveClassroomUseCase(repo),
      activateClassroomUseCase: ActivateClassroomUseCase(repo),
      joinClassroomUseCase: JoinClassroomUseCase(repo),
    );
  }
}
