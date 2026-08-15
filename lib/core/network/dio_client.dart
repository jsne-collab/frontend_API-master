import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';

const String _explicitBaseUrl = String.fromEnvironment('API_BASE_URL');

/// Hôte par défaut (backend déployé en production).
const String _candidateHost = 'https://immo-api-master-8.onrender.com/';

/// client HTTP quon utilise pour faire des requetes HTTP vers le backend. Il est basé sur la librairie Dio et est configuré avec l'URL de base, les délais de connexion et de réception, et les en-têtes par défaut. Il gère également l'ajout du token d'authentification aux requêtes et la gestion des erreurs 401 (non autorisé) en effaçant le token stocké et en appelant un callback.
class DioClient {
  ///On définit une classe DioClient. Elle sert à centraliser la configuration et l’utilisation du client HTTP Dio dans ton application.
  DioClient._internal() {
    ///C’est un constructeur privé (avec _internal).
    //Ça veut dire qu’on ne peut pas créer directement un DioClient avec new DioClient().
    //On force l’utilisation d’une instance unique.
    _dio = Dio(
      BaseOptions(
        baseUrl: _explicitBaseUrl.isNotEmpty
            ? _explicitBaseUrl
            : '$_candidateHost/api/v1',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Accept': 'application/json'},
      ),
    );

    ///Les intercepteurs permettent de modifier ou contrôler les requêtes et réponses avant qu’elles ne soient envoyées ou reçues.
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

  void Function()? onUnauthorized;

  /// Vérifie si le serveur répond et ajuste l’URL si besoin.
  Future<void> resolveServer() async {
    if (_explicitBaseUrl.isNotEmpty) return;

    final probe = Dio(
      BaseOptions(
        connectTimeout: const Duration(milliseconds: 1200),
        receiveTimeout: const Duration(milliseconds: 1200),
        validateStatus: (_) => true,
      ),
    );

    try {
      await probe.get('$_candidateHost/api/v1');
      _dio.options.baseUrl = '$_candidateHost/api/v1';
      return;
    } on DioException {
      // Si le serveur ne répond pas, on garde l’URL par défaut.
      return;
    }
  }
}
