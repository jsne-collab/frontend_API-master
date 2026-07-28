import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_locative/features/leases/data/lease_api.dart';
import 'package:gestion_locative/features/leases/data/lease_repository.dart';
import 'package:gestion_locative/features/leases/domain/lease_provider.dart';
import 'package:gestion_locative/features/leases/presentation/screens/lease_form_screen.dart';
import 'package:gestion_locative/features/properties/data/property_api.dart';
import 'package:gestion_locative/features/properties/data/property_repository.dart';
import 'package:gestion_locative/features/properties/domain/property_model.dart';
import 'package:gestion_locative/features/properties/domain/property_provider.dart';

Map<String, dynamic> _propertyJson() {
  return {
    'id': 5,
    'owner_id': 1,
    'title': 'Villa Bord de Mer',
    'type': 'maison',
    'address': '1 Rue Test',
    'city': 'Lomé',
    'surface_area': 120,
    'rooms_count': 4,
    'monthly_rent': 150000,
    'deposit_amount': 150000,
    'status': 'available',
    'description': null,
    'images': [],
  };
}

Map<String, dynamic> _leaseJson(Map<String, dynamic> data) {
  return {
    'id': 42,
    'property': {
      'id': 5,
      'title': 'Villa Bord de Mer',
      'address': '1 Rue Test',
      'city': 'Lomé',
    },
    'unit': null,
    'tenant': {
      'id': 9,
      'name': 'Awa Koffi',
      'phone': '+22890000009',
      'email': 'awa@example.com',
    },
    'owner': {'id': 1, 'name': 'Jean Owner', 'phone': '+22890000001'},
    'start_date': '2026-01-01',
    'end_date': '2027-01-01',
    'monthly_rent': data['monthly_rent'],
    'deposit_amount': data['deposit_amount'],
    'status': 'active',
    'contract_pdf_url': null,
    'created_at': '2026-01-01T00:00:00Z',
  };
}

class _FakePropertyApi extends PropertyApi {
  @override
  Future<Map<String, dynamic>> listOwn() async {
    return {
      'success': true,
      'message': '',
      'data': {
        'items': [_propertyJson()],
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

class _FakeLeaseApi extends LeaseApi {
  int createCallCount = 0;
  Map<String, dynamic>? lastPayload;

  @override
  Future<Map<String, dynamic>> listOwn() async {
    return {
      'success': true,
      'message': '',
      'data': {
        'items': <Map<String, dynamic>>[],
        'pagination': {
          'current_page': 1,
          'last_page': 1,
          'per_page': 15,
          'total': 0,
        },
      },
    };
  }

  @override
  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    createCallCount++;
    lastPayload = data;
    return {
      'success': true,
      'message': 'Bail créé avec succès.',
      'data': _leaseJson(data),
    };
  }
}

Widget _wrap({
  required PropertyApi fakePropertyApi,
  required LeaseApi fakeLeaseApi,
}) {
  return ProviderScope(
    overrides: [
      propertyRepositoryProvider.overrideWithValue(
        PropertyRepository(api: fakePropertyApi),
      ),
      leaseRepositoryProvider.overrideWithValue(
        LeaseRepository(api: fakeLeaseApi),
      ),
    ],
    child: const MaterialApp(home: LeaseFormScreen()),
  );
}

void main() {
  testWidgets(
    'creating a lease blocks submission without a selected property or tenant',
    (tester) async {
      final fakeLeaseApi = _FakeLeaseApi();

      await tester.pumpWidget(
        _wrap(fakePropertyApi: _FakePropertyApi(), fakeLeaseApi: fakeLeaseApi),
      );
      await tester.pumpAndSettle();

      expect(find.text('Créer un bail'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Loyer mensuel (FCFA)'),
        '150000',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Caution (FCFA)'),
        '150000',
      );

      await tester.ensureVisible(find.text('Créer le bail'));
      await tester.tap(find.text('Créer le bail'));
      await tester.pump();

      expect(find.text('Sélectionnez un bien.'), findsOneWidget);
      expect(fakeLeaseApi.createCallCount, 0);
    },
  );

  testWidgets('selecting a property pre-fills the rent and deposit fields', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(fakePropertyApi: _FakePropertyApi(), fakeLeaseApi: _FakeLeaseApi()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<Property>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Villa Bord de Mer').last);
    await tester.pumpAndSettle();

    expect(find.text('150000'), findsNWidgets(2));
  });
}
