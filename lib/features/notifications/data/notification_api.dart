import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';

/// Appels HTTP bruts vers les endpoints `notifications/*`.
class NotificationApi {
  Dio get _dio => DioClient.instance.dio;

  Future<Map<String, dynamic>> list() => _get('/notifications');

  Future<Map<String, dynamic>> markRead(int id) =>
      _put('/notifications/$id/read', {});

  Future<Map<String, dynamic>> markAllRead() =>
      _put('/notifications/read-all', {});

  Future<void> delete(int id) async {
    try {
      await _dio.delete('/notifications/$id');
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
