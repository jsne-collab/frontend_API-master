import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/domain/auth_provider.dart';
import '../../../leases/domain/lease_model.dart';
import '../../../maintenance/domain/maintenance_model.dart';
import '../../../notifications/domain/notification_provider.dart';
import '../../../payments/domain/payment_model.dart';
import '../../domain/dashboard_model.dart';
import '../../domain/dashboard_provider.dart';
import '../../../../core/network/error_message.dart';

final _currency = NumberFormat.currency(
  locale: 'fr_FR',
  symbol: 'FCFA',
  decimalDigits: 0,
);

class TenantDashboardScreen extends ConsumerWidget {
  const TenantDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(tenantDashboardProvider);
    final user = ref.watch(authControllerProvider).user;
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final firstName = (user?.name ?? '').split(' ').first;

    return AppScaffold(
      currentRoute: '/tenant/home',
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Bonjour, $firstName'),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                tooltip: 'Notifications',
                onPressed: () => context.push('/notifications'),
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 10,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Mon profil',
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(tenantDashboardProvider.notifier).refresh(),
          child: dashboardAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      friendlyErrorMessage(error),
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ),
              ],
            ),
            data: (dashboard) => LayoutBuilder(
              builder: (context, constraints) {
                final isExpanded = constraints.maxWidth >= 840;

                final hero = _RentHeroCard(dashboard: dashboard);
                final homeCard = _MyHomeCard(lease: dashboard.currentLease);
                final recentPayments = _RecentPaymentsSection(
                  payments: dashboard.recentPayments,
                );
                final maintenanceSection = _OpenMaintenanceSection(
                  requests: dashboard.openMaintenanceRequests,
                );

                if (isExpanded) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              hero,
                              const SizedBox(height: 16),
                              const _ReceiptsLinkCard(),
                              const SizedBox(height: 16),
                              homeCard,
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              recentPayments,
                              const SizedBox(height: 16),
                              maintenanceSection,
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    hero,
                    const SizedBox(height: 16),
                    const _ReceiptsLinkCard(),
                    const SizedBox(height: 16),
                    homeCard,
                    const SizedBox(height: 16),
                    recentPayments,
                    const SizedBox(height: 16),
                    maintenanceSection,
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _RentHeroCard extends StatelessWidget {
  const _RentHeroCard({required this.dashboard});

  final TenantDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final lease = dashboard.currentLease;

    if (lease == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryLight],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          "Vous n'avez pas de bail actif pour le moment.",
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    final dueDate = dashboard.nextDueDate;
    final daysUntilDue = dueDate?.difference(
      DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      ),
    ).inDays;
    final isUrgent = daysUntilDue != null && daysUntilDue <= 5;
    final isOverdue = daysUntilDue != null && daysUntilDue < 0;
    // Approximation d'un cycle de 30 jours pour la barre de progression
    // (aucune date d'échéance précédente exposée par l'API).
    final elapsedFraction = daysUntilDue == null
        ? 0.0
        : (1 - (daysUntilDue.clamp(0, 30) / 30)).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Loyer courant',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
              StatusBadge(
                label: lease.status.label,
                tone: lease.status == LeaseStatus.active
                    ? StatusTone.success
                    : StatusTone.neutral,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _currency.format(lease.monthlyRent),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (dueDate != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  color: Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  isOverdue
                      ? 'En retard de ${-daysUntilDue} jour(s)'
                      : daysUntilDue == 0
                      ? "Échéance aujourd'hui"
                      : 'Échéance dans $daysUntilDue jour(s)',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: elapsedFraction,
                minHeight: 6,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation(
                  isOverdue ? AppColors.error : AppColors.accent,
                ),
              ),
            ),
            if (isUrgent) ...[
              const SizedBox(height: 16),
              AppButton(
                label: 'Payer maintenant',
                variant: AppButtonVariant.secondary,
                onPressed: () => context.push('/payments/initiate'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// Accès aux quittances — pas d'onglet dédié dans la barre de navigation,
/// donc affiché en pleine largeur comme les autres cartes de l'accueil
/// plutôt qu'en petite tuile carrée (qui détonnait, seule, à côté d'elles).
class _ReceiptsLinkCard extends StatelessWidget {
  const _ReceiptsLinkCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.push('/receipts'),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Quittances',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _MyHomeCard extends StatelessWidget {
  const _MyHomeCard({required this.lease});

  final Lease? lease;

  @override
  Widget build(BuildContext context) {
    if (lease == null) return const SizedBox.shrink();

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.home_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mon logement',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  lease!.property.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${lease!.property.address}, ${lease!.property.city}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentPaymentsSection extends StatelessWidget {
  const _RecentPaymentsSection({required this.payments});

  final List<Payment> payments;

  StatusTone _tone(PaymentStatus status) => switch (status) {
    PaymentStatus.validated => StatusTone.success,
    PaymentStatus.pending => StatusTone.warning,
    PaymentStatus.late => StatusTone.error,
    PaymentStatus.partial => StatusTone.warning,
  };

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Historique récent',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              TextButton(
                onPressed: () => context.push('/payments'),
                child: const Text('Voir tout'),
              ),
            ],
          ),
          if (payments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Aucun paiement récent.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            ...payments.map(
              (payment) => Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        payment.periodCovered,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _currency.format(payment.amount),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(
                      label: payment.status.label,
                      tone: _tone(payment.status),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OpenMaintenanceSection extends StatelessWidget {
  const _OpenMaintenanceSection({required this.requests});

  final List<MaintenanceRequestModel> requests;

  StatusTone _tone(MaintenancePriority priority) => switch (priority) {
    MaintenancePriority.low => StatusTone.neutral,
    MaintenancePriority.medium => StatusTone.warning,
    MaintenancePriority.high => StatusTone.error,
    MaintenancePriority.urgent => StatusTone.error,
  };

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Mes demandes en cours',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              TextButton(
                onPressed: () => context.push('/maintenance'),
                child: const Text('Voir tout'),
              ),
            ],
          ),
          if (requests.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Aucune demande en cours.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            ...requests.map(
              (request) => Padding(
                padding: const EdgeInsets.only(top: 10),
                child: InkWell(
                  onTap: () => context.push('/maintenance/${request.id}'),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          request.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(
                        label: request.priority.label,
                        tone: _tone(request.priority),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
