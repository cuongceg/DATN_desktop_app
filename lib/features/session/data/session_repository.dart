import '../models/session_model.dart';
import '../models/message_model.dart';
import '../models/session_participant_model.dart';
import 'session_api.dart';

class SessionRepository {
  final SessionApi _api;

  const SessionRepository(this._api);

  Future<List<SessionModel>> getSessionsByClass(String classId) async {
    final data = await _api.fetchSessions(classId);
    return data
        .map((json) => SessionModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<SessionModel> createSession({
    required String classId,
    required String title,
    DateTime? scheduledAt,
    DateTime? scheduledEndAt,
  }) async {
    final data = await _api.createSession(
      classId,
      title,
      scheduledAt: scheduledAt,
      scheduledEndAt: scheduledEndAt,
    );
    return SessionModel.fromJson(data);
  }

  Future<List<SessionModel>> getMySessionsInRange({
    required DateTime from,
    required DateTime to,
  }) async {
    final data = await _api.fetchMySessionsInRange(from: from, to: to);
    return data
        .map((json) => SessionModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<SessionModel> updateSession({
    required String sessionId,
    String? title,
    DateTime? scheduledAt,
    DateTime? scheduledEndAt,
  }) async {
    final data = await _api.updateSession(
      sessionId,
      title: title,
      scheduledAt: scheduledAt,
      scheduledEndAt: scheduledEndAt,
    );
    return SessionModel.fromJson(data);
  }

  Future<void> deleteSession(String sessionId) {
    return _api.deleteSession(sessionId);
  }

  Future<SessionModel> startSession(String sessionId) async {
    final data = await _api.startSession(sessionId);
    return SessionModel.fromJson(data);
  }

  Future<SessionModel> endSession(String sessionId) async {
    final data = await _api.endSession(sessionId);
    return SessionModel.fromJson(data);
  }

  Future<({String token, String livekitUrl, String roomName})> joinSession(
    String sessionId,
  ) async {
    final data = await _api.joinSession(sessionId);
    return (
      token: data['token'] as String,
      livekitUrl: data['livekit_url'] as String,
      roomName: data['room_name'] as String,
    );
  }

  Future<List<MessageModel>> fetchMessages(String sessionId) async {
    final data = await _api.fetchMessages(sessionId);
    return data
        .map((json) => MessageModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<SessionParticipantModel>> getParticipants(
    String sessionId,
  ) async {
    final data = await _api.fetchParticipants(sessionId);
    final list = data['participants'] as List<dynamic>;
    return list
        .map((j) => SessionParticipantModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<void> leaveSession(String sessionId) {
    return _api.leaveSession(sessionId);
  }

  Future<MessageModel> sendMessage(String sessionId, String content) async {
    final data = await _api.sendMessage(sessionId, content);
    return MessageModel.fromJson(data);
  }
}
