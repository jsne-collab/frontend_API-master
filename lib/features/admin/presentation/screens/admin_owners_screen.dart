import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/error_message.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/domain/auth_provider.dart';
import '../../../subscription/domain/subscription_model.dart';
import '../../domain/admin_provider.dart';
import '../../domain/owner_overview_model.dart';

/// Écran unique de l'espace admin : tous les propriétaires (avec ou sans
/// locataire) et le statut de leur abonnement plateforme. Pas de barre de
/// navigation dédiée (voir `AppScaffold`) — un seul écran pour l'instant.
class AdminOwnersScreen extends ConsumerWidget {
  const AdminOwnersScreen({super.key});

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Se déconnecter'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownersAsync = ref.watch(adminOwnersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Propriétaires'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
            onPressed: () => _confirmLogout(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(adminOwnersProvider.notifier).refresh(),
          child: ownersAsync.when(
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
            data: (owners) {
              if (owners.isEmpty) {
                return const Center(
                  child: Text(
                    'Aucun propriétaire pour le moment.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: owners.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) =>
                    _OwnerCard(owner: owners[index]),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _OwnerCard extends StatelessWidget {
  const _OwnerCard({required this.owner});

  final OwnerOverview owner;

  StatusTone get _tone => switch (owner.subscriptionStatus) {
    SubscriptionStatus.paid => StatusTone.success,
    SubscriptionStatus.pending => StatusTone.warning,
    SubscriptionStatus.overdue => StatusTone.error,
    SubscriptionStatus.never => StatusTone.neutral,
  };

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.push('/admin/owners/${owner.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  owner.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              StatusBadge(label: owner.subscriptionStatus.label, tone: _tone),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            owner.phone,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${owner.propertiesCount} bien(s) · ${owner.tenantCount} locataire(s)',
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }
}
