import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../env.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(tokenStorageProvider));
});

/// Dio wrapper: base URL, bearer auth, retry-on-network with backoff,
/// and mapping of every failure into [ApiException].
class ApiClient {
  ApiClient(this._tokens, {Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options
      ..baseUrl = Env.apiBaseUrl
      ..connectTimeout = const Duration(seconds: 15)
      ..receiveTimeout = const Duration(seconds: 20)
      ..headers = {'Accept': 'application/json'};

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _tokens.read();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  final Dio _dio;
  final TokenStorage _tokens;

  Future<Map<String, dynamic>> get(String path,
          {Map<String, dynamic>? query}) =>
      _request(() => _dio.get(path, queryParameters: query));

  Future<Map<String, dynamic>> post(String path, {Object? body}) =>
      _request(() => _dio.post(path, data: body));

  Future<Map<String, dynamic>> patch(String path, {Object? body}) =>
      _request(() => _dio.patch(path, data: body));

  Future<Map<String, dynamic>> delete(String path) =>
      _request(() => _dio.delete(path));

  Future<Map<String, dynamic>> _request(
    Future<Response<dynamic>> Function() send, {
    int retries = 2,
  }) async {
    var attempt = 0;
    while (true) {
      try {
        final response = await send();
        final data = response.data;
        if (data is Map<String, dynamic>) return data;
        return const {};
      } on DioException catch (e) {
        final retriable = e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout;
        if (retriable && attempt < retries) {
          attempt++;
          await Future<void>.delayed(
              Duration(milliseconds: 400 * (1 << attempt)));
          continue;
        }
        throw _map(e);
      }
    }
  }

  ApiException _map(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
        return const ApiException(
            code: 'network',
            message: 'Could not reach the server. Check your connection.');
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const ApiException(
            code: 'timeout', message: 'The server took too long to respond.');
      default:
        break;
    }

    final status = e.response?.statusCode;
    final body = e.response?.data;
    if (body is Map<String, dynamic> && body['error'] is Map) {
      final err = body['error'] as Map;
      final details = <String, List<String>>{};
      final rawDetails = err['details'];
      if (rawDetails is Map) {
        rawDetails.forEach((k, v) {
          if (v is List) {
            details['$k'] = v.map((m) => '$m').toList();
          }
        });
      }
      return ApiException(
        code: '${err['code'] ?? 'unknown'}',
        message: '${err['message'] ?? 'Something went wrong.'}',
        statusCode: status,
        fieldErrors: details,
      );
    }
    return ApiException(
      code: 'unknown',
      message: 'Something went wrong. Please try again.',
      statusCode: status,
    );
  }
}
