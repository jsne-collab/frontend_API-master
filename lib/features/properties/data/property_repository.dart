import '../domain/property_model.dart';
import 'property_api.dart';

class PropertyRepository {
  PropertyRepository({PropertyApi? api}) : _api = api ?? PropertyApi();

  final PropertyApi _api;

  Future<List<Property>> listOwn() async {
    final response = await _api.listOwn();
    return _parseItems(response);
  }

  Future<List<Property>> listAvailable() async {
    final response = await _api.listAvailable();
    return _parseItems(response);
  }

  Future<List<Property>> search(Map<String, dynamic> filters) async {
    final response = await _api.search(filters);
    return _parseItems(response);
  }

  Future<Property> show(int id) async {
    final response = await _api.show(id);
    return Property.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Property> create(Map<String, dynamic> data) async {
    final response = await _api.create(data);
    return Property.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Property> update(int id, Map<String, dynamic> data) async {
    final response = await _api.update(id, data);
    return Property.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> delete(int id) => _api.delete(id);

  Future<Property> uploadImage(
    int propertyId,
    String filePath, {
    bool isPrimary = false,
  }) async {
    final response = await _api.uploadImage(
      propertyId,
      filePath,
      isPrimary: isPrimary,
    );
    return Property.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> deleteImage(int propertyId, int imageId) =>
      _api.deleteImage(propertyId, imageId);

  List<Property> _parseItems(Map<String, dynamic> response) {
    final data = response['data'] as Map<String, dynamic>;
    final items = data['items'] as List;
    return items
        .map((e) => Property.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
