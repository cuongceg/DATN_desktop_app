import 'package:dio/dio.dart';

import 'auth_storage.dart';

class ApiClient {
  ApiClient({
    required AuthStorage authStorage,
    String baseUrl = 'http://localhost:3000',
  }) : dio = Dio(
         BaseOptions(
           baseUrl: baseUrl,
           connectTimeout: const Duration(seconds: 10),
           receiveTimeout: const Duration(seconds: 12),
           sendTimeout: const Duration(seconds: 12),
           contentType: Headers.jsonContentType,
           responseType: ResponseType.json,
         ),
       ) {
    dio.interceptors.add(
      _AuthInterceptor(
        authStorage: authStorage,
        excludedPaths: const {'/api/auth/login', '/api/auth/register'},
      ),
    );
  }

  final Dio dio;
}

class _AuthInterceptor extends Interceptor {
  const _AuthInterceptor({
    required this.authStorage,
    required this.excludedPaths,
  });

  final AuthStorage authStorage;
  final Set<String> excludedPaths;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final shouldSkipAuth = excludedPaths.any(options.path.endsWith);
    if (!shouldSkipAuth) {
      final token = await authStorage.readToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }
}
