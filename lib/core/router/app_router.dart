import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/auth_provider.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/domain/user_model.dart';
import '../../features/auth/presentation/screens/complete_profile_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/admin/presentation/screens/admin_owners_screen.dart';
import '../../features/admin/presentation/screens/owner_detail_screen.dart';
import '../../features/dashboard/presentation/screens/owner_dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/statistics_screen.dart';
import '../../features/dashboard/presentation/screens/tenant_dashboard_screen.dart';
import '../../features/expenses/presentation/screens/expense_form_screen.dart';
import '../../features/expenses/presentation/screens/expense_list_screen.dart';
import '../../features/profile/presentation/screens/about_screen.dart';
import '../../features/legal/presentation/screens/legal_document_screen.dart';
import '../../features/profile/presentation/screens/change_password_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/leases/presentation/screens/lease_detail_screen.dart';
import '../../features/leases/presentation/screens/lease_form_screen.dart';
import '../../features/leases/presentation/screens/lease_list_screen.dart';
import '../../features/maintenance/presentation/screens/maintenance_create_screen.dart';
import '../../features/maintenance/presentation/screens/maintenance_detail_screen.dart';
import '../../features/maintenance/presentation/screens/maintenance_list_screen.dart';
import '../../features/messaging/presentation/screens/conversations_list_screen.dart';
import '../../features/messaging/presentation/screens/message_thread_screen.dart';
import '../../features/messaging/presentation/screens/new_conversation_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/payments/presentation/screens/payment_detail_screen.dart';
import '../../features/payments/presentation/screens/payment_initiate_screen.dart';
import '../../features/payments/presentation/screens/payment_list_screen.dart';
import '../../features/properties/presentation/screens/property_detail_screen.dart';
import '../../features/properties/presentation/screens/property_form_screen.dart';
import '../../features/properties/presentation/screens/property_list_screen.dart';
import '../../features/receipts/presentation/screens/receipt_list_screen.dart';
import '../../features/subscription/presentation/screens/subscription_screen.dart';
import '../widgets/pdf_viewer_screen.dart';

const _publicPaths = {'/login', '/register', '/forgot-password'};

/// Notifie go_router à chaque changement de [authControllerProvider] pour
/// que `redirect` soit ré-évalué (sinon go_router ne se met à jour qu'à
/// la prochaine navigation).
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen(authControllerProvider, (previous, next) {
      final statusChanged = previous?.status != next.status;
      final profileCompletedChanged =
          previous?.user?.profileCompleted != next.user?.profileCompleted;
      if (statusChanged || profileCompletedChanged) notifyListeners();
    });
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final path = state.matchedLocation;

      if (authState.status == AuthStatus.unknown) {
        return path == '/splash' ? null : '/splash';
      }

      final isAuthenticated = authState.isAuthenticated;

      if (!isAuthenticated) {
        return _publicPaths.contains(path) ? null : '/login';
      }

      final user = authState.user!;

      if (!user.profileCompleted) {
        return path == '/complete-profile' ? null : '/complete-profile';
      }

      if (path == '/complete-profile' ||
          path == '/splash' ||
          _publicPaths.contains(path)) {
        return switch (user.role) {
          UserRole.owner => '/owner/home',
          UserRole.admin => '/admin/home',
          UserRole.tenant => '/tenant/home',
        };
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/complete-profile',
        builder: (context, state) => const CompleteProfileScreen(),
      ),
      GoRoute(
        path: '/owner/home',
        builder: (context, state) => const OwnerDashboardScreen(),
      ),
      GoRoute(
        path: '/tenant/home',
        builder: (context, state) => const TenantDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/home',
        builder: (context, state) => const AdminOwnersScreen(),
      ),
      GoRoute(
        path: '/admin/owners/:id',
        builder: (context, state) =>
            OwnerDetailScreen(ownerId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/subscription',
        builder: (context, state) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: '/statistics',
        builder: (context, state) => const StatisticsScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(path: '/about', builder: (context, state) => const AboutScreen()),
      GoRoute(
        path: '/legal/terms',
        builder: (context, state) => LegalDocumentScreen.termsOfService,
      ),
      GoRoute(
        path: '/legal/privacy',
        builder: (context, state) => LegalDocumentScreen.privacyPolicy,
      ),
      GoRoute(
        path: '/profile/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/properties',
        builder: (context, state) => const PropertyListScreen(),
      ),
      GoRoute(
        path: '/properties/create',
        builder: (context, state) => const PropertyFormScreen(),
      ),
      GoRoute(
        path: '/properties/:id',
        builder: (context, state) => PropertyDetailScreen(
          propertyId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/properties/:id/edit',
        builder: (context, state) => PropertyFormScreen(
          propertyId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/leases',
        builder: (context, state) => const LeaseListScreen(),
      ),
      GoRoute(
        path: '/leases/create',
        builder: (context, state) => const LeaseFormScreen(),
      ),
      GoRoute(
        path: '/leases/:id',
        builder: (context, state) =>
            LeaseDetailScreen(leaseId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/leases/:id/edit',
        builder: (context, state) =>
            LeaseFormScreen(leaseId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/leases/:id/contract',
        builder: (context, state) => PdfViewerScreen(
          title: 'Contrat de location',
          pdfUrl: state.extra! as String,
        ),
      ),
      GoRoute(
        path: '/payments',
        builder: (context, state) => const PaymentListScreen(),
      ),
      GoRoute(
        path: '/payments/initiate',
        builder: (context, state) => const PaymentInitiateScreen(),
      ),
      GoRoute(
        path: '/payments/:id',
        builder: (context, state) => PaymentDetailScreen(
          paymentId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/receipts',
        builder: (context, state) => const ReceiptListScreen(),
      ),
      GoRoute(
        path: '/receipts/:id/view',
        builder: (context, state) =>
            PdfViewerScreen(title: 'Quittance', pdfUrl: state.extra! as String),
      ),
      GoRoute(
        path: '/expenses',
        builder: (context, state) => const ExpenseListScreen(),
      ),
      GoRoute(
        path: '/expenses/add',
        builder: (context, state) => const ExpenseFormScreen(),
      ),
      GoRoute(
        path: '/maintenance',
        builder: (context, state) => const MaintenanceListScreen(),
      ),
      GoRoute(
        path: '/maintenance/create',
        builder: (context, state) => const MaintenanceCreateScreen(),
      ),
      GoRoute(
        path: '/maintenance/:id',
        builder: (context, state) => MaintenanceDetailScreen(
          requestId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/messages',
        builder: (context, state) => const ConversationsListScreen(),
      ),
      GoRoute(
        path: '/messages/new',
        builder: (context, state) => const NewConversationScreen(),
      ),
      GoRoute(
        path: '/messages/:userId',
        builder: (context, state) => MessageThreadScreen(
          otherUserId: int.parse(state.pathParameters['userId']!),
          otherUserName: state.extra! as String,
        ),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
  );
});
