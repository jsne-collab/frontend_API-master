import '../domain/maintenance_model.dart';
import 'maintenance_api.dart';

class MaintenanceRepository {
  MaintenanceRepository({MaintenanceApi? api}) : _api = api ?? MaintenanceApi();

  final MaintenanceApi _api;

  Future<List<MaintenanceRequestModel>> listOwn({
    Map<String, dynamic>? filters,
  }) async {
    final response = await _api.listOwn(filters: filters);
    final data = response['data'] as Map<String, dynamic>;
    final items = data['items'] as List;
    return items
        .map((e) => MaintenanceRequestModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MaintenanceRequestModel> show(int id) async {
    final response = await _api.show(id);
    return MaintenanceRequestModel.fromJson(
      response['data'] as Map<String, dynamic>,
    );
  }

  Future<MaintenanceRequestModel> create(
    Map<String, dynamic> data, {
    String? photoPath,
  }) async {
    final response = await _api.create(data, photoPath: photoPath);
    return MaintenanceRequestModel.fromJson(
      response['data'] as Map<String, dynamic>,
    );
  }

  Future<MaintenanceRequestModel> update(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _api.update(id, data);
    return MaintenanceRequestModel.fromJson(
      response['data'] as Map<String, dynamic>,
    );
  }

  Future<void> delete(int id) => _api.delete(id);

  Future<MaintenanceRequestModel> updateStatus(int id, String status) async {
    final response = await _api.updateStatus(id, status);
    return MaintenanceRequestModel.fromJson(
      response['data'] as Map<String, dynamic>,
    );
  }

  Future<MaintenanceRequestModel> addComment(int id, String comment) async {
    final response = await _api.addComment(id, comment);
    return MaintenanceRequestModel.fromJson(
      response['data'] as Map<String, dynamic>,
    );
  }
}
