import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/property_repository.dart';
import 'property_model.dart';

final propertyRepositoryProvider = Provider<PropertyRepository>(
  (ref) => PropertyRepository(),
);

final myPropertiesProvider =
    AsyncNotifierProvider<MyPropertiesController, List<Property>>(
      MyPropertiesController.new,
    );

/// Liste des biens du propriétaire connecté. `refresh()` est appelé après
/// création/modification/suppression d'un bien pour garder la liste à jour.
class MyPropertiesController extends AsyncNotifier<List<Property>> {
  @override
  Future<List<Property>> build() =>
      ref.read(propertyRepositoryProvider).listOwn();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(propertyRepositoryProvider).listOwn(),
    );
  }

  /// Voir `OwnerDashboardController.clear` (dashboard_provider.dart) : évite
  /// qu'un changement de compte affiche brièvement les biens du précédent
  /// utilisateur pendant que `ref.invalidate` refetch.
  void clear() {
    state = const AsyncLoading();
  }
}

/// Détail d'un bien (avec galerie complète), rechargé à la demande via
/// `ref.invalidate(propertyDetailProvider(id))`.
final propertyDetailProvider = FutureProvider.autoDispose.family<Property, int>(
  (ref, id) {
    return ref.watch(propertyRepositoryProvider).show(id);
  },
);
