import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_locative/features/notifications/data/notification_api.dart';
import 'package:gestion_locative/features/notifications/data/notification_repository.dart';
import 'package:gestion_locative/features/notifications/domain/notification_provider.dart';
import 'package:gestion_locative/features/notifications/presentation/screens/notifications_screen.dart';

Map<String, dynamic> _notificationJson({
  required int id,
  required bool isRead,
}) {
  return {
    'id': id,
    'type': 'payment_validated',
    'title': 'Paiement validé',
    'message': 'Votre paiement de 150000 FCFA a été validé.',
    'is_read': isRead,
    'created_at': '2026-07-19T00:00:00Z',
  };
}

class _FakeNotificationApi extends NotificationApi {
  int markReadCallCount = 0;
  bool isRead = false;

  @override
  Future<Map<String, dynamic>> list() async {
    return {
      'success': true,
      'message': '',
      'data': {
        'items': [_notificationJson(id: 1, isRead: isRead)],
        'pagination': {
          'current_page': 1,
          'last_page': 1,
          'per_page': 15,
          'total': 1,
        },
      },
    };
  }

  @override
  Future<Map<String, dynamic>> markRead(int id) async {
    markReadCallCount++;
    isRead = true;

    return {
      'success': true,
      'message': 'Notification marquée comme lue.',
      'data': _notificationJson(id: id, isRead: true),
    };
  }
}

class _FakeEmptyNotificationApi extends NotificationApi {
  @override
  Future<Map<String, dynamic>> list() async {
    return {
      'success': true,
      'message': '',
      'data': {
        'items': <Map<String, dynamic>>[],
        'pagination': {
          'current_page': 1,
          'last_page': 1,
          'per_page': 15,
          'total': 0,
        },
      },
    };
  }
}

Widget _wrap(NotificationApi fakeApi) {
  return ProviderScope(
    overrides: [
      notificationRepositoryProvider.overrideWithValue(
        NotificationRepository(api: fakeApi),
      ),
    ],
    child: const MaterialApp(home: NotificationsScreen()),
  );
}

void main() {
  testWidgets('shows the unread notification and marks it read on tap', (
    tester,
  ) async {
    final fakeApi = _FakeNotificationApi();

    await tester.pumpWidget(_wrap(fakeApi));
    await tester.pumpAndSettle();

    expect(find.text('Paiement validé'), findsOneWidget);
    expect(find.text('Tout marquer lu'), findsOneWidget);

    await tester.tap(find.text('Paiement validé'));
    await tester.pumpAndSettle();

    expect(fakeApi.markReadCallCount, 1);
    expect(find.text('Tout marquer lu'), findsNothing);
  });

  testWidgets('shows an empty state when there are no notifications', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_FakeEmptyNotificationApi()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Aucune notification'), findsOneWidget);
  });
}
