import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';

/// Appels HTTP bruts vers les endpoints `receipts/*`.
class ReceiptApi {
  Dio get _dio => DioClient.instance.dio;

  Future<Map<String, dynamic>> listOwn() => _get('/receipts');

  Future<Map<String, dynamic>> show(int id) => _get('/receipts/$id');

  Future<Map<String, dynamic>> download(int id) =>
      _get('/receipts/$id/download');

  Future<Map<String, dynamic>> _get(String path) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(path);
      return response.data ?? const {};
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
