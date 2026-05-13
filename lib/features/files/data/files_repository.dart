import 'package:dio/dio.dart';
import '../models/file_node_model.dart';

class FilesRepository {
  const FilesRepository(this._dio);

  final Dio _dio;

  Future<List<FileNodeModel>> listContent(String classId, String path) async {
    try {
      final response = await _dio.get(
        '/api/files/class/$classId/content',
        queryParameters: {'path': path},
      );
      final list = response.data['items'] as List;
      return list
          .map((e) => FileNodeModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  Future<void> createFolder(String classId, String path) async {
    try {
      await _dio.post(
        '/api/files/class/$classId/content',
        data: {'type': 'folder', 'path': path},
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw Exception('Tên đã tồn tại trong thư mục này.');
      }
      throw Exception(_handleDioError(e));
    }
  }

  Future<void> uploadFile(
    String classId,
    String targetPath,
    String filePath,
    String fileName,
  ) async {
    try {
      final formData = FormData.fromMap({
        'type': 'file',
        'path': targetPath,
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });
      await _dio.post('/api/files/class/$classId/content', data: formData);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw Exception('Tên đã tồn tại trong thư mục này.');
      }
      throw Exception(_handleDioError(e));
    }
  }

  Future<String> getDownloadUrl(String classId, String path) async {
    try {
      final response = await _dio.get(
        '/api/files/class/$classId/download',
        queryParameters: {'path': path},
      );
      return response.data['download_url'] as String;
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  Future<void> deleteContent(String classId, String path) async {
    try {
      await _dio.delete(
        '/api/files/class/$classId/content',
        queryParameters: {'path': path},
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception('Thư mục không rỗng, xóa các file bên trong trước.');
      }
      throw Exception(_handleDioError(e));
    }
  }

  // ─── Error helper ──────────────────────────────────────────────────────────

  String _handleDioError(DioException e) {
    return e.response?.data['message'] as String? ?? 'Unknown error occurred.';
  }
}
