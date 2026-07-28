import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_locative/features/auth/domain/auth_provider.dart';
import 'package:gestion_locative/features/auth/domain/auth_state.dart';
import 'package:gestion_locative/features/auth/domain/user_model.dart';
import 'package:gestion_locative/features/messaging/data/message_api.dart';
import 'package:gestion_locative/features/messaging/data/message_repository.dart';
import 'package:gestion_locative/features/messaging/domain/message_provider.dart';
import 'package:gestion_locative/features/messaging/presentation/screens/message_thread_screen.dart';

const _ownerUser = User(
  id: 1,
  name: 'Jean Owner',
  email: 'owner@example.com',
  phone: '+22890000001',
  role: UserRole.owner,
);

class _FakeAuthController extends AuthController {
  @override
  AuthState build() => const AuthState.authenticated(_ownerUser);
}

Map<String, dynamic> _messageJson({
  required int id,
  required int senderId,
  required String content,
}) {
  return {
    'id': id,
    'sender': {
      'id': senderId,
      'name': senderId == 1 ? 'Jean Owner' : 'Awa Koffi',
      'role': senderId == 1 ? 'owner' : 'tenant',
    },
    'receiver': {
      'id': senderId == 1 ? 2 : 1,
      'name': senderId == 1 ? 'Awa Koffi' : 'Jean Owner',
      'role': senderId == 1 ? 'tenant' : 'owner',
    },
    'lease_id': 7,
    'property_id': 3,
    'content': content,
    'is_read': false,
    'created_at': '2026-07-19T00:00:00Z',
  };
}

class _FakeMessageApi extends MessageApi {
  int sendCallCount = 0;
  Map<String, dynamic>? lastPayload;
  final List<Map<String, dynamic>> _messages = [];

  @override
  Future<Map<String, dynamic>> messages(int otherUserId) async {
    return {
      'success': true,
      'message': '',
      'data': {
        'items': List<Map<String, dynamic>>.from(_messages),
        'pagination': {
          'current_page': 1,
          'last_page': 1,
          'per_page': 50,
          'total': _messages.length,
        },
      },
    };
  }

  @override
  Future<Map<String, dynamic>> send(Map<String, dynamic> data) async {
    sendCallCount++;
    lastPayload = data;

    final message = _messageJson(
      id: _messages.length + 1,
      senderId: 1,
      content: data['content'] as String,
    );
    _messages.add(message);

    return {
      'success': true,
      'message': 'Message envoyé avec succès.',
      'data': message,
    };
  }
}

Widget _wrap(MessageApi fakeApi) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(_FakeAuthController.new),
      messageRepositoryProvider.overrideWithValue(
        MessageRepository(api: fakeApi),
      ),
    ],
    child: const MaterialApp(
      home: MessageThreadScreen(otherUserId: 2, otherUserName: 'Awa Koffi'),
    ),
  );
}

void main() {
  testWidgets('shows an empty state when there are no messages yet', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_FakeMessageApi()));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Aucun message'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('sends a message and displays it in the thread', (tester) async {
    final fakeApi = _FakeMessageApi();

    await tester.pumpWidget(_wrap(fakeApi));
    await tester.pump();
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'Bonjour, tout va bien ?');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(fakeApi.sendCallCount, 1);
    expect(fakeApi.lastPayload?['receiver_id'], 2);
    expect(fakeApi.lastPayload?['content'], 'Bonjour, tout va bien ?');
    expect(find.text('Bonjour, tout va bien ?'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
