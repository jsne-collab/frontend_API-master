import '../../auth/domain/user_model.dart';
import 'profile_api.dart';

class ProfileRepository {
  ProfileRepository({ProfileApi? api}) : _api = api ?? ProfileApi();

  final ProfileApi _api;

  Future<User> updateProfile(int userId, Map<String, dynamic> data) async {
    final response = await _api.updateProfile(userId, data);
    return User.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> updatePassword(int userId, Map<String, dynamic> data) {
    return _api.updatePassword(userId, data);
  }

  Future<User> uploadAvatar(int userId, String filePath) async {
    final response = await _api.uploadAvatar(userId, filePath);
    return User.fromJson(response['data'] as Map<String, dynamic>);
  }
}
