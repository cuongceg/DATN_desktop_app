import 'package:dio/dio.dart';
import '../models/post_model.dart';

class PostsRepository {
  const PostsRepository(this._dio);

  final Dio _dio;

  Future<({List<PostModel> posts, int totalCount})> getPosts(
    String classId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        '/api/posts/class/$classId',
        queryParameters: {'limit': limit, 'offset': offset},
      );
      final data = response.data as Map<String, dynamic>;
      final list = data['posts'] as List;
      return (
        posts: list
            .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalCount: data['total_count'] as int,
      );
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  Future<PostModel> getPost(String postId) async {
    try {
      final response = await _dio.get('/api/posts/$postId');
      return PostModel.fromJson(response.data['post'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  Future<PostModel> createPost({
    required String classId,
    String? title,
    required Map<String, dynamic> bodyDelta,
    required String bodyPlain,
  }) async {
    try {
      final response = await _dio.post(
        '/api/posts',
        data: {
          'classId': classId,
          if (title != null && title.isNotEmpty) 'title': title,
          'bodyDelta': bodyDelta,
          'bodyPlain': bodyPlain,
        },
      );
      return PostModel.fromJson(response.data['post'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  Future<PostModel> updatePost({
    required String postId,
    String? title,
    Map<String, dynamic>? bodyDelta,
    String? bodyPlain,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (bodyDelta != null) data['bodyDelta'] = bodyDelta;
      if (bodyPlain != null) data['bodyPlain'] = bodyPlain;
      final response = await _dio.patch('/api/posts/$postId', data: data);
      return PostModel.fromJson(response.data['post'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await _dio.delete('/api/posts/$postId');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  String _handleDioError(DioException e) {
    return e.response?.data['message'] as String? ?? 'Unknown error occurred.';
  }
}
