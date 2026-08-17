import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';

/// URL de base du backend déployé sur Render.
/// Tu peux aussi surcharger avec --dart-define=API_BASE_URL=...
const String _explicitBaseUrl = String.fromEnvironment('API_BASE_URL');
const String _defaultHost = 'https://immo-api-master-8.onrender.com/api/v1/';

class DioClient {
  DioClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _explicitBaseUrl.isNotEmpty ? _explicitBaseUrl : _defaultHost,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    // Intercepteur pour ajouter le token automatiquement
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorage.instance.readToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await SecureStorage.instance.clear();
            onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  static final DioClient instance = DioClient._internal();

  late final Dio _dio;
  Dio get dio => _dio;

  /// Callback déclenché si l’utilisateur est déconnecté (401).
  void Function()? onUnauthorized;
}
