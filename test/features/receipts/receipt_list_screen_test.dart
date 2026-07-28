import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_locative/features/receipts/data/receipt_api.dart';
import 'package:gestion_locative/features/receipts/data/receipt_repository.dart';
import 'package:gestion_locative/features/receipts/domain/receipt_provider.dart';
import 'package:gestion_locative/features/receipts/presentation/screens/receipt_list_screen.dart';

Map<String, dynamic> _receiptJson({
  required int id,
  required String receiptNumber,
}) {
  return {
    'id': id,
    'receipt_number': receiptNumber,
    'payment': {
      'id': 1,
      'amount': 100000,
      'period_covered': '2026-07',
      'payment_date': '2026-07-19',
    },
    'property_title': 'Villa Bord de Mer',
    'tenant': {'id': 2, 'name': 'Awa Koffi'},
    'pdf_url': 'http://example.test/storage/receipts/$receiptNumber.pdf',
    'generated_at': '2026-07-19T10:00:00Z',
  };
}

class _FakeEmptyApi extends ReceiptApi {
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

class _FakeWithItemsApi extends ReceiptApi {
  @override
  Future<Map<String, dynamic>> listOwn() async {
    return {
      'success': true,
      'message': '',
      'data': {
        'items': [_receiptJson(id: 1, receiptNumber: 'QUIT-2026-000001')],
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

Widget _wrap(ReceiptApi fakeApi) {
  return ProviderScope(
    overrides: [
      receiptRepositoryProvider.overrideWithValue(
        ReceiptRepository(api: fakeApi),
      ),
    ],
    child: const MaterialApp(home: ReceiptListScreen()),
  );
}

void main() {
  testWidgets('shows an empty state when there are no receipts', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_FakeEmptyApi()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Aucune quittance'), findsOneWidget);
  });

  testWidgets('lists the receipts returned by the API', (tester) async {
    await tester.pumpWidget(_wrap(_FakeWithItemsApi()));
    await tester.pumpAndSettle();

    expect(find.text('QUIT-2026-000001'), findsOneWidget);
    expect(find.textContaining('Villa Bord de Mer'), findsOneWidget);
  });
}
