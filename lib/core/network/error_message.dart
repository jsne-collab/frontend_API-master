import 'api_exception.dart';

/// Message à afficher pour une erreur capturée par un `AsyncValue`/`.when`.
///
/// [ApiException] porte déjà un message adapté à l'utilisateur (voir
/// `ApiException.fromDioException`) — mais toute erreur qui n'en est pas
/// une (bug de parsing JSON, cast raté...) donnait auparavant un
/// `error.toString()` brut (ex. "type 'Null' is not a subtype of type
/// 'String'"), incompréhensible et peu professionnel pour l'utilisateur
/// final. Ce garde-fou assure qu'il ne voit jamais que du texte en français.
String friendlyErrorMessage(Object error) {
  if (error is ApiException) return error.message;
  return 'Une erreur inattendue est survenue. Réessayez dans un instant.';
}
