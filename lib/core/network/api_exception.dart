import 'package:dio/dio.dart';

/// Erreur API normalisée à partir d'une [DioException], avec un message
/// prêt à afficher et le détail des erreurs de validation par champ.
class ApiException implements Exception {
  const ApiException(this.message, {this.fieldErrors = const {}});

  factory ApiException.fromDioException(DioException error) {
    final data = error.response?.data;

    if (data is Map<String, dynamic>) {
      final message = data['message'] as String?;
      final errors = data['errors'];
      final fieldErrors = <String, List<String>>{};

      if (errors is Map<String, dynamic>) {
        for (final entry in errors.entries) {
          final value = entry.value;
          if (value is List) {
            fieldErrors[entry.key] = value.map((e) => e.toString()).toList();
          }
        }
      }

      if (message != null && message.isNotEmpty) {
        return ApiException(message, fieldErrors: fieldErrors);
      }

      if (fieldErrors.isNotEmpty) {
        return ApiException(
          fieldErrors.values.first.first,
          fieldErrors: fieldErrors,
        );
      }
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return const ApiException(
        'Impossible de contacter le serveur. Vérifiez votre connexion.',
      );
    }

    return const ApiException('Une erreur inattendue est survenue.');
  }

  final String message;
  final Map<String, List<String>> fieldErrors;

  @override
  String toString() => message;
}
