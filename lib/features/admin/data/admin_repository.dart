import '../domain/owner_detail_model.dart';
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

  Future<OwnerDetail> showOwner(int ownerId) async {
    final response = await _api.showOwner(ownerId);
    return OwnerDetail.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> validateSubscription(int subscriptionId) =>
      _api.validateSubscription(subscriptionId);
}
