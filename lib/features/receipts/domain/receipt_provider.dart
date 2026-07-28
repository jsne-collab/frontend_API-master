import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/receipt_repository.dart';
import 'receipt_model.dart';

final receiptRepositoryProvider = Provider<ReceiptRepository>(
  (ref) => ReceiptRepository(),
);

final myReceiptsProvider =
    AsyncNotifierProvider<MyReceiptsController, List<Receipt>>(
      MyReceiptsController.new,
    );

class MyReceiptsController extends AsyncNotifier<List<Receipt>> {
  @override
  Future<List<Receipt>> build() =>
      ref.read(receiptRepositoryProvider).listOwn();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(receiptRepositoryProvider).listOwn(),
    );
  }

  /// Voir `OwnerDashboardController.clear` (dashboard_provider.dart).
  void clear() {
    state = const AsyncLoading();
  }
}
