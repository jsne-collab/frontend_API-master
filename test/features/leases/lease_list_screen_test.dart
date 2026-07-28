import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_locative/features/auth/domain/auth_provider.dart';
import 'package:gestion_locative/features/auth/domain/auth_state.dart';
import 'package:gestion_locative/features/auth/domain/user_model.dart';
import 'package:gestion_locative/features/leases/data/lease_api.dart';
import 'package:gestion_locative/features/leases/data/lease_repository.dart';
import 'package:gestion_locative/features/leases/domain/lease_provider.dart';
import 'package:gestion_locative/features/leases/presentation/screens/lease_list_screen.dart';

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

Map<String, dynamic> _leaseJson({
  required int id,
  required String title,
  required String tenantName,
}) {
  return {
    'id': id,
    'property': {
      'id': 1,
      'title': title,
      'address': '1 Rue Test',
      'city': 'Lomé',
    },
    'unit': null,
    'tenant': {
      'id': 5,
      'name': tenantName,
      'phone': '+22890000002',
      'email': 't@example.com',
    },
    'owner': {'id': 1, 'name': 'Jean Owner', 'phone': '+22890000001'},
    'start_date': '2026-01-01',
    'end_date': '2027-01-01',
    'monthly_rent': 100000,
    'deposit_amount': 100000,
    'status': 'active',
    'contract_pdf_url': null,
    'created_at': '2026-01-01T00:00:00Z',
  };
}

class _FakeEmptyApi extends LeaseApi {
  @override
  Future<Map<String, dynamic>> listOwn() async {
    return {
      'success': true,
      'message': '',
      'data': {
        'items': [],
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

class _FakeWithItemsApi extends LeaseApi {
  @override
  Future<Map<String, dynamic>> listOwn() async {
    return {
      'success': true,
      'message': '',
      'data': {
        'items': [
          _leaseJson(
            id: 1,
            title: 'Villa Bord de Mer',
            tenantName: 'Awa Koffi',
          ),
        ],
        'pagination': {
          'current_page': 1,
          'last_page': 1,
          'per_page': 15,
          'total': 1,
        },
      },
    };
  }
}

Widget _wrap(LeaseApi fakeApi) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(_FakeAuthController.new),
      leaseRepositoryProvider.overrideWithValue(LeaseRepository(api: fakeApi)),
    ],
    child: const MaterialApp(home: LeaseListScreen()),
  );
}

void main() {
  testWidgets('shows an empty state when there are no leases', (tester) async {
    await tester.pumpWidget(_wrap(_FakeEmptyApi()));
    await tester.pumpAndSettle();

    expect(
      find.textContaining("Vous n'avez pas encore de bail"),
      findsOneWidget,
    );
  });

  testWidgets('lists the leases returned by the API', (tester) async {
    await tester.pumpWidget(_wrap(_FakeWithItemsApi()));
    await tester.pumpAndSettle();

    expect(find.text('Villa Bord de Mer'), findsOneWidget);
    expect(find.text('Locataire : Awa Koffi'), findsOneWidget);
  });
}
