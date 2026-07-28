import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_locative/features/leases/data/lease_api.dart';
import 'package:gestion_locative/features/leases/data/lease_repository.dart';
import 'package:gestion_locative/features/leases/domain/lease_provider.dart';
import 'package:gestion_locative/features/maintenance/data/maintenance_api.dart';
import 'package:gestion_locative/features/maintenance/data/maintenance_repository.dart';
import 'package:gestion_locative/features/maintenance/domain/maintenance_provider.dart';
import 'package:gestion_locative/features/maintenance/presentation/screens/maintenance_create_screen.dart';

Map<String, dynamic> _leaseJson() {
  return {
    'id': 7,
    'property': {
      'id': 3,
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

class _FakeMaintenanceApi extends MaintenanceApi {
  int createCallCount = 0;
  Map<String, dynamic>? lastPayload;

  @override
  Future<Map<String, dynamic>> create(
    Map<String, dynamic> data, {
    String? photoPath,
  }) async {
    createCallCount++;
    lastPayload = data;

    return {
      'success': true,
      'message': 'Demande de maintenance créée avec succès.',
      'data': {
        'id': 1,
        'property': {'id': 3, 'title': 'Villa Bord de Mer'},
        'lease_id': 7,
        'tenant': {'id': 2, 'name': 'Awa Koffi'},
        'title': data['title'],
        'description': data['description'],
        'priority': data['priority'],
        'status': 'new',
        'photo_url': null,
        'comments': [],
        'created_at': '2026-07-19T00:00:00Z',
      },
    };
  }
}

Widget _wrap({
  required LeaseApi fakeLeaseApi,
  required MaintenanceApi fakeMaintenanceApi,
}) {
  return ProviderScope(
    overrides: [
      leaseRepositoryProvider.overrideWithValue(
        LeaseRepository(api: fakeLeaseApi),
      ),
      maintenanceRepositoryProvider.overrideWithValue(
        MaintenanceRepository(api: fakeMaintenanceApi),
      ),
    ],
    child: const MaterialApp(home: MaintenanceCreateScreen()),
  );
}

void main() {
  testWidgets('pre-fills the property from the active lease', (tester) async {
    await tester.pumpWidget(
      _wrap(
        fakeLeaseApi: _FakeLeaseApi(),
        fakeMaintenanceApi: _FakeMaintenanceApi(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Villa Bord de Mer'), findsOneWidget);
  });

  testWidgets('submits the request with the right property and priority', (
    tester,
  ) async {
    final fakeMaintenanceApi = _FakeMaintenanceApi();

    await tester.pumpWidget(
      _wrap(
        fakeLeaseApi: _FakeLeaseApi(),
        fakeMaintenanceApi: fakeMaintenanceApi,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Titre'), 'Fuite d\'eau');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Description'),
      'Fuite sous le lavabo.',
    );

    await tester.ensureVisible(find.text('Envoyer la demande'));
    await tester.tap(find.text('Envoyer la demande'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(fakeMaintenanceApi.createCallCount, 1);
    expect(fakeMaintenanceApi.lastPayload?['property_id'], 3);
    expect(fakeMaintenanceApi.lastPayload?['title'], 'Fuite d\'eau');
    expect(fakeMaintenanceApi.lastPayload?['priority'], 'medium');
  });
}
