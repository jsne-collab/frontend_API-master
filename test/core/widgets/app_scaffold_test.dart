import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_locative/core/widgets/app_scaffold.dart';
import 'package:gestion_locative/features/auth/domain/auth_provider.dart';
import 'package:gestion_locative/features/auth/domain/auth_state.dart';
import 'package:gestion_locative/features/auth/domain/user_model.dart';

const _ownerUser = User(
  id: 1,
  name: 'Jean Owner',
  email: 'owner@example.com',
  phone: '+22890000001',
  role: UserRole.owner,
);

const _tenantUser = User(
  id: 2,
  name: 'Awa Koffi',
  email: 'tenant@example.com',
  phone: '+22890000002',
  role: UserRole.tenant,
);

class _FakeAuthController extends AuthController {
  _FakeAuthController(this.user);

  final User user;

  @override
  AuthState build() => AuthState.authenticated(user);
}

Widget _wrap(User user, String currentRoute) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(() => _FakeAuthController(user)),
    ],
    child: MaterialApp(
      home: AppScaffold(
        currentRoute: currentRoute,
        appBar: AppBar(title: const Text('Test')),
        body: const SizedBox(),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the owner tabs with the right one selected', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_ownerUser, '/properties'));
    await tester.pump();

    expect(find.text('Accueil'), findsOneWidget);
    expect(find.text('Biens'), findsOneWidget);
    expect(find.text('Baux'), findsOneWidget);
    expect(find.text('Paiements'), findsOneWidget);
    expect(find.text('Messages'), findsOneWidget);
    expect(find.text('Maintenance'), findsNothing);

    final navBar = tester.widget<BottomNavigationBar>(
      find.byType(BottomNavigationBar),
    );
    expect(navBar.currentIndex, 1);
  });

  testWidgets('shows the tenant tabs with the right one selected', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_tenantUser, '/maintenance'));
    await tester.pump();

    expect(find.text('Accueil'), findsOneWidget);
    expect(find.text('Mon bail'), findsOneWidget);
    expect(find.text('Paiements'), findsOneWidget);
    expect(find.text('Maintenance'), findsOneWidget);
    expect(find.text('Messages'), findsOneWidget);
    expect(find.text('Biens'), findsNothing);

    final navBar = tester.widget<BottomNavigationBar>(
      find.byType(BottomNavigationBar),
    );
    expect(navBar.currentIndex, 3);
  });

  testWidgets('defaults to the first tab for an unknown route', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_ownerUser, '/some/unmapped/route'));
    await tester.pump();

    final navBar = tester.widget<BottomNavigationBar>(
      find.byType(BottomNavigationBar),
    );
    expect(navBar.currentIndex, 0);
  });
}
