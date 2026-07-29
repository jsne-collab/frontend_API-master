import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_repository.dart';
import 'owner_overview_model.dart';

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepository(),
);

final adminOwnersProvider =
    AsyncNotifierProvider<AdminOwnersController, List<OwnerOverview>>(
      AdminOwnersController.new,
    );

class AdminOwnersController extends AsyncNotifier<List<OwnerOverview>> {
  @override
  Future<List<OwnerOverview>> build() =>
      ref.read(adminRepositoryProvider).listOwners();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(adminRepositoryProvider).listOwners(),
    );
  }

  /// Voir `OwnerDashboardController.clear` (dashboard/domain/dashboard_provider.dart).
  void clear() {
    state = const AsyncLoading();
  }
}
