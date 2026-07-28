import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/dashboard_repository.dart';
import 'dashboard_model.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(),
);

final ownerDashboardProvider =
    AsyncNotifierProvider<OwnerDashboardController, OwnerDashboard>(
      OwnerDashboardController.new,
    );

class OwnerDashboardController extends AsyncNotifier<OwnerDashboard> {
  @override
  Future<OwnerDashboard> build() =>
      ref.read(dashboardRepositoryProvider).owner();

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(dashboardRepositoryProvider).owner(),
    );
  }

  /// Efface la valeur en cache sans en refetcher une nouvelle — appelé au
  /// login/logout (voir `AuthController`) pour qu'un changement de compte
  /// n'affiche jamais, même une fraction de seconde, les données du
  /// précédent utilisateur pendant que `ref.invalidate` refetch.
  void clear() {
    state = const AsyncLoading();
  }
}

final tenantDashboardProvider =
    AsyncNotifierProvider<TenantDashboardController, TenantDashboard>(
      TenantDashboardController.new,
    );

class TenantDashboardController extends AsyncNotifier<TenantDashboard> {
  @override
  Future<TenantDashboard> build() =>
      ref.read(dashboardRepositoryProvider).tenant();

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(dashboardRepositoryProvider).tenant(),
    );
  }

  /// Voir [OwnerDashboardController.clear].
  void clear() {
    state = const AsyncLoading();
  }
}

final revenueChartProvider = FutureProvider.autoDispose<List<RevenuePoint>>((
  ref,
) {
  return ref.watch(dashboardRepositoryProvider).revenue();
});

final occupancyProvider = FutureProvider.autoDispose<Occupancy>((ref) {
  return ref.watch(dashboardRepositoryProvider).occupancy();
});
