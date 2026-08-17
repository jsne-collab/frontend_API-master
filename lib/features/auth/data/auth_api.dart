import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';

/// Appels HTTP bruts vers les 8 endpoints `auth/*` de l'API.
class AuthApi {
  Dio get _dio => DioClient.instance.dio;

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
    required String role,
  }) => _post('auth/register', {
    'name': name,
    'email': email,
    'phone': phone,
    'password': password,
    'password_confirmation': passwordConfirmation,
    'role': role,
    // Le formulaire d'inscription bloque la soumission tant que la case
    // CGU/Politique de confidentialité n'est pas cochée — voir register_screen.dart.
    'terms_accepted': true,
    'privacy_accepted': true,
  });

  Future<Map<String, dynamic>> login({
    required String login,
    required String password,
  }) => _post('auth/login', {'login': login, 'password': password});

  Future<Map<String, dynamic>> google({
    required String idToken,
    String deviceType = 'android',
  }) => _post('auth/google', {'id_token': idToken, 'device_type': deviceType});

  Future<Map<String, dynamic>> completeProfile({
    required String role,
    required String phone,
  }) => _put('auth/complete-profile', {
    'role': role,
    'phone': phone,
    'terms_accepted': true,
    'privacy_accepted': true,
  });

  Future<void> logout() => _post('auth/logout', const {});

  Future<Map<String, dynamic>> refresh() => _post('auth/refresh', const {});

  Future<Map<String, dynamic>> me() => _get('auth/me');

  Future<void> forgotPassword(String email) =>
      _post('auth/forgot-password', {'email': email});

  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) => _post('auth/reset-password', {
    'email': email,
    'token': token,
    'password': password,
    'password_confirmation': passwordConfirmation,
  });

  Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) => _post('auth/verify-email', {'email': email, 'code': code});

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
