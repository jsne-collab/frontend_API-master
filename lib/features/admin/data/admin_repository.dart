import '../domain/owner_overview_model.dart';
import 'admin_api.dart';

class AdminRepository {
  AdminRepository({AdminApi? api}) : _api = api ?? AdminApi();

  final AdminApi _api;

  Future<List<OwnerOverview>> listOwners() async {
    final items = await _api.listOwners();
    return items
        .map((e) => OwnerOverview.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
