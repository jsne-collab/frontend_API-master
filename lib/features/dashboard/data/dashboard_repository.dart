import '../domain/dashboard_model.dart';
import 'dashboard_api.dart';

class DashboardRepository {
  DashboardRepository({DashboardApi? api}) : _api = api ?? DashboardApi();

  final DashboardApi _api;

  Future<OwnerDashboard> owner() async {
    final response = await _api.owner();
    return OwnerDashboard.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<TenantDashboard> tenant() async {
    final response = await _api.tenant();
    return TenantDashboard.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<List<RevenuePoint>> revenue() async {
    final response = await _api.revenue();
    final items = response['data'] as List;
    return items
        .map((e) => RevenuePoint.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Occupancy> occupancy() async {
    final response = await _api.occupancy();
    return Occupancy.fromJson(response['data'] as Map<String, dynamic>);
  }
}
