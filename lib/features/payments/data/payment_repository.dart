import '../domain/payment_model.dart';
import 'payment_api.dart';

class PaymentRepository {
  PaymentRepository({PaymentApi? api}) : _api = api ?? PaymentApi();

  final PaymentApi _api;

  Future<List<Payment>> listOwn({Map<String, dynamic>? filters}) async {
    final response = await _api.listOwn(filters: filters);
    return _parseItems(response);
  }

  Future<List<Payment>> history({Map<String, dynamic>? filters}) async {
    final response = await _api.history(filters: filters);
    return _parseItems(response);
  }

  Future<PaymentStats> stats({Map<String, dynamic>? filters}) async {
    final response = await _api.stats(filters: filters);
    return PaymentStats.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Payment> show(int id) async {
    final response = await _api.show(id);
    return Payment.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Payment> create(Map<String, dynamic> data) async {
    final response = await _api.create(data);
    return Payment.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Payment> initiate(Map<String, dynamic> data) async {
    final response = await _api.initiate(data);
    return Payment.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Payment> update(int id, Map<String, dynamic> data) async {
    final response = await _api.update(id, data);
    return Payment.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> delete(int id) => _api.delete(id);

  List<Payment> _parseItems(Map<String, dynamic> response) {
    final data = response['data'] as Map<String, dynamic>;
    final items = data['items'] as List;
    return items
        .map((e) => Payment.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
