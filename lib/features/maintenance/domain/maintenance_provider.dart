import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/maintenance_repository.dart';
import 'maintenance_model.dart';

final maintenanceRepositoryProvider = Provider<MaintenanceRepository>(
  (ref) => MaintenanceRepository(),
);

final myMaintenanceRequestsProvider =
    AsyncNotifierProvider<
      MyMaintenanceRequestsController,
      List<MaintenanceRequestModel>
    >(MyMaintenanceRequestsController.new);

/// Demandes de maintenance de l'utilisateur connecté (propriétaire : celles
/// sur ses biens ; locataire : les siennes) — le backend applique déjà le
/// bon scope.
class MyMaintenanceRequestsController
    extends AsyncNotifier<List<MaintenanceRequestModel>> {
  @override
  Future<List<MaintenanceRequestModel>> build() =>
      ref.read(maintenanceRepositoryProvider).listOwn();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(maintenanceRepositoryProvider).listOwn(),
    );
  }

  /// Voir `OwnerDashboardController.clear` (dashboard_provider.dart).
  void clear() {
    state = const AsyncLoading();
  }
}

final maintenanceRequestDetailProvider =
    FutureProvider.autoDispose.family<MaintenanceRequestModel, int>((
      ref,
      id,
    ) {
      return ref.watch(maintenanceRepositoryProvider).show(id);
    });
