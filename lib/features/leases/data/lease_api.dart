import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';

/// Appels HTTP bruts vers les endpoints `leases/*`.
class LeaseApi {
  Dio get _dio => DioClient.instance.dio;

  Future<Map<String, dynamic>> listOwn() => _get('/leases');

  Future<Map<String, dynamic>> show(int id) => _get('/leases/$id');

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) =>
      _post('/leases', data);

  Future<Map<String, dynamic>> update(int id, Map<String, dynamic> data) =>
      _put('/leases/$id', data);

  Future<void> delete(int id) async {
    try {
      await _dio.delete('/leases/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> terminate(int id, {String? terminationDate}) =>
      _post('/leases/$id/terminate', {'termination_date': ?terminationDate});

  Future<Map<String, dynamic>> renew(int id, String endDate) =>
      _post('/leases/$id/renew', {'end_date': endDate});

  Future<Map<String, dynamic>> download(int id) => _get('/leases/$id/download');

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
