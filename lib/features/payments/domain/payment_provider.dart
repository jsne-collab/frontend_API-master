import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/payment_repository.dart';
import 'payment_model.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => PaymentRepository(),
);

final myPaymentsProvider =
    AsyncNotifierProvider<MyPaymentsController, List<Payment>>(
      MyPaymentsController.new,
    );

/// Paiements de l'utilisateur connecté (propriétaire : ses biens ;
/// locataire : les siens) — sert à la fois d'écran "Liste" et
/// "Historique", le backend renvoyant déjà l'ensemble chronologique.
class MyPaymentsController extends AsyncNotifier<List<Payment>> {
  @override
  Future<List<Payment>> build() =>
      ref.read(paymentRepositoryProvider).listOwn();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(paymentRepositoryProvider).listOwn(),
    );
  }

  /// Voir `OwnerDashboardController.clear` (dashboard_provider.dart).
  void clear() {
    state = const AsyncLoading();
  }
}

final paymentStatsProvider = FutureProvider.autoDispose<PaymentStats>((ref) {
  return ref.watch(paymentRepositoryProvider).stats();
});

final paymentDetailProvider = FutureProvider.autoDispose.family<Payment, int>((
  ref,
  id,
) {
  return ref.watch(paymentRepositoryProvider).show(id);
});
