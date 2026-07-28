import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_locative/features/auth/data/auth_api.dart';
import 'package:gestion_locative/features/auth/data/auth_repository.dart';
import 'package:gestion_locative/features/auth/domain/auth_provider.dart';
import 'package:gestion_locative/features/auth/domain/auth_state.dart';
import 'package:gestion_locative/features/auth/domain/user_model.dart';
import 'package:gestion_locative/features/auth/presentation/screens/complete_profile_screen.dart';

const _incompleteUser = User(
  id: 5,
  name: 'Awa Google',
  email: 'awa.google@example.com',
  phone: '',
  role: UserRole.tenant,
  profileCompleted: false,
);

class _FakeAuthController extends AuthController {
  @override
  AuthState build() => const AuthState.authenticated(_incompleteUser);
}

class _FakeAuthApi extends AuthApi {
  int completeProfileCallCount = 0;
  Map<String, dynamic>? lastPayload;

  @override
  Future<Map<String, dynamic>> completeProfile({
    required String role,
    required String phone,
  }) async {
    completeProfileCallCount++;
    lastPayload = {'role': role, 'phone': phone};

    return {
      'success': true,
      'message': 'Profil complété avec succès.',
      'data': {
        'id': 5,
        'name': 'Awa Google',
        'email': 'awa.google@example.com',
        'phone': phone,
        'role': role,
        'email_verified_at': '2026-07-20T00:00:00Z',
        'profile_completed': true,
      },
    };
  }
}

Widget _wrap(AuthApi fakeApi) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(_FakeAuthController.new),
      authRepositoryProvider.overrideWithValue(AuthRepository(api: fakeApi)),
    ],
    child: const MaterialApp(home: CompleteProfileScreen()),
  );
}

void main() {
  testWidgets('blocks submission until the terms checkbox is accepted', (
    tester,
  ) async {
    final fakeApi = _FakeAuthApi();

    await tester.pumpWidget(_wrap(fakeApi));
    await tester.pump();

    expect(find.text('Bienvenue Awa, encore une étape'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '+22890001234');
    await tester.ensureVisible(find.text('Terminer mon inscription'));
    await tester.tap(find.text('Terminer mon inscription'));
    await tester.pump();

    expect(fakeApi.completeProfileCallCount, 0);
  });

  testWidgets('submits the role and phone once the terms are accepted', (
    tester,
  ) async {
    final fakeApi = _FakeAuthApi();

    await tester.pumpWidget(_wrap(fakeApi));
    await tester.pump();

    await tester.enterText(find.byType(TextFormField), '+22890001234');
    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    await tester.ensureVisible(find.text('Terminer mon inscription'));
    await tester.tap(find.text('Terminer mon inscription'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(fakeApi.completeProfileCallCount, 1);
    expect(fakeApi.lastPayload?['phone'], '+22890001234');
    expect(fakeApi.lastPayload?['role'], 'tenant');
  });
}
