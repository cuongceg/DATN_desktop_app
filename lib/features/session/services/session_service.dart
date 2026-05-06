import '../data/session_repository.dart';
import '../models/session_model.dart';

/// Service layer cho Session feature.
///
/// Hiện tại service delegate sang [SessionRepository]. Việc attach token được
/// handle bởi `ApiClient` interceptor (Authorization header).
class SessionService {
  /// Creates a [SessionService].
  const SessionService(this._repo);

  final SessionRepository _repo;

  /// Fetch sessions của 1 lớp.
  Future<List<SessionModel>> fetchSessionsByClass(String classId) {
    return _repo.getSessionsByClass(classId);
  }

  /// Fetch tất cả sessions liên quan user trong khoảng thời gian để hiển thị calendar.
  Future<List<SessionModel>> fetchMySessionsInRange(
    DateTime from,
    DateTime to,
  ) {
    return _repo.getMySessionsInRange(from: from, to: to);
  }

  /// Tạo session mới.
  Future<SessionModel> createSession({
    required String classId,
    required String title,
    DateTime? scheduledAt,
    DateTime? scheduledEndAt,
  }) {
    return _repo.createSession(
      classId: classId,
      title: title,
      scheduledAt: scheduledAt,
      scheduledEndAt: scheduledEndAt,
    );
  }

  /// Update title/scheduledAt/scheduledEndAt của session.
  Future<SessionModel> updateSession({
    required String sessionId,
    String? title,
    DateTime? scheduledAt,
    DateTime? scheduledEndAt,
  }) {
    return _repo.updateSession(
      sessionId: sessionId,
      title: title,
      scheduledAt: scheduledAt,
      scheduledEndAt: scheduledEndAt,
    );
  }

  /// Delete session (chỉ status scheduled).
  Future<void> deleteSession(String sessionId) {
    return _repo.deleteSession(sessionId);
  }

  /// Start session (scheduled -> ongoing).
  Future<SessionModel> startSession(String sessionId) {
    return _repo.startSession(sessionId);
  }

  /// End session (ongoing -> completed).
  Future<SessionModel> endSession(String sessionId) {
    return _repo.endSession(sessionId);
  }

  /// Join session và lấy token LiveKit.
  Future<({String token, String livekitUrl, String roomName})> joinSession(
    String sessionId,
  ) {
    return _repo.joinSession(sessionId);
  }
}
