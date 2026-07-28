import '../domain/message_model.dart';
import 'message_api.dart';

class MessageRepository {
  MessageRepository({MessageApi? api}) : _api = api ?? MessageApi();

  final MessageApi _api;

  Future<List<Conversation>> conversations() async {
    final response = await _api.conversations();
    final items = response['data'] as List;
    return items
        .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ChatMessage>> messages(int otherUserId) async {
    final response = await _api.messages(otherUserId);
    final data = response['data'] as Map<String, dynamic>;
    final items = data['items'] as List;
    return items
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ChatMessage> send({
    required int receiverId,
    required String content,
    int? leaseId,
    int? propertyId,
  }) async {
    final response = await _api.send({
      'receiver_id': receiverId,
      'content': content,
      'lease_id': leaseId,
      'property_id': propertyId,
    });
    return ChatMessage.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> markRead(int id) => _api.markRead(id);

  Future<void> delete(int id) => _api.delete(id);
}
