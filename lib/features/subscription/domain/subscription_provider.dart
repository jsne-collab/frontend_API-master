import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/subscription_repository.dart';
import 'subscription_model.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
  (ref) => SubscriptionRepository(),
);

final subscriptionProvider =
    AsyncNotifierProvider<SubscriptionController, SubscriptionInfo>(
      SubscriptionController.new,
    );

class SubscriptionController extends AsyncNotifier<SubscriptionInfo> {
  @override
  Future<SubscriptionInfo> build() =>
      ref.read(subscriptionRepositoryProvider).show();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(subscriptionRepositoryProvider).show(),
    );
  }

  /// Voir `OwnerDashboardController.clear` (dashboard_provider.dart).
  void clear() {
    state = const AsyncLoading();
  }
}
