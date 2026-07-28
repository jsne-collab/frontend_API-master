import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_locative/core/network/api_exception.dart';
import 'package:gestion_locative/features/auth/data/auth_api.dart';
import 'package:gestion_locative/features/auth/data/auth_repository.dart';
import 'package:gestion_locative/features/auth/domain/auth_provider.dart';
import 'package:gestion_locative/features/auth/presentation/screens/login_screen.dart';

class _FakeAuthApi extends AuthApi {
  _FakeAuthApi({this.shouldFail = false});

  final bool shouldFail;
  int loginCallCount = 0;

  @override
  Future<Map<String, dynamic>> login({
    required String login,
    required String password,
  }) async {
    loginCallCount++;

    if (shouldFail) {
      throw const ApiException('Identifiants invalides.');
    }

    return {
      'success': true,
      'message': 'Connexion réussie.',
      'data': {
        'user': {
          'id': 1,
          'name': 'Jean Dupont',
          'email': 'jean@example.com',
          'phone': '+22890000001',
          'role': 'tenant',
          'email_verified_at': null,
        },
        'token': 'fake-token',
      },
    };
  }
}

Widget _wrap(Widget child, {required AuthApi fakeApi}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(AuthRepository(api: fakeApi)),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  testWidgets('shows validation errors when submitting an empty form', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const LoginScreen(), fakeApi: _FakeAuthApi()),
    );

    await tester.tap(find.text('Se connecter'));
    await tester.pump();

    expect(find.text('Ce champ est requis.'), findsNWidgets(2));
  });

  testWidgets('logs in successfully and updates the auth controller state', (
    tester,
  ) async {
    final fakeApi = _FakeAuthApi();

    await tester.pumpWidget(_wrap(const LoginScreen(), fakeApi: fakeApi));

    await tester.enterText(
      find.byType(TextFormField).first,
      'jean@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'Password!234');

    await tester.tap(find.text('Se connecter'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(fakeApi.loginCallCount, 1);
    expect(find.text('Identifiants invalides.'), findsNothing);
  });

  testWidgets('shows the server error message when login fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const LoginScreen(), fakeApi: _FakeAuthApi(shouldFail: true)),
    );

    await tester.enterText(
      find.byType(TextFormField).first,
      'jean@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'wrong-password');

    await tester.tap(find.text('Se connecter'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Identifiants invalides.'), findsOneWidget);
  });
}
