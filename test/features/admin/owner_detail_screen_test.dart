import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_locative/features/admin/data/admin_api.dart';
import 'package:gestion_locative/features/admin/data/admin_repository.dart';
import 'package:gestion_locative/features/admin/domain/admin_provider.dart';
import 'package:gestion_locative/features/admin/presentation/screens/owner_detail_screen.dart';

class _FakeAdminApi extends AdminApi {
  int validateCallCount = 0;

  @override
  Future<Map<String, dynamic>> showOwner(int ownerId) async => {
    'success': true,
    'message': '',
    'data': {
      'owner': {
        'id': ownerId,
        'name': 'Josiane',
        'email': 'josiane@example.com',
        'phone': '+22890000000',
        'role': 'owner',
      },
      'leases': [
        {
          'id': 1,
          'property': {
            'id': 1,
            'title': 'Studio Centre-ville',
            'address': 'Rue 1',
            'city': 'Lomé',
          },
          'unit': null,
          'tenant': {
            'id': 5,
            'name': 'Josy1',
            'phone': '+22891111111',
            'email': 'j1@example.com',
          },
          'owner': {'id': ownerId, 'name': 'Josiane', 'phone': '+22890000000'},
          'start_date': '2026-01-01',
          'end_date': '2027-01-01',
          'monthly_rent': 50000,
          'deposit_amount': 50000,
          'status': 'active',
          'contract_pdf_url': null,
          'created_at': '2026-01-01T00:00:00Z',
        },
      ],
      'subscriptions': [
        {
          'id': 42,
          'amount': 5000,
          'period_start': '2026-07-01',
          'period_end': '2026-08-01',
          'payment_method': null,
          'status': 'pending',
          'paid_at': null,
          'reference': null,
        },
      ],
      'subscription_status': 'pending',
      'next_due_date': '2026-08-01',
    },
  };

  @override
  Future<Map<String, dynamic>> validateSubscription(int subscriptionId) async {
    validateCallCount++;
    return {'success': true, 'message': '', 'data': null};
  }
}

Widget _wrap(AdminApi fakeApi) {
  return ProviderScope(
    overrides: [
      adminRepositoryProvider.overrideWithValue(AdminRepository(api: fakeApi)),
    ],
    child: const MaterialApp(home: OwnerDetailScreen(ownerId: 1)),
  );
}

void main() {
  testWidgets(
    'shows the tenant, the pending subscription and validates it on tap',
    (tester) async {
      final fakeApi = _FakeAdminApi();

      await tester.pumpWidget(_wrap(fakeApi));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Josy1'), findsOneWidget);
      expect(find.text('Studio Centre-ville'), findsOneWidget);
      expect(find.text('Valider'), findsOneWidget);

      await tester.tap(find.text('Valider'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(fakeApi.validateCallCount, 1);
    },
  );
}
