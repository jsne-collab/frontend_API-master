import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_locative/features/leases/data/lease_api.dart';
import 'package:gestion_locative/features/leases/data/lease_repository.dart';
import 'package:gestion_locative/features/leases/domain/lease_provider.dart';
import 'package:gestion_locative/features/payments/data/payment_api.dart';
import 'package:gestion_locative/features/payments/data/payment_repository.dart';
import 'package:gestion_locative/features/payments/domain/payment_provider.dart';
import 'package:gestion_locative/features/payments/presentation/screens/payment_initiate_screen.dart';

Map<String, dynamic> _leaseJson() {
  return {
    'id': 7,
    'property': {
      'id': 1,
      'title': 'Villa Bord de Mer',
      'address': '1 Rue Test',
      'city': 'Lomé',
    },
    'unit': null,
    'tenant': {
      'id': 2,
      'name': 'Awa Koffi',
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

class _FakeLeaseApi extends LeaseApi {
  @override
  Future<Map<String, dynamic>> listOwn() async {
    return {
      'success': true,
      'message': '',
      'data': {
        'items': [_leaseJson()],
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

class _FakePaymentApi extends PaymentApi {
  int initiateCallCount = 0;
  Map<String, dynamic>? lastPayload;

  @override
  Future<Map<String, dynamic>> initiate(Map<String, dynamic> data) async {
    initiateCallCount++;
    lastPayload = data;

    return {
      'success': true,
      'message': 'Paiement initié, en attente de validation.',
      'data': {
        'id': 1,
        'lease': {'id': 7, 'property_title': 'Villa Bord de Mer'},
        'tenant': {'id': 2, 'name': 'Awa Koffi'},
        'amount': data['amount'],
        'payment_method': null,
        'payment_date': '2026-07-19',
        'period_covered': data['period_covered'],
        'status': 'pending',
        'reference': null,
        'created_at': '2026-07-19T00:00:00Z',
      },
    };
  }
}

Widget _wrap({
  required LeaseApi fakeLeaseApi,
  required PaymentApi fakePaymentApi,
}) {
  return ProviderScope(
    overrides: [
      leaseRepositoryProvider.overrideWithValue(
        LeaseRepository(api: fakeLeaseApi),
      ),
      paymentRepositoryProvider.overrideWithValue(
        PaymentRepository(api: fakePaymentApi),
      ),
    ],
    child: const MaterialApp(home: PaymentInitiateScreen()),
  );
}

void main() {
  testWidgets('pre-fills the amount from the selected active lease', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(fakeLeaseApi: _FakeLeaseApi(), fakePaymentApi: _FakePaymentApi()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Villa Bord de Mer'), findsOneWidget);
    expect(find.text('100000'), findsOneWidget);
  });

  testWidgets('submits the payment and calls initiate with the right lease', (
    tester,
  ) async {
    final fakePaymentApi = _FakePaymentApi();

    await tester.pumpWidget(
      _wrap(fakeLeaseApi: _FakeLeaseApi(), fakePaymentApi: fakePaymentApi),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Envoyer le paiement'));
    await tester.tap(find.text('Envoyer le paiement'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(fakePaymentApi.initiateCallCount, 1);
    expect(fakePaymentApi.lastPayload?['lease_id'], 7);
    expect(fakePaymentApi.lastPayload?['method_type'], 'mobile_money');
  });
}
