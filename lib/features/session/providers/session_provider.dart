import 'package:flutter/material.dart';
import '../models/session_model.dart';
import '../services/session_service.dart';

enum SessionLoadState { idle, loading, success, error }

enum _SessionQueryMode { none, byClass, byRange }

class SessionProvider extends ChangeNotifier {
  final SessionService _service;

  SessionProvider(this._service);

  List<SessionModel> _sessions = [];
  bool _isLoading = false;
  String? _error;

  SessionLoadState loadState = SessionLoadState.idle;

  _SessionQueryMode _lastQueryMode = _SessionQueryMode.none;
  DateTime? _lastFrom;
  DateTime? _lastTo;

  List<SessionModel> get sessions => _sessions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _error;

  Future<void> fetchSessions(String classId) async {
    _lastQueryMode = _SessionQueryMode.byClass;
    loadState = SessionLoadState.loading;
    notifyListeners();
    try {
      _sessions = await _service.fetchSessionsByClass(classId);
      _error = null;
      loadState = SessionLoadState.success;
    } catch (e) {
      _error = e.toString();
      loadState = SessionLoadState.error;
    }
    notifyListeners();
  }

  Future<void> loadSessionsForRange(DateTime from, DateTime to) async {
    _lastQueryMode = _SessionQueryMode.byRange;
    _lastFrom = from;
    _lastTo = to;

    _isLoading = true;
    notifyListeners();
    try {
      _sessions = await _service.fetchMySessionsInRange(from, to);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<SessionModel?> createSession(
    String classId,
    String title, {
    DateTime? scheduledAt,
    DateTime? scheduledEndAt,
  }) async {
    try {
      final session = await _service.createSession(
        classId: classId,
        title: title,
        scheduledAt: scheduledAt,
        scheduledEndAt: scheduledEndAt,
      );
      _sessions = [session, ..._sessions];
      notifyListeners();
      return session;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateSession({
    required String sessionId,
    String? title,
    DateTime? scheduledAt,
    DateTime? scheduledEndAt,
  }) async {
    try {
      final updated = await _service.updateSession(
        sessionId: sessionId,
        title: title,
        scheduledAt: scheduledAt,
        scheduledEndAt: scheduledEndAt,
      );
      _updateLocal(updated);
      if (_lastQueryMode == _SessionQueryMode.byRange &&
          _lastFrom != null &&
          _lastTo != null) {
        await loadSessionsForRange(_lastFrom!, _lastTo!);
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSession(String sessionId) async {
    try {
      await _service.deleteSession(sessionId);
      _sessions = _sessions.where((s) => s.id != sessionId).toList();
      notifyListeners();
      if (_lastQueryMode == _SessionQueryMode.byRange &&
          _lastFrom != null &&
          _lastTo != null) {
        await loadSessionsForRange(_lastFrom!, _lastTo!);
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<SessionModel?> startSession(String sessionId) async {
    try {
      final SessionModel started = await _service.startSession(sessionId);
      _updateLocal(started);
      return started;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> endSession(String sessionId) async {
    final updated = await _service.endSession(sessionId);
    _updateLocal(updated);
  }

  Future<({String token, String livekitUrl, String roomName})?> joinSession(
    String sessionId,
  ) async {
    try {
      return await _service.joinSession(sessionId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  List<SessionModel> sessionsForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _sessions.where((s) {
      final display = s.displayTime;
      if (display == null) return false;
      return display.isAtSameMomentAs(startOfDay) ||
          (display.isAfter(startOfDay) && display.isBefore(endOfDay));
    }).toList();
  }

  void _updateLocal(SessionModel updated) {
    _sessions = _sessions.map((s) => s.id == updated.id ? updated : s).toList();
    notifyListeners();
  }
}
