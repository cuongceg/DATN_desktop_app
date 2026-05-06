import '../models/session_model.dart';
import '../models/message_model.dart';
import 'session_api.dart';

class SessionRepository {
  final SessionApi _api;

  const SessionRepository(this._api);

  Future<List<SessionModel>> getSessionsByClass(String classId) async {
    final data = await _api.fetchSessions(classId);
    return data.map((json) => SessionModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<SessionModel> createSession(String classId, String title) async {
    final data = await _api.createSession(classId, title);
    return SessionModel.fromJson(data);
  }

  Future<SessionModel> startSession(String sessionId) async {
    final data = await _api.startSession(sessionId);
    return SessionModel.fromJson(data);
  }

  Future<SessionModel> endSession(String sessionId) async {
    final data = await _api.endSession(sessionId);
    return SessionModel.fromJson(data);
  }

  Future<({String token, String livekitUrl, String roomName})> joinSession(String sessionId) async {
    final data = await _api.joinSession(sessionId);
    return (
      token: data['token'] as String,
      livekitUrl: data['livekit_url'] as String,
      roomName: data['room_name'] as String,
    );
  }

  Future<List<MessageModel>> fetchMessages(String sessionId) async {
    final data = await _api.fetchMessages(sessionId);
    return data.map((json) => MessageModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<MessageModel> sendMessage(String sessionId, String content) async {
    final data = await _api.sendMessage(sessionId, content);
    return MessageModel.fromJson(data);
  }
}
