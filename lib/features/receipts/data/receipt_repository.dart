import '../domain/receipt_model.dart';
import 'receipt_api.dart';

class ReceiptRepository {
  ReceiptRepository({ReceiptApi? api}) : _api = api ?? ReceiptApi();

  final ReceiptApi _api;

  Future<List<Receipt>> listOwn() async {
    final response = await _api.listOwn();
    final data = response['data'] as Map<String, dynamic>;
    final items = data['items'] as List;
    return items
        .map((e) => Receipt.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Receipt> show(int id) async {
    final response = await _api.show(id);
    return Receipt.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<String> downloadUrl(int id) async {
    final response = await _api.download(id);
    return (response['data'] as Map<String, dynamic>)['url'] as String;
  }
}
