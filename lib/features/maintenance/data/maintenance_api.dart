import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';

/// Appels HTTP bruts vers les endpoints `maintenance-requests/*`.
class MaintenanceApi {
  Dio get _dio => DioClient.instance.dio;

  Future<Map<String, dynamic>> listOwn({Map<String, dynamic>? filters}) =>
      _get('maintenance-requests', query: filters);

  Future<Map<String, dynamic>> show(int id) => _get('maintenance-requests/$id');

  Future<Map<String, dynamic>> create(
    Map<String, dynamic> data, {
    String? photoPath,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'maintenance-requests',
        data: photoPath != null
            ? FormData.fromMap({
                ...data,
                'photo': await MultipartFile.fromFile(photoPath),
              })
            : data,
      );
      return response.data ?? const {};
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> update(int id, Map<String, dynamic> data) =>
      _put('maintenance-requests/$id', data);

  Future<void> delete(int id) async {
    try {
      await _dio.delete('maintenance-requests/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> updateStatus(int id, String status) =>
      _put('maintenance-requests/$id/status', {'status': status});

  Future<Map<String, dynamic>> addComment(int id, String comment) =>
      _post('maintenance-requests/$id/comments', {'comment': comment});

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
