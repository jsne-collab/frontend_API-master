import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_locative/features/properties/data/property_api.dart';
import 'package:gestion_locative/features/properties/data/property_repository.dart';
import 'package:gestion_locative/features/properties/domain/property_provider.dart';
import 'package:gestion_locative/features/properties/presentation/screens/property_list_screen.dart';

Map<String, dynamic> _propertyJson({required int id, required String title}) {
  return {
    'id': id,
    'owner_id': 1,
    'title': title,
    'type': 'appartement',
    'address': '10 Rue Test',
    'city': 'Lomé',
    'surface_area': 80.0,
    'rooms_count': 3,
    'monthly_rent': 100000,
    'deposit_amount': 100000,
    'status': 'available',
    'description': null,
    'images': [],
    'created_at': '2026-07-18T00:00:00Z',
  };
}

class _FakeEmptyApi extends PropertyApi {
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

class _FakeWithItemsApi extends PropertyApi {
  @override
  Future<Map<String, dynamic>> listOwn() async {
    return {
      'success': true,
      'message': '',
      'data': {
        'items': [
          _propertyJson(id: 1, title: 'Villa Bord de Mer'),
          _propertyJson(id: 2, title: 'Studio Centre-ville'),
        ],
        'pagination': {
          'current_page': 1,
          'last_page': 1,
          'per_page': 15,
          'total': 2,
        },
      },
    };
  }
}

Widget _wrap(PropertyApi fakeApi) {
  return ProviderScope(
    overrides: [
      propertyRepositoryProvider.overrideWithValue(
        PropertyRepository(api: fakeApi),
      ),
    ],
    child: const MaterialApp(home: PropertyListScreen()),
  );
}

void main() {
  testWidgets('shows an empty state when the owner has no property', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_FakeEmptyApi()));
    await tester.pumpAndSettle();

    expect(
      find.textContaining("Vous n'avez pas encore de bien"),
      findsOneWidget,
    );
  });

  testWidgets('lists the owner properties returned by the API', (tester) async {
    await tester.pumpWidget(_wrap(_FakeWithItemsApi()));
    await tester.pumpAndSettle();

    expect(find.text('Villa Bord de Mer'), findsOneWidget);
    expect(find.text('Studio Centre-ville'), findsOneWidget);
  });
}
