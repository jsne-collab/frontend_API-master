import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/domain/user_model.dart';

/// Recherche de locataires pour l'attribution d'un bail (GET
/// /users?role=tenant&search=...), réservée aux propriétaires côté API.
class TenantSearchApi {
  Dio get _dio => DioClient.instance.dio;

  Future<List<User>> search(String query) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/users',
        queryParameters: {'search': query},
      );
      final data = response.data!['data'] as Map<String, dynamic>;
      final items = data['items'] as List;
      return items
          .map((e) => User.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
