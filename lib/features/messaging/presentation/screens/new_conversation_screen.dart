import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../auth/domain/auth_provider.dart';
import '../../../auth/domain/user_model.dart';
import '../../../leases/domain/lease_model.dart';
import '../../../leases/domain/lease_provider.dart';
import '../../../../core/network/error_message.dart';
import '../../../../core/widgets/skeleton.dart';

/// Sélection d'un interlocuteur pour démarrer une conversation — limité
/// aux propriétaires/locataires liés par un bail (comme imposé côté API).
class NewConversationScreen extends ConsumerWidget {
  const NewConversationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leasesAsync = ref.watch(myLeasesProvider);
    final isOwner =
        ref.watch(authControllerProvider).user?.role == UserRole.owner;

    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau message')),
      body: SafeArea(
        child: leasesAsync.when(
          loading: () => const SkeletonList(),
          error: (error, _) => Center(
            child: Text(
              friendlyErrorMessage(error),
              style: const TextStyle(color: AppColors.error),
            ),
          ),
          data: (leases) {
            final counterparts = <int, LeasePerson>{};
            for (final lease in leases) {
              final other = isOwner ? lease.tenant : lease.owner;
              counterparts[other.id] = other;
            }

            if (counterparts.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    "Vous n'avez personne à contacter pour l'instant.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: counterparts.values
                  .map(
                    (person) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppCard(
                        onTap: () => context.pushReplacement(
                          '/messages/${person.id}',
                          extra: person.name,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    person.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    isOwner ? 'Locataire' : 'Propriétaire',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ),
    );
  }
}
