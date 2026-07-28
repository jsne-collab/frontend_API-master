import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';

/// Appels HTTP bruts vers les endpoints `users/*` liés au profil.
class ProfileApi {
  Dio get _dio => DioClient.instance.dio;

  Future<Map<String, dynamic>> updateProfile(
    int userId,
    Map<String, dynamic> data,
  ) => _put('/users/$userId', data);

  Future<Map<String, dynamic>> updatePassword(
    int userId,
    Map<String, dynamic> data,
  ) => _put('/users/$userId/password', data);

  Future<Map<String, dynamic>> uploadAvatar(int userId, String filePath) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/users/$userId/avatar',
        data: FormData.fromMap({
          'avatar': await MultipartFile.fromFile(filePath),
        }),
      );
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
