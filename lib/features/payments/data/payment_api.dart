import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';

/// Appels HTTP bruts vers les endpoints `payments/*`.
class PaymentApi {
  Dio get _dio => DioClient.instance.dio;

  Future<Map<String, dynamic>> listOwn({Map<String, dynamic>? filters}) =>
      _get('/payments', query: filters);

  Future<Map<String, dynamic>> history({Map<String, dynamic>? filters}) =>
      _get('/payments/history', query: filters);

  Future<Map<String, dynamic>> stats({Map<String, dynamic>? filters}) =>
      _get('/payments/stats', query: filters);

  Future<Map<String, dynamic>> show(int id) => _get('/payments/$id');

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) =>
      _post('/payments', data);

  Future<Map<String, dynamic>> initiate(Map<String, dynamic> data) =>
      _post('/payments/initiate', data);

  Future<Map<String, dynamic>> update(int id, Map<String, dynamic> data) =>
      _put('/payments/$id', data);

  Future<void> delete(int id) async {
    try {
      await _dio.delete('/payments/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: query,
      );
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
