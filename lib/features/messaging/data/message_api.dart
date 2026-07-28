import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';

/// Appels HTTP bruts vers les endpoints `conversations/*` et `messages/*`.
class MessageApi {
  Dio get _dio => DioClient.instance.dio;

  Future<Map<String, dynamic>> conversations() => _get('/conversations');

  Future<Map<String, dynamic>> messages(int otherUserId) =>
      _get('/conversations/$otherUserId/messages');

  Future<Map<String, dynamic>> send(Map<String, dynamic> data) =>
      _post('/messages', data);

  Future<Map<String, dynamic>> markRead(int id) =>
      _put('/messages/$id/read', {});

  Future<void> delete(int id) async {
    try {
      await _dio.delete('/messages/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> _get(String path) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(path);
      return response.data ?? const {};
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(path, data: data);
      return response.data ?? const {};
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> _put(
    String path,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(path, data: data);
      return response.data ?? const {};
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
