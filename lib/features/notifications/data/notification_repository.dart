import '../domain/notification_model.dart';
import 'notification_api.dart';

class NotificationRepository {
  NotificationRepository({NotificationApi? api})
    : _api = api ?? NotificationApi();

  final NotificationApi _api;

  Future<List<AppNotification>> list() async {
    final response = await _api.list();
    final data = response['data'] as Map<String, dynamic>;
    final items = data['items'] as List;
    return items
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AppNotification> markRead(int id) async {
    final response = await _api.markRead(id);
    return AppNotification.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> markAllRead() => _api.markAllRead();

  Future<void> delete(int id) => _api.delete(id);
}
