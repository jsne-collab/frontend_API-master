import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_locative/features/admin/data/admin_api.dart';
import 'package:gestion_locative/features/admin/data/admin_repository.dart';
import 'package:gestion_locative/features/admin/domain/admin_provider.dart';
import 'package:gestion_locative/features/admin/presentation/screens/admin_owners_screen.dart';
import 'package:gestion_locative/features/auth/domain/auth_provider.dart';
import 'package:gestion_locative/features/auth/domain/auth_state.dart';
import 'package:gestion_locative/features/auth/domain/user_model.dart';

const _testAdmin = User(
  id: 99,
  name: 'Super Admin',
  email: 'admin@example.com',
  phone: '+22890000000',
  role: UserRole.admin,
);

class _FakeAuthController extends AuthController {
  @override
  AuthState build() => const AuthState.authenticated(_testAdmin);
}

class _FakeEmptyAdminApi extends AdminApi {
  @override
  Future<List<dynamic>> listOwners() async => [];
}

class _FakeAdminApi extends AdminApi {
  @override
  Future<List<dynamic>> listOwners() async => [
    {
      'owner': {
        'id': 1,
        'name': 'Owner With Tenant',
        'email': 'owner1@example.com',
        'phone': '+22891111111',
        'role': 'owner',
      },
      'properties_count': 2,
      'tenant_count': 1,
      'subscription_status': 'paid',
      'next_due_date': '2026-08-01',
    },
    {
      'owner': {
        'id': 2,
        'name': 'Owner Without Tenant',
        'email': 'owner2@example.com',
        'phone': '+22892222222',
        'role': 'owner',
      },
      'properties_count': 1,
      'tenant_count': 0,
      'subscription_status': 'never',
      'next_due_date': null,
    },
  ];
}

Widget _wrap(AdminApi fakeApi) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(_FakeAuthController.new),
      adminRepositoryProvider.overrideWithValue(
        AdminRepository(api: fakeApi),
      ),
    ],
    child: const MaterialApp(home: AdminOwnersScreen()),
  );
}

void main() {
  testWidgets('shows an empty state when there are no owners', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_FakeEmptyAdminApi()));
    await tester.pumpAndSettle();

    expect(find.text('Aucun propriétaire pour le moment.'), findsOneWidget);
  });

  testWidgets(
    'lists every owner with or without tenants and their subscription status',
    (tester) async {
      await tester.pumpWidget(_wrap(_FakeAdminApi()));
      await tester.pumpAndSettle();

      expect(find.text('Owner With Tenant'), findsOneWidget);
      expect(find.text('2 bien(s) · 1 locataire(s)'), findsOneWidget);
      expect(find.text('À jour'), findsOneWidget);

      expect(find.text('Owner Without Tenant'), findsOneWidget);
      expect(find.text('1 bien(s) · 0 locataire(s)'), findsOneWidget);
      expect(find.text('Jamais payé'), findsOneWidget);
    },
  );
}
