import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';

/// Appels HTTP bruts vers les endpoints `admin/*`.
class AdminApi {
  Dio get _dio => DioClient.instance.dio;

  /// `data` est une liste ici (une ligne par propriétaire), pas un objet.
  Future<List<dynamic>> listOwners() => _getList('/admin/owners');

  Future<List<dynamic>> _getList(String path) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(path);
      return (response.data?['data'] as List?) ?? const [];
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
