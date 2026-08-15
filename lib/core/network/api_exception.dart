import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.fieldErrors = const {}});

  /// Crée une instance d'API à partir d'une [DioException]
  factory ApiException.fromDioException(DioException error) {
    final data = error.response?.data;

    ///recuper
    ///si la reponse est un objet json, on  recupere le message  les erreurs  et on recupere les champd'erreurs
    if (data is Map<String, dynamic>) {
      final message = data['message'] as String?;
      final errors = data['errors'];
      final fieldErrors = <String, List<String>>{};

      /// on parcours la liste
      if (errors is Map<String, dynamic>) {
        ///et on recupere les erreurs de chaque champ
        for (final entry in errors.entries) {
          final value = entry.value;
          if (value is List) {
            fieldErrors[entry.key] = value.map((e) => e.toString()).toList();
          }
        }
      }

      /// si le message n'est pas null et n'est pas vide, on retourne une exception avec le message et les erreurs de champ
      if (message != null && message.isNotEmpty) {
        return ApiException(message, fieldErrors: fieldErrors);
      }
/// si le message est null ou vide, mais qu'il y a des erreurs de champ, on retourne une exception avec la première erreur de champ
      if (fieldErrors.isNotEmpty) {
        return ApiException(
          fieldErrors.values.first.first,
          fieldErrors: fieldErrors,
        );
      }
    }
/// si la reponse n'est pas un objet json, on retourne une exception . 
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return const ApiException(
        'Impossible de contacter le serveur. Vérifiez votre connexion.',
      );
    }

    return const ApiException('Une erreur inattendue est survenue.');
  }
/// Le message d'erreur à afficher à l'utilisateur
  final String message;
  final Map<String, List<String>> fieldErrors;
/// Retourne une représentation textuelle de l'exception
  @override
  String toString() => message;
}
