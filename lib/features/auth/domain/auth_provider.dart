import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../dashboard/domain/dashboard_provider.dart';
import '../../expenses/domain/expense_provider.dart';
import '../../leases/domain/lease_provider.dart';
import '../../maintenance/domain/maintenance_provider.dart';
import '../../messaging/domain/message_provider.dart';
import '../../notifications/domain/notification_provider.dart';
import '../../payments/domain/payment_provider.dart';
import '../../properties/domain/property_provider.dart';
import '../../receipts/domain/receipt_provider.dart';
import '../data/auth_repository.dart';
import '../data/google_sign_in_service.dart';
import 'auth_state.dart';
import 'user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);

final googleSignInServiceProvider = Provider<GoogleSignInService>(
  (ref) => GoogleSignInService(),
);

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

/// Détient la session courante (utilisateur connecté / rôle) et orchestre
/// les appels au repository. Les écrans gèrent leur propre `isLoading`
/// local le temps d'une soumission ; ce controller ne porte que l'état
/// de session global consommé par le router (redirections) et l'UI.
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    DioClient.instance.onUnauthorized = () {
      state = const AuthState.unauthenticated();
    };
    return const AuthState.unknown();
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  /// Appelé au démarrage (Splash) : restaure la session si un token valide
  /// est déjà stocké, sinon bascule sur l'écran de connexion.
  ///
  /// Timeout explicite car la lecture du token passe par l'AndroidKeyStore
  /// (`flutter_secure_storage`) : sur certains émulateurs le service Keystore
  /// reste bloqué après un Quick Boot et le Future ne se résout jamais côté
  /// natif (ni succès, ni exception) — sans ce timeout le splash reste figé
  /// indéfiniment, y compris sans le moindre appel réseau.
  Future<void> bootstrap() async {
    try {
      final token = await _repository.readStoredToken().timeout(
        const Duration(seconds: 5),
      );
      if (token == null) {
        state = const AuthState.unauthenticated();
        return;
      }

      final user = await _repository.fetchCurrentUser().timeout(
        const Duration(seconds: 20),
      );
      state = AuthState.authenticated(user);
    } catch (_) {
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> login({required String login, required String password}) async {
    final user = await _repository.login(login: login, password: password);
    _invalidateSessionScopedProviders();
    state = AuthState.authenticated(user);
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
    required UserRole role,
  }) async {
    final user = await _repository.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
      passwordConfirmation: passwordConfirmation,
      role: role,
    );
    _invalidateSessionScopedProviders();
    state = AuthState.authenticated(user);
  }

  Future<void> loginWithGoogle(String idToken) async {
    final user = await _repository.loginWithGoogle(idToken);
    _invalidateSessionScopedProviders();
    state = AuthState.authenticated(user);
  }

  Future<void> completeProfile({
    required UserRole role,
    required String phone,
  }) async {
    final user = await _repository.completeProfile(
      role: role.name,
      phone: phone,
    );
    state = AuthState.authenticated(user);
  }

  Future<void> logout() async {
    await _repository.logout();
    _invalidateSessionScopedProviders();
    state = const AuthState.unauthenticated();
  }

  /// Remplace l'utilisateur en session par une version à jour (ex. après
  /// modification du profil), sans reproduire un login complet.
  void updateUser(User user) {
    state = AuthState.authenticated(user);
  }

  /// Purge les données mises en cache par les `AsyncNotifierProvider` des
  /// autres features (dashboard, biens, baux, paiements, maintenance,
  /// messages, notifications, quittances, dépenses).
  ///
  /// Ces providers ne sont pas `.autoDispose` et ne dépendent pas de
  /// l'utilisateur courant : sans cette purge à chaque connexion/déconnexion,
  /// un second compte connecté sur le même appareil (ex. changer de
  /// locataire pour tester) continue d'afficher les données mises en cache
  /// du compte précédent (bail, loyer, paiements...) tant qu'aucun
  /// pull-to-refresh manuel n'est fait.
  ///
  /// `clear()` est appelé *avant* `invalidate()` : Riverpod garde par défaut
  /// l'ancienne valeur visible (état "loading avec valeur précédente") le
  /// temps du refetch pour lisser un simple pull-to-refresh — mais ici
  /// l'ancienne valeur appartient à un *autre* utilisateur, donc il ne faut
  /// jamais la laisser s'afficher, même une fraction de seconde. `clear()`
  /// vide la valeur avant que `invalidate()` ne déclenche le refetch, pour
  /// qu'il n'y ait plus rien à "garder visible".
  void _invalidateSessionScopedProviders() {
    ref.read(ownerDashboardProvider.notifier).clear();
    ref.read(tenantDashboardProvider.notifier).clear();
    ref.read(myPropertiesProvider.notifier).clear();
    ref.read(myLeasesProvider.notifier).clear();
    ref.read(myPaymentsProvider.notifier).clear();
    ref.read(myMaintenanceRequestsProvider.notifier).clear();
    ref.read(conversationsProvider.notifier).clear();
    ref.read(notificationsProvider.notifier).clear();
    ref.read(myReceiptsProvider.notifier).clear();
    ref.read(myExpensesProvider.notifier).clear();

    ref.invalidate(ownerDashboardProvider);
    ref.invalidate(tenantDashboardProvider);
    ref.invalidate(myPropertiesProvider);
    ref.invalidate(myLeasesProvider);
    ref.invalidate(myPaymentsProvider);
    ref.invalidate(myMaintenanceRequestsProvider);
    ref.invalidate(conversationsProvider);
    ref.invalidate(notificationsProvider);
    ref.invalidate(myReceiptsProvider);
    ref.invalidate(myExpensesProvider);
  }
}
