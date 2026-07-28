import 'package:google_sign_in/google_sign_in.dart';

/// Fine couche autour de `google_sign_in` : ne récupère qu'un idToken,
/// jamais de logique métier ici — le backend est la seule source de
/// vérité (vérifie le jeton, décide de créer/lier/retrouver le compte).
class GoogleSignInService {
  GoogleSignInService() : _googleSignIn = GoogleSignIn(scopes: const ['email']);

  final GoogleSignIn _googleSignIn;

  /// Retourne l'idToken Google, ou `null` si l'utilisateur annule.
  Future<String?> signIn() async {
    final account = await _googleSignIn.signIn();
    if (account == null) return null;

    final auth = await account.authentication;
    return auth.idToken;
  }

  Future<void> signOut() => _googleSignIn.signOut();
}
