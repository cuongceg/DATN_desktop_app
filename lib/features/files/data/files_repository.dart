import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/category_model.dart';
import '../models/class_file_model.dart';
import '../models/folder_model.dart';

class FilesRepository {
  const FilesRepository(this._dio);

  final Dio _dio;

  // ─── Categories ────────────────────────────────────────────────────────────

  Future<List<CategoryModel>> getCategories(String classId) async {
    try {
      final response = await _dio.get('/api/files/class/$classId/categories');
      final list = response.data['categories'] as List;
      return list
          .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  Future<CategoryModel> createCategory(String classId, String name) async {
    try {
      final response = await _dio.post(
        '/api/files/class/$classId/categories',
        data: {'name': name},
      );
      return CategoryModel.fromJson(
        response.data['category'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  Future<void> deleteCategory(String classId, String categoryId) async {
    try {
      await _dio.delete('/api/files/class/$classId/categories/$categoryId');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  // ─── Folders ───────────────────────────────────────────────────────────────

  Future<List<FolderModel>> getFolders(
    String classId,
    String categoryId,
  ) async {
    try {
      final response = await _dio.get(
        '/api/files/class/$classId/categories/$categoryId/folders',
      );
      final list = response.data['folders'] as List;
      debugPrint('folders: $list');
      return list
          .map((e) => FolderModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      debugPrint('folder error: ${e.toString()}');
      throw Exception(_handleDioError(e));
    }
  }

  Future<FolderModel> createFolder(
    String classId,
    String categoryId,
    String name,
  ) async {
    try {
      final response = await _dio.post(
        '/api/files/class/$classId/categories/$categoryId/folders',
        data: {'name': name},
      );
      return FolderModel.fromJson(
        response.data['folder'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  Future<void> deleteFolder(
    String classId,
    String categoryId,
    String folderId,
  ) async {
    try {
      await _dio.delete(
        '/api/files/class/$classId/categories/$categoryId/folders/$folderId',
      );
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  // ─── Files ─────────────────────────────────────────────────────────────────

  Future<List<ClassFileModel>> getFiles(String classId, String folderId) async {
    try {
      final response = await _dio.get(
        '/api/files/class/$classId/folders/$folderId/files',
      );
      final list = response.data['files'] as List;
      debugPrint('files: $list');
      return list
          .map((e) => ClassFileModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  Future<ClassFileModel> uploadFile(
    String classId,
    String folderId,
    String filePath,
    String fileName,
  ) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });
      final response = await _dio.post(
        '/api/files/class/$classId/folders/$folderId/upload',
        data: formData,
      );
      return ClassFileModel.fromJson(
        response.data['file'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  Future<String> getDownloadUrl(String fileId) async {
    try {
      final response = await _dio.get('/api/files/$fileId/download-url');
      return response.data['download_url'] as String;
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  Future<void> deleteFile(String fileId) async {
    try {
      await _dio.delete('/api/files/$fileId');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  // ─── Error helper ──────────────────────────────────────────────────────────

  String _handleDioError(DioException e) {
    return e.response?.data['message'] as String? ?? 'Unknown error occurred.';
  }
}
