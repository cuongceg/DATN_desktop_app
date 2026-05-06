import 'package:flutter/material.dart';
import '../models/session_model.dart';
import '../data/session_repository.dart';

enum SessionLoadState { idle, loading, success, error }

class SessionProvider extends ChangeNotifier {
  final SessionRepository _repo;
  SessionProvider(this._repo);

  List<SessionModel> sessions = [];
  SessionLoadState  loadState = SessionLoadState.idle;
  String?           errorMessage;

  Future<void> fetchSessions(String classId) async {
    loadState = SessionLoadState.loading;
    notifyListeners();
    try {
      sessions  = await _repo.getSessionsByClass(classId);
      loadState = SessionLoadState.success;
    } catch (e) {
      errorMessage = e.toString();
      loadState    = SessionLoadState.error;
    }
    notifyListeners();
  }

  Future<SessionModel?> createSession(String classId, String title) async {
    try {
      final session = await _repo.createSession(classId, title);
      sessions = [session, ...sessions];
      notifyListeners();
      return session;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> startSession(String sessionId) async {
    final updated = await _repo.startSession(sessionId);
    _updateLocal(updated);
  }

  Future<void> endSession(String sessionId) async {
    final updated = await _repo.endSession(sessionId);
    _updateLocal(updated);
  }

  Future<({String token, String livekitUrl, String roomName})?> joinSession(
    String sessionId,
  ) async {
    try {
      return await _repo.joinSession(sessionId);
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  void _updateLocal(SessionModel updated) {
    sessions = sessions.map((s) => s.id == updated.id ? updated : s).toList();
    notifyListeners();
  }
}
