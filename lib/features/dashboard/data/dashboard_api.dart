import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';

/// Appels HTTP bruts vers les endpoints `dashboard/*`.
class DashboardApi {
  Dio get _dio => DioClient.instance.dio;

  Future<Map<String, dynamic>> owner() => _get('/dashboard/owner');

  Future<Map<String, dynamic>> tenant() => _get('/dashboard/tenant');

  Future<Map<String, dynamic>> revenue() => _get('/dashboard/revenue');

  Future<Map<String, dynamic>> occupancy() => _get('/dashboard/occupancy');

  Future<Map<String, dynamic>> _get(String path) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(path);
      return response.data ?? const {};
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
