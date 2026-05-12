import 'package:flutter/material.dart';
import '../data/posts_repository.dart';
import '../models/post_model.dart';

class PostsProvider extends ChangeNotifier {
  PostsProvider(this._repository);

  final PostsRepository _repository;

  List<PostModel> _posts = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  int _currentOffset = 0;
  int _totalCount = 0;

  static const int _pageSize = 20;

  List<PostModel> get posts => _posts;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;

  Future<void> fetchPosts(String classId, {bool refresh = false}) async {
    if (refresh) {
      _currentOffset = 0;
      _posts = [];
      _hasMore = true;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _repository.getPosts(
        classId,
        limit: _pageSize,
        offset: _currentOffset,
      );
      debugPrint('PostsProvider: getPosts: $result');
      _posts = result.posts;
      _totalCount = result.totalCount;
      _hasMore = _posts.length < _totalCount;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMorePosts(String classId) async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();
    try {
      final result = await _repository.getPosts(
        classId,
        limit: _pageSize,
        offset: _currentOffset,
      );
      _posts = [..._posts, ...result.posts];
      _totalCount = result.totalCount;
      _currentOffset = _posts.length;
      _hasMore = _posts.length < _totalCount;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<PostModel?> createPost({
    required String classId,
    String? title,
    required Map<String, dynamic> bodyDelta,
    required String bodyPlain,
  }) async {
    try {
      final post = await _repository.createPost(
        classId: classId,
        title: title,
        bodyDelta: bodyDelta,
        bodyPlain: bodyPlain,
      );
      _posts = [post, ..._posts];
      _totalCount++;
      notifyListeners();
      return post;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> updatePost({
    required String postId,
    String? title,
    Map<String, dynamic>? bodyDelta,
    String? bodyPlain,
  }) async {
    try {
      final updated = await _repository.updatePost(
        postId: postId,
        title: title,
        bodyDelta: bodyDelta,
        bodyPlain: bodyPlain,
      );
      final index = _posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final list = List<PostModel>.of(_posts);
        list[index] = updated;
        _posts = list;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePost(String postId) async {
    try {
      await _repository.deletePost(postId);
      _posts = _posts.where((p) => p.id != postId).toList();
      if (_totalCount > 0) _totalCount--;
      _currentOffset = _posts.length; // keep offset in sync after local delete
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
