import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_provider.dart';
import '../data/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(),
);

final profileControllerProvider = Provider<ProfileController>(
  ProfileController.new,
);

/// Pas de state propre : les écrans gèrent leur `isLoading` local le
/// temps d'une soumission, et le profil à jour est répercuté sur
/// [authControllerProvider] pour rester la seule source de vérité de
/// l'utilisateur courant.
class ProfileController {
  ProfileController(this.ref);

  final Ref ref;

  ProfileRepository get _repository => ref.read(profileRepositoryProvider);

  Future<void> updateProfile(int userId, Map<String, dynamic> data) async {
    final user = await _repository.updateProfile(userId, data);
    ref.read(authControllerProvider.notifier).updateUser(user);
  }

  Future<void> updatePassword(int userId, Map<String, dynamic> data) {
    return _repository.updatePassword(userId, data);
  }

  Future<void> uploadAvatar(int userId, String filePath) async {
    final user = await _repository.uploadAvatar(userId, filePath);
    ref.read(authControllerProvider.notifier).updateUser(user);
  }
}
