import 'package:dio/dio.dart';

/// Maps API error messages to user-friendly Vietnamese messages.
String _mapApiError(DioException e) {
  final data = e.response?.data;
  final serverMsg = (data is Map ? data['message'] as String? : null) ?? '';
  final status = e.response?.statusCode ?? 0;

  // joinSession specific errors (POST /sessions/:id/token)
  if (serverMsg == 'Session has not started yet.') {
    return 'Buổi học chưa bắt đầu.';
  }
  if (serverMsg == 'Session has already ended.') {
    return 'Buổi học đã kết thúc.';
  }
  if (serverMsg == 'You are not a member of this class.') {
    return 'Bạn không thuộc lớp học này.';
  }
  if (serverMsg == 'Session not found.') {
    return 'Không tìm thấy buổi học.';
  }

  // startSession / endSession errors
  if (serverMsg == 'Unable to start session.') {
    return 'Không thể bắt đầu buổi học (trạng thái không hợp lệ).';
  }
  if (serverMsg == 'Unable to end session.') {
    return 'Không thể kết thúc buổi học (trạng thái không hợp lệ).';
  }
  if (serverMsg == 'Only teachers can start sessions.') {
    return 'Chỉ giáo viên mới có thể bắt đầu buổi học.';
  }
  if (serverMsg == 'Only teachers can end sessions.') {
    return 'Chỉ giáo viên mới có thể kết thúc buổi học.';
  }

  // createSession errors
  if (serverMsg.contains('classId must be a valid UUID')) {
    return 'ID lớp học không hợp lệ.';
  }
  if (serverMsg == 'title is required.') {
    return 'Tiêu đề buổi học không được để trống.';
  }
  if (serverMsg.contains('do not have permission to create')) {
    return 'Bạn không có quyền tạo buổi học cho lớp này.';
  }

  // Generic fallback
  if (status == 401) return 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.';
  if (status == 403) return 'Bạn không có quyền thực hiện thao tác này.';
  if (status == 404) return 'Không tìm thấy tài nguyên.';
  if (serverMsg.isNotEmpty) return serverMsg;
  return 'Đã xảy ra lỗi. Vui lòng thử lại.';
}

class SessionApi {
  final Dio _dio;

  const SessionApi(this._dio);

  Future<List<dynamic>> fetchSessions(String classId) async {
    try {
      final response = await _dio.get('/api/sessions/class/$classId');
      return response.data['sessions'] as List<dynamic>;
    } on DioException catch (e) {
      throw Exception(_mapApiError(e));
    }
  }

  Future<Map<String, dynamic>> createSession(String classId, String title) async {
    try {
      final response = await _dio.post('/api/sessions', data: {
        'classId': classId,
        'title': title,
      });
      return response.data['session'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_mapApiError(e));
    }
  }

  Future<Map<String, dynamic>> startSession(String sessionId) async {
    try {
      final response = await _dio.patch('/api/sessions/$sessionId/start');
      return response.data['session'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_mapApiError(e));
    }
  }

  Future<Map<String, dynamic>> endSession(String sessionId) async {
    try {
      final response = await _dio.patch('/api/sessions/$sessionId/end');
      return response.data['session'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_mapApiError(e));
    }
  }

  /// POST /api/sessions/:sessionId/token
  /// Returns: { token, livekit_url, room_name }
  ///
  /// Errors:
  ///   400 Session has not started yet.     → 'Buổi học chưa bắt đầu.'
  ///   400 Session has already ended.       → 'Buổi học đã kết thúc.'
  ///   403 You are not a member...          → 'Bạn không thuộc lớp học này.'
  Future<Map<String, dynamic>> joinSession(String sessionId) async {
    try {
      final response = await _dio.post('/api/sessions/$sessionId/token');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_mapApiError(e));
    }
  }

  Future<List<dynamic>> fetchMessages(String sessionId) async {
    try {
      final response = await _dio.get('/api/sessions/$sessionId/messages');
      return response.data['messages'] as List<dynamic>;
    } on DioException catch (e) {
      throw Exception(_mapApiError(e));
    }
  }

  Future<Map<String, dynamic>> sendMessage(String sessionId, String content) async {
    try {
      final response = await _dio.post('/api/sessions/$sessionId/messages', data: {
        'content': content,
      });
      return response.data['message_data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_mapApiError(e));
    }
  }
}
