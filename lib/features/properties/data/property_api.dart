import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';

/// Appels HTTP bruts vers les endpoints `properties/*`.
class PropertyApi {
  Dio get _dio => DioClient.instance.dio;

  Future<Map<String, dynamic>> listOwn() => _get('/properties');

  Future<Map<String, dynamic>> listAvailable() => _get('/properties/available');

  Future<Map<String, dynamic>> search(Map<String, dynamic> filters) =>
      _get('/properties/search', query: filters);

  Future<Map<String, dynamic>> show(int id) => _get('/properties/$id');

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) =>
      _post('/properties', data);

  Future<Map<String, dynamic>> update(int id, Map<String, dynamic> data) =>
      _put('/properties/$id', data);

  Future<void> delete(int id) async {
    try {
      await _dio.delete('/properties/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> uploadImage(
    int propertyId,
    String filePath, {
    bool isPrimary = false,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/properties/$propertyId/images',
        data: FormData.fromMap({
          'image': await MultipartFile.fromFile(filePath),
          'is_primary': isPrimary ? '1' : '0',
        }),
      );
      return response.data ?? const {};
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> deleteImage(int propertyId, int imageId) async {
    try {
      await _dio.delete('/properties/$propertyId/images/$imageId');
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
