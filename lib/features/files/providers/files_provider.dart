import 'package:flutter/material.dart';
import '../data/files_repository.dart';
import '../models/file_node_model.dart';

class FilesProvider extends ChangeNotifier {
  FilesProvider(this._repository);

  final FilesRepository _repository;

  final Map<String, List<FileNodeModel>> _itemsByPath = {};
  bool _isLoading = false;
  bool _isUploading = false;
  String? _errorMessage;

  Map<String, List<FileNodeModel>> get itemsByPath => _itemsByPath;
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  String? get errorMessage => _errorMessage;

  void clearCache() => _itemsByPath.clear();

  // Returns parent path: "/slides/week1" → "/slides", "/slides" → "/"
  String _parentOf(String path) {
    if (path == '/') return '/';
    final idx = path.lastIndexOf('/');
    return idx <= 0 ? '/' : path.substring(0, idx);
  }

  // ─── Fetch ─────────────────────────────────────────────────────────────────

  Future<void> fetchContent(
    String classId,
    String path, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _itemsByPath.containsKey(path)) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _itemsByPath[path] = await _repository.listContent(classId, path);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Create ────────────────────────────────────────────────────────────────

  Future<bool> createFolder(String classId, String path) async {
    try {
      await _repository.createFolder(classId, path);
      await _refreshParent(classId, path);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadFile(
    String classId,
    String targetPath,
    String filePath,
    String fileName,
  ) async {
    _isUploading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.uploadFile(classId, targetPath, filePath, fileName);
      await _refreshParent(classId, targetPath);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  // ─── Download ──────────────────────────────────────────────────────────────

  /// Always fetches a fresh presigned URL — never cached.
  Future<String?> getDownloadUrl(String classId, String filePath) async {
    try {
      return await _repository.getDownloadUrl(classId, filePath);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  // ─── Delete ────────────────────────────────────────────────────────────────

  Future<bool> deleteContent(String classId, String path) async {
    try {
      await _repository.deleteContent(classId, path);
      await _refreshParent(classId, path);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _refreshParent(String classId, String childPath) async {
    final parent = _parentOf(childPath);
    _itemsByPath.remove(parent);
    await fetchContent(classId, parent, forceRefresh: true);
  }
}
