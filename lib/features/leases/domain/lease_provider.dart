import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/lease_repository.dart';
import '../data/tenant_search_api.dart';
import 'lease_model.dart';

final leaseRepositoryProvider = Provider<LeaseRepository>(
  (ref) => LeaseRepository(),
);

final tenantSearchApiProvider = Provider<TenantSearchApi>(
  (ref) => TenantSearchApi(),
);

final myLeasesProvider = AsyncNotifierProvider<MyLeasesController, List<Lease>>(
  MyLeasesController.new,
);

/// Baux de l'utilisateur connecté (propriétaire : tous ses baux ; locataire :
/// les siens) — le backend applique déjà le bon scope.
class MyLeasesController extends AsyncNotifier<List<Lease>> {
  @override
  Future<List<Lease>> build() => ref.read(leaseRepositoryProvider).listOwn();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(leaseRepositoryProvider).listOwn(),
    );
  }

  /// Voir `OwnerDashboardController.clear` (dashboard_provider.dart).
  void clear() {
    state = const AsyncLoading();
  }
}

final leaseDetailProvider = FutureProvider.autoDispose.family<Lease, int>((
  ref,
  id,
) {
  return ref.watch(leaseRepositoryProvider).show(id);
});
