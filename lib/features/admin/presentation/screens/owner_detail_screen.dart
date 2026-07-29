import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/error_message.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../subscription/domain/subscription_model.dart';
import '../../domain/admin_provider.dart';

final _currency = NumberFormat.currency(
  locale: 'fr_FR',
  symbol: 'FCFA',
  decimalDigits: 0,
);
final _dateFormat = DateFormat('dd/MM/yyyy');

class OwnerDetailScreen extends ConsumerStatefulWidget {
  const OwnerDetailScreen({super.key, required this.ownerId});

  final int ownerId;

  @override
  ConsumerState<OwnerDetailScreen> createState() => _OwnerDetailScreenState();
}

class _OwnerDetailScreenState extends ConsumerState<OwnerDetailScreen> {
  int? _validatingSubscriptionId;
  String? _errorMessage;

  Future<void> _validate(int subscriptionId) async {
    setState(() {
      _validatingSubscriptionId = subscriptionId;
      _errorMessage = null;
    });

    try {
      await ref
          .read(adminRepositoryProvider)
          .validateSubscription(subscriptionId);
      ref.invalidate(ownerDetailProvider(widget.ownerId));
      ref.invalidate(adminOwnersProvider);
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _validatingSubscriptionId = null);
    }
  }

  StatusTone _tone(String status) => switch (status) {
    'paid' => StatusTone.success,
    'pending' => StatusTone.warning,
    _ => StatusTone.neutral,
  };

  String _label(String status) => switch (status) {
    'paid' => 'Payé',
    'pending' => 'En attente',
    _ => status,
  };

  @override
  Widget build(BuildContext context) {
    final ownerAsync = ref.watch(ownerDetailProvider(widget.ownerId));

    return Scaffold(
      appBar: AppBar(title: const Text('Détail propriétaire')),
      body: SafeArea(
        child: ownerAsync.when(
          loading: () => const SkeletonList(),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                friendlyErrorMessage(error),
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ),
          data: (owner) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            owner.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        StatusBadge(
                          label: owner.subscriptionStatus.label,
                          tone: switch (owner.subscriptionStatus) {
                            SubscriptionStatus.paid => StatusTone.success,
                            SubscriptionStatus.pending => StatusTone.warning,
                            SubscriptionStatus.overdue => StatusTone.error,
                            SubscriptionStatus.never => StatusTone.neutral,
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(owner.email),
                    Text(owner.phone),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Locataires (${owner.leases.length})',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (owner.leases.isEmpty)
                const Text(
                  "Aucun locataire pour l'instant.",
                  style: TextStyle(color: AppColors.textSecondary),
                )
              else
                ...owner.leases.map(
                  (lease) => AppCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lease.tenantName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                lease.propertyTitle,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(_currency.format(lease.monthlyRent)),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                "Historique d'abonnement",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppColors.error),
                ),
                const SizedBox(height: 8),
              ],
              if (owner.subscriptions.isEmpty)
                const Text(
                  'Aucun paiement enregistré.',
                  style: TextStyle(color: AppColors.textSecondary),
                )
              else
                ...owner.subscriptions.map(
                  (subscription) => AppCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_dateFormat.format(subscription.periodStart)} — ${_dateFormat.format(subscription.periodEnd)}',
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _currency.format(subscription.amount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (subscription.status == 'pending')
                          AppButton(
                            label: 'Valider',
                            fullWidth: false,
                            isLoading:
                                _validatingSubscriptionId == subscription.id,
                            onPressed: () => _validate(subscription.id),
                          )
                        else
                          StatusBadge(
                            label: _label(subscription.status),
                            tone: _tone(subscription.status),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
