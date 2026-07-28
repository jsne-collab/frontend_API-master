import '../../../core/storage/secure_storage.dart';
import '../domain/user_model.dart';
import 'auth_api.dart';

/// Couche repository : orchestre [AuthApi] + [SecureStorage], et convertit
/// les réponses JSON en modèles de domaine.
class AuthRepository {
  AuthRepository({AuthApi? api}) : _api = api ?? AuthApi();

  final AuthApi _api;

  Future<User> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
    required UserRole role,
  }) async {
    final data = await _api.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
      passwordConfirmation: passwordConfirmation,
      role: role.name,
    );

    return _persistSession(data);
  }

  Future<User> login({required String login, required String password}) async {
    final data = await _api.login(login: login, password: password);
    return _persistSession(data);
  }

  Future<User> loginWithGoogle(String idToken) async {
    final data = await _api.google(idToken: idToken);
    return _persistSession(data);
  }

  Future<User> completeProfile({
    required String role,
    required String phone,
  }) async {
    final data = await _api.completeProfile(role: role, phone: phone);
    final user = User.fromJson(data['data'] as Map<String, dynamic>);
    await SecureStorage.instance.saveRole(user.role.name);
    return user;
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } finally {
      await SecureStorage.instance.clear();
    }
  }

  Future<User> fetchCurrentUser() async {
    final data = await _api.me();
    return User.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> forgotPassword(String email) => _api.forgotPassword(email);

  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) => _api.resetPassword(
    email: email,
    token: token,
    password: password,
    passwordConfirmation: passwordConfirmation,
  );

  Future<User> verifyEmail({
    required String email,
    required String code,
  }) async {
    final data = await _api.verifyEmail(email: email, code: code);
    return User.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<String?> readStoredToken() => SecureStorage.instance.readToken();

  Future<User> _persistSession(Map<String, dynamic> data) async {
    final payload = data['data'] as Map<String, dynamic>;
    final user = User.fromJson(payload['user'] as Map<String, dynamic>);
    final token = payload['token'] as String;

    await SecureStorage.instance.saveToken(token);
    await SecureStorage.instance.saveRole(user.role.name);

    return user;
  }
}
