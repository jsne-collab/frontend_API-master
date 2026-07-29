import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/domain/auth_provider.dart';
import '../../../expenses/domain/expense_model.dart';
import '../../../expenses/domain/expense_provider.dart';
import '../../../maintenance/domain/maintenance_model.dart';
import '../../../notifications/domain/notification_provider.dart';
import '../../../payments/domain/payment_model.dart';
import '../../domain/dashboard_model.dart';
import '../../domain/dashboard_provider.dart';
import '../widgets/kpi_card.dart';
import '../widgets/quick_links.dart';
import '../widgets/revenue_chart.dart';
import '../../../../core/network/error_message.dart';
import '../../../../core/widgets/skeleton.dart';

// Biens/Baux/Paiements/Messages sont déjà dans la barre de navigation ;
// ces accès rapides couvrent le reste (pas assez de place pour 6+ onglets).
const _ownerQuickLinks = [
  QuickLink(
    icon: Icons.build_outlined,
    label: 'Maintenance',
    route: '/maintenance',
  ),
  QuickLink(
    icon: Icons.receipt_long_outlined,
    label: 'Quittances',
    route: '/receipts',
  ),
  QuickLink(
    icon: Icons.bar_chart_outlined,
    label: 'Statistiques',
    route: '/statistics',
  ),
  QuickLink(
    icon: Icons.workspace_premium_outlined,
    label: 'Abonnement',
    route: '/subscription',
  ),
];

final _currency = NumberFormat.currency(
  locale: 'fr_FR',
  symbol: 'FCFA',
  decimalDigits: 0,
);

class OwnerDashboardScreen extends ConsumerWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(ownerDashboardProvider);
    final revenueAsync = ref.watch(revenueChartProvider);
    final expensesAsync = ref.watch(myExpensesProvider);
    final user = ref.watch(authControllerProvider).user;
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final firstName = (user?.name ?? '').split(' ').first;

    return AppScaffold(
      currentRoute: '/owner/home',
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
          onRefresh: () async {
            await ref.read(ownerDashboardProvider.notifier).refresh();
            ref.invalidate(revenueChartProvider);
          },
          child: dashboardAsync.when(
            loading: () => const SkeletonList(),
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

                final hero = _HeroRevenueCard(dashboard: dashboard);
                final kpiRow = _KpiRow(
                  dashboard: dashboard,
                  compact: constraints.maxWidth < 600,
                );
                final chartCard = revenueAsync.when(
                  loading: () => const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (points) => AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Revenus (6 derniers mois)',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),
                        RevenueChart(points: points),
                      ],
                    ),
                  ),
                );
                final recentPaymentsSection = _RecentPaymentsSection(
                  payments: dashboard.recentPayments,
                );
                final maintenanceSection = _OpenMaintenanceSection(
                  requests: dashboard.openMaintenanceRequests,
                );
                final expensesSection = _ExpensesSection(
                  expensesAsync: expensesAsync,
                  monthlyRevenue: dashboard.monthlyRevenue,
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
                              const QuickLinks(links: _ownerQuickLinks),
                              const SizedBox(height: 16),
                              chartCard,
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              kpiRow,
                              const SizedBox(height: 16),
                              recentPaymentsSection,
                              const SizedBox(height: 16),
                              maintenanceSection,
                              const SizedBox(height: 16),
                              expensesSection,
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
                    const QuickLinks(links: _ownerQuickLinks),
                    const SizedBox(height: 16),
                    kpiRow,
                    const SizedBox(height: 16),
                    chartCard,
                    const SizedBox(height: 16),
                    recentPaymentsSection,
                    const SizedBox(height: 16),
                    maintenanceSection,
                    const SizedBox(height: 16),
                    expensesSection,
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

class _HeroRevenueCard extends StatelessWidget {
  const _HeroRevenueCard({required this.dashboard});

  final OwnerDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final isUp = dashboard.revenueVariationPercent >= 0;

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
          const Text(
            'Revenus du mois',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            _currency.format(dashboard.monthlyRevenue),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (isUp ? AppColors.success : AppColors.warning).withValues(
                alpha: 0.2,
              ),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${isUp ? '+' : ''}${dashboard.revenueVariationPercent.toStringAsFixed(1)}% vs mois dernier',
              style: TextStyle(
                color: isUp
                    ? Colors.greenAccent.shade100
                    : Colors.orange.shade100,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.dashboard, required this.compact});

  final OwnerDashboard dashboard;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cards = [
      KpiCard(
        label: "Taux d'occupation",
        value: '${dashboard.occupancyRate.toStringAsFixed(0)}%',
        icon: Icons.home_work_outlined,
        progress: dashboard.occupancyRate / 100,
      ),
      KpiCard(
        label: 'Paiements en attente',
        value: '${dashboard.pendingPaymentsCount}',
        icon: Icons.hourglass_empty,
        valueColor: dashboard.pendingPaymentsCount > 0
            ? AppColors.warning
            : AppColors.textPrimary,
      ),
      KpiCard(
        label: 'Biens disponibles',
        value: '${dashboard.availablePropertiesCount}',
        icon: Icons.villa_outlined,
      ),
    ];

    if (compact) {
      return SizedBox(
        height: 118,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: cards.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, index) =>
              SizedBox(width: 168, child: cards[index]),
        ),
      );
    }

    return Row(
      children: cards
          .map(
            (card) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: card,
              ),
            ),
          )
          .toList(),
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
                  'Paiements récents',
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
                        payment.propertyTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

class _ExpensesSection extends StatelessWidget {
  const _ExpensesSection({
    required this.expensesAsync,
    required this.monthlyRevenue,
  });

  final AsyncValue<List<Expense>> expensesAsync;
  final double monthlyRevenue;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Charges', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          expensesAsync.when(
            loading: () => const SkeletonList(),
            error: (error, _) => Text(
              friendlyErrorMessage(error),
              style: const TextStyle(color: AppColors.error),
            ),
            data: (expenses) {
              final total = expenses.fold<double>(
                0,
                (sum, expense) => sum + expense.amount,
              );
              final netBalance = monthlyRevenue - total;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _ExpenseFigure(
                          label: 'Charges totales',
                          value: _currency.format(total),
                          color: AppColors.error,
                        ),
                      ),
                      Expanded(
                        child: _ExpenseFigure(
                          label: 'Solde net',
                          value: _currency.format(netBalance),
                          color: netBalance >= 0
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  if (expenses.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        'Aucune charge enregistrée.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  else
                    ...expenses
                        .take(3)
                        .map(
                          (expense) => Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${expense.property.title} · ${expense.category.label}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _currency.format(expense.amount),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ExpenseFigure extends StatelessWidget {
  const _ExpenseFigure({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
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
                  'Demandes de maintenance en cours',
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
