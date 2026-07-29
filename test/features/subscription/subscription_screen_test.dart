import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_locative/features/subscription/data/subscription_api.dart';
import 'package:gestion_locative/features/subscription/data/subscription_repository.dart';
import 'package:gestion_locative/features/subscription/domain/subscription_provider.dart';
import 'package:gestion_locative/features/subscription/presentation/screens/subscription_screen.dart';

class _NeverPaidApi extends SubscriptionApi {
  @override
  Future<Map<String, dynamic>> show() async => {
    'success': true,
    'message': '',
    'data': {'status': 'never', 'next_due_date': null, 'amount': 5000},
  };
}

class _PendingApi extends SubscriptionApi {
  @override
  Future<Map<String, dynamic>> show() async => {
    'success': true,
    'message': '',
    'data': {
      'status': 'pending',
      'next_due_date': '2026-08-01',
      'amount': 5000,
    },
  };
}

Widget _wrap(SubscriptionApi fakeApi) {
  return ProviderScope(
    overrides: [
      subscriptionRepositoryProvider.overrideWithValue(
        SubscriptionRepository(api: fakeApi),
      ),
    ],
    child: const MaterialApp(home: SubscriptionScreen()),
  );
}

void main() {
  testWidgets('offers to pay when the owner never paid the subscription', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_NeverPaidApi()));
    await tester.pumpAndSettle();

    expect(find.text('Jamais payé'), findsOneWidget);
    expect(find.text('Payer maintenant'), findsOneWidget);
  });

  testWidgets('shows a pending message instead of the payment form', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_PendingApi()));
    await tester.pumpAndSettle();

    expect(find.text('En attente de validation'), findsOneWidget);
    expect(
      find.text(
        'Paiement envoyé, en attente de validation par un administrateur.',
      ),
      findsOneWidget,
    );
    expect(find.text('Payer maintenant'), findsNothing);
  });
}
