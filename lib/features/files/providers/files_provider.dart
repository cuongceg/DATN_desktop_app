import 'package:flutter/material.dart';
import '../data/files_repository.dart';
import '../models/category_model.dart';
import '../models/class_file_model.dart';
import '../models/folder_model.dart';

class FilesProvider extends ChangeNotifier {
  FilesProvider(this._repository);

  final FilesRepository _repository;

  List<CategoryModel> _categories = [];
  final Map<String, List<FolderModel>> _foldersByCategory = {};
  final Map<String, List<ClassFileModel>> _filesByFolder = {};
  bool _isLoading = false;
  bool _isUploading = false;
  String? _errorMessage;

  List<CategoryModel> get categories => _categories;
  Map<String, List<FolderModel>> get foldersByCategory => _foldersByCategory;
  Map<String, List<ClassFileModel>> get filesByFolder => _filesByFolder;
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  String? get errorMessage => _errorMessage;

  // ─── Categories ────────────────────────────────────────────────────────────

  Future<void> fetchCategories(String classId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _categories = await _repository.getCategories(classId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createCategory(String classId, String name) async {
    try {
      final created = await _repository.createCategory(classId, name);
      _categories = [..._categories, created];
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCategory(String classId, String categoryId) async {
    try {
      await _repository.deleteCategory(classId, categoryId);
      _categories = _categories.where((c) => c.id != categoryId).toList();
      _foldersByCategory.remove(categoryId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─── Folders ───────────────────────────────────────────────────────────────

  /// Lazy fetch — skips API call if data already cached for [categoryId].
  Future<void> fetchFolders(String classId, String categoryId) async {
    if (_foldersByCategory.containsKey(categoryId)) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final folders = await _repository.getFolders(classId, categoryId);
      _foldersByCategory[categoryId] = folders;
    } catch (e) {
      debugPrint('folder error: ${e.toString()}');
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createFolder(
    String classId,
    String categoryId,
    String name,
  ) async {
    try {
      final created = await _repository.createFolder(classId, categoryId, name);
      final existing = _foldersByCategory[categoryId] ?? [];
      _foldersByCategory[categoryId] = [...existing, created];
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteFolder(
    String classId,
    String categoryId,
    String folderId,
  ) async {
    try {
      await _repository.deleteFolder(classId, categoryId, folderId);
      final existing = _foldersByCategory[categoryId];
      if (existing != null) {
        _foldersByCategory[categoryId] = existing
            .where((f) => f.id != folderId)
            .toList();
      }
      _filesByFolder.remove(folderId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─── Files ─────────────────────────────────────────────────────────────────

  /// Lazy fetch — skips API call if data already cached for [folderId].
  Future<void> fetchFiles(String classId, String folderId) async {
    if (_filesByFolder.containsKey(folderId)) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final files = await _repository.getFiles(classId, folderId);
      _filesByFolder[folderId] = files;
    } catch (e) {
      debugPrint('file error: ${e.toString()}');
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> uploadFile(
    String classId,
    String folderId,
    String filePath,
    String fileName,
  ) async {
    _isUploading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final uploaded = await _repository.uploadFile(
        classId,
        folderId,
        filePath,
        fileName,
      );
      final existing = _filesByFolder[folderId] ?? [];
      _filesByFolder[folderId] = [...existing, uploaded];
      notifyListeners();
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

  Future<String?> getDownloadUrl(String fileId) async {
    try {
      return await _repository.getDownloadUrl(fileId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteFile(
    String classId,
    String folderId,
    String fileId,
  ) async {
    try {
      await _repository.deleteFile(fileId);
      final existing = _filesByFolder[folderId];
      if (existing != null) {
        _filesByFolder[folderId] = existing
            .where((f) => f.id != fileId)
            .toList();
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
