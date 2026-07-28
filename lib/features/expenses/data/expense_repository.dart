import '../domain/expense_model.dart';
import 'expense_api.dart';

class ExpenseRepository {
  ExpenseRepository({ExpenseApi? api}) : _api = api ?? ExpenseApi();

  final ExpenseApi _api;

  Future<List<Expense>> listOwn({Map<String, dynamic>? filters}) async {
    final response = await _api.listOwn(filters: filters);
    final data = response['data'] as Map<String, dynamic>;
    final items = data['items'] as List;
    return items
        .map((e) => Expense.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Expense> show(int id) async {
    final response = await _api.show(id);
    return Expense.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Expense> create(Map<String, dynamic> data) async {
    final response = await _api.create(data);
    return Expense.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Expense> update(int id, Map<String, dynamic> data) async {
    final response = await _api.update(id, data);
    return Expense.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> delete(int id) => _api.delete(id);

  /// Solde net d'un bien (revenus validés - charges), calculé côté client
  /// à partir des paiements/charges filtrés par bien — pas de route
  /// dédiée côté backend, le calcul sera affiché dans le tableau de bord
  /// propriétaire (Phase 11).
  Future<double> totalForProperty(int propertyId) async {
    final expenses = await listOwn(filters: {'property_id': propertyId});
    return expenses.fold<double>(0, (sum, expense) => sum + expense.amount);
  }
}
