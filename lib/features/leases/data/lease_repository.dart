import '../domain/lease_model.dart';
import 'lease_api.dart';

class LeaseRepository {
  LeaseRepository({LeaseApi? api}) : _api = api ?? LeaseApi();

  final LeaseApi _api;

  Future<List<Lease>> listOwn() async {
    final response = await _api.listOwn();
    final data = response['data'] as Map<String, dynamic>;
    final items = data['items'] as List;
    return items.map((e) => Lease.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Lease> show(int id) async {
    final response = await _api.show(id);
    return Lease.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Lease> create(Map<String, dynamic> data) async {
    final response = await _api.create(data);
    return Lease.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Lease> update(int id, Map<String, dynamic> data) async {
    final response = await _api.update(id, data);
    return Lease.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> delete(int id) => _api.delete(id);

  Future<Lease> terminate(int id, {String? terminationDate}) async {
    final response = await _api.terminate(id, terminationDate: terminationDate);
    return Lease.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Lease> renew(int id, String endDate) async {
    final response = await _api.renew(id, endDate);
    return Lease.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<String> downloadUrl(int id) async {
    final response = await _api.download(id);
    return (response['data'] as Map<String, dynamic>)['url'] as String;
  }
}
