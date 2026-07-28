import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/domain/auth_provider.dart';
import '../../../auth/domain/user_model.dart';
import '../../domain/lease_model.dart';
import '../../domain/lease_provider.dart';
import '../../../../core/network/error_message.dart';

class LeaseListScreen extends ConsumerWidget {
  const LeaseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leasesAsync = ref.watch(myLeasesProvider);
    final isOwner =
        ref.watch(authControllerProvider).user?.role == UserRole.owner;

    return AppScaffold(
      currentRoute: '/leases',
      appBar: AppBar(title: const Text('Mes baux')),
      floatingActionButton: isOwner
          ? FloatingActionButton(
              onPressed: () => context.push('/leases/create'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(myLeasesProvider.notifier).refresh(),
          child: leasesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _ErrorState(
              message: friendlyErrorMessage(error),
              onRetry: () => ref.read(myLeasesProvider.notifier).refresh(),
            ),
            data: (leases) => leases.isEmpty
                ? _EmptyState(isOwner: isOwner)
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: leases.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _LeaseCard(lease: leases[index], isOwner: isOwner),
                  ),
          ),
        ),
      ),
    );
  }
}

class _LeaseCard extends StatelessWidget {
  const _LeaseCard({required this.lease, required this.isOwner});

  final Lease lease;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd/MM/yyyy');
    final counterparty = isOwner ? lease.tenant : lease.owner;

    return AppCard(
      onTap: () => context.push('/leases/${lease.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  lease.property.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              StatusBadge(
                label: lease.status.label,
                tone: _toneFor(lease.status),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isOwner
                ? 'Locataire : ${counterparty.name}'
                : 'Propriétaire : ${counterparty.name}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${dateFormat.format(lease.startDate)} → ${dateFormat.format(lease.endDate)}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                '${currency.format(lease.monthlyRent)}/mois',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  StatusTone _toneFor(LeaseStatus status) => switch (status) {
    LeaseStatus.active => StatusTone.success,
    LeaseStatus.pending => StatusTone.warning,
    LeaseStatus.terminated => StatusTone.error,
    LeaseStatus.expired => StatusTone.neutral,
  };
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isOwner});

  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.description_outlined,
              size: 56,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              isOwner
                  ? "Vous n'avez pas encore de bail.\nAppuyez sur + pour en créer un."
                  : "Vous n'avez pas encore de bail actif.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: 16),
            TextButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}
