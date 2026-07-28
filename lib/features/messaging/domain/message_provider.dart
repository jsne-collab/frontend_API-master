import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/message_repository.dart';
import 'message_model.dart';

final messageRepositoryProvider = Provider<MessageRepository>(
  (ref) => MessageRepository(),
);

final conversationsProvider =
    AsyncNotifierProvider<ConversationsController, List<Conversation>>(
      ConversationsController.new,
    );

/// Conversations de l'utilisateur connecté, dérivées des messages côté
/// backend (pas de table dédiée).
class ConversationsController extends AsyncNotifier<List<Conversation>> {
  @override
  Future<List<Conversation>> build() =>
      ref.read(messageRepositoryProvider).conversations();

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(messageRepositoryProvider).conversations(),
    );
  }

  /// Voir `OwnerDashboardController.clear` (dashboard_provider.dart).
  void clear() {
    state = const AsyncLoading();
  }
}

final threadProvider = FutureProvider.autoDispose.family<List<ChatMessage>, int>((
  ref,
  otherUserId,
) {
  return ref.watch(messageRepositoryProvider).messages(otherUserId);
});
