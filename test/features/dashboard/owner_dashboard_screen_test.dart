import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:gestion_locative/features/auth/domain/auth_provider.dart';
import 'package:gestion_locative/features/auth/domain/auth_state.dart';
import 'package:gestion_locative/features/auth/domain/user_model.dart';
import 'package:gestion_locative/features/dashboard/data/dashboard_api.dart';
import 'package:gestion_locative/features/dashboard/data/dashboard_repository.dart';
import 'package:gestion_locative/features/dashboard/domain/dashboard_provider.dart';
import 'package:gestion_locative/features/dashboard/presentation/screens/owner_dashboard_screen.dart';
import 'package:gestion_locative/features/notifications/data/notification_api.dart';
import 'package:gestion_locative/features/notifications/data/notification_repository.dart';
import 'package:gestion_locative/features/notifications/domain/notification_provider.dart';

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

class _FakeNotificationApi extends NotificationApi {
  @override
  Future<Map<String, dynamic>> list() async {
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
}

class _FakeDashboardApi extends DashboardApi {
  int ownerCallCount = 0;

  @override
  Future<Map<String, dynamic>> owner() async {
    ownerCallCount++;
    return {
      'success': true,
      'message': '',
      'data': {
        'monthly_revenue': 250000,
        'previous_month_revenue': 200000,
        'revenue_variation_percent': 25.0,
        'occupancy_rate': 66.7,
        'pending_payments_count': 2,
        'available_properties_count': 1,
        'total_properties_count': 3,
        'recent_payments': <Map<String, dynamic>>[],
        'open_maintenance_requests': <Map<String, dynamic>>[],
      },
    };
  }

  @override
  Future<Map<String, dynamic>> revenue() async {
    return {
      'success': true,
      'message': '',
      'data': [
        {'month': '2026-02', 'total': 0},
        {'month': '2026-03', 'total': 100000},
        {'month': '2026-04', 'total': 150000},
        {'month': '2026-05', 'total': 120000},
        {'month': '2026-06', 'total': 200000},
        {'month': '2026-07', 'total': 250000},
      ],
    };
  }
}

Widget _wrap({
  required DashboardApi fakeDashboardApi,
  required NotificationApi fakeNotificationApi,
}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(_FakeAuthController.new),
      dashboardRepositoryProvider.overrideWithValue(
        DashboardRepository(api: fakeDashboardApi),
      ),
      notificationRepositoryProvider.overrideWithValue(
        NotificationRepository(api: fakeNotificationApi),
      ),
    ],
    child: const MaterialApp(home: OwnerDashboardScreen()),
  );
}

void main() {
  testWidgets('shows the monthly revenue and KPI figures from the API', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        fakeDashboardApi: _FakeDashboardApi(),
        fakeNotificationApi: _FakeNotificationApi(),
      ),
    );
    await tester.pumpAndSettle();

    final currency = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
      decimalDigits: 0,
    );

    expect(find.textContaining('Bonjour, Jean'), findsOneWidget);
    expect(find.text(currency.format(250000)), findsOneWidget);
    expect(find.text('+25.0% vs mois dernier'), findsOneWidget);
    expect(find.text('67%'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('pull-to-refresh reloads the owner dashboard', (tester) async {
    final fakeDashboardApi = _FakeDashboardApi();

    await tester.pumpWidget(
      _wrap(
        fakeDashboardApi: fakeDashboardApi,
        fakeNotificationApi: _FakeNotificationApi(),
      ),
    );
    await tester.pumpAndSettle();

    expect(fakeDashboardApi.ownerCallCount, 1);

    await tester.fling(find.byType(ListView).first, const Offset(0, 300), 1000);
    await tester.pumpAndSettle();

    expect(fakeDashboardApi.ownerCallCount, 2);
  });
}
