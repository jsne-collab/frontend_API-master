import 'package:dio/dio.dart';

import '../storage/secure_storage.dart';

/// Override explicite, seulement si fourni via `--dart-define=API_BASE_URL=...`
/// (utile pour pointer vers un serveur distant/staging). Sinon vide : le
/// serveur est détecté automatiquement au démarrage par [DioClient.resolveServer].
const String _explicitBaseUrl = String.fromEnvironment('API_BASE_URL');

/// Hôtes candidats testés dans l'ordre au démarrage pour trouver le serveur
/// local, sans dépendre d'une IP Wi-Fi qui change à chaque changement de
/// réseau (voir CLAUDE.md D.4 pour l'historique du problème) :
/// - `10.0.2.2` : alias spécial de l'émulateur Android vers l'hôte (PC),
///   fonctionne quel que soit le Wi-Fi du PC.
/// - `127.0.0.1` : appareil physique via `adb reverse tcp:8000 tcp:8000`
///   (tunnel USB), fonctionne aussi quel que soit le Wi-Fi tant que le
///   câble est branché — voir le watcher qui l'exécute automatiquement.
/*const List<String> _candidateHosts = [
  //'http://10.0.2.2:8000',
  'https://immo.defconenterprise.com',
];*/

const String _candidateHosts = 'https://immo.defconenterprise.com';
/// Client HTTP unique de l'application, avec injection automatique du token
/// et notification centralisée des 401 (session expirée).
class DioClient {
  DioClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _explicitBaseUrl.isNotEmpty
            ? _explicitBaseUrl
            : '${_candidateHosts.first}/api/v1',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Accept': 'application/json'},
      ),
    );

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

  /// Callback branché par le provider d'authentification pour rediriger
  /// vers /login lorsqu'une session expire (401).
  void Function()? onUnauthorized;

  /// Sonde les hôtes candidats et retient le premier qui répond réellement,
  /// pour ne plus jamais dépendre d'une IP Wi-Fi codée en dur. À appeler une
  /// fois au démarrage de l'app (avant `runApp`). Ne fait rien si
  /// `API_BASE_URL` a été fourni explicitement via `--dart-define`.
  Future<void> resolveServer() async {
    if (_explicitBaseUrl.isNotEmpty) return;

    final probe = Dio(
      BaseOptions(
        connectTimeout: const Duration(milliseconds: 1200),
        receiveTimeout: const Duration(milliseconds: 1200),
        validateStatus: (_) => true,
      ),
    );

    /*for (final host in _candidateHosts) {
      try {
        await probe.get('$host/api/v1');
        _dio.options.baseUrl = '$host/api/v1';
        return;
      } on DioException {
        continue;
      }
    }*/
	
	try {
        await probe.get('$_candidateHosts/api/v1');
        _dio.options.baseUrl = '$_candidateHosts/api/v1';
        return;
      } on DioException {
        continue;
      }
	
	
    // Aucun candidat n'a répondu (ex : device physique sans câble/adb
    // reverse) : on garde le premier par défaut, l'appel réel échouera
    // avec un message clair plutôt que de deviner une IP Wi-Fi.
  }
}
