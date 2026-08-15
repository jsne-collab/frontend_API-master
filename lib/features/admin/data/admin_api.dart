import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';

/// Appels HTTP bruts vers les endpoints `admin/*`.
class AdminApi {
  Dio get _dio => DioClient.instance.dio;

  Future<List<dynamic>> listOwners() => _getList('/admin/owners');

  Future<Map<String, dynamic>> showOwner(int ownerId) =>
      _get('/admin/owners/$ownerId');

  Future<Map<String, dynamic>> validateSubscription(int subscriptionId) =>
      _put('/admin/subscriptions/$subscriptionId/validate');

  Future<List<dynamic>> _getList(String path) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(path);
      return (response.data?['data'] as List?) ?? const [];
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

  Future<Map<String, dynamic>> _put(String path) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(path);
      return response.data ?? const {};
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
