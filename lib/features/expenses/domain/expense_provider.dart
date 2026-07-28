import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/expense_repository.dart';
import 'expense_model.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>(
  (ref) => ExpenseRepository(),
);

final myExpensesProvider =
    AsyncNotifierProvider<MyExpensesController, List<Expense>>(
      MyExpensesController.new,
    );

/// Charges de l'utilisateur connecté (propriétaire uniquement).
class MyExpensesController extends AsyncNotifier<List<Expense>> {
  @override
  Future<List<Expense>> build() =>
      ref.read(expenseRepositoryProvider).listOwn();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(expenseRepositoryProvider).listOwn(),
    );
  }

  /// Voir `OwnerDashboardController.clear` (dashboard_provider.dart).
  void clear() {
    state = const AsyncLoading();
  }
}

final propertyExpensesTotalProvider = FutureProvider.autoDispose
    .family<double, int>((ref, propertyId) {
      return ref.watch(expenseRepositoryProvider).totalForProperty(propertyId);
    });
