import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/error_message.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../payments/domain/payment_model.dart';
import '../../domain/subscription_model.dart';
import '../../domain/subscription_provider.dart';

final _currency = NumberFormat.currency(
  locale: 'fr_FR',
  symbol: 'FCFA',
  decimalDigits: 0,
);

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  final _providerController = TextEditingController();
  final _accountController = TextEditingController();

  PaymentMethodType _methodType = PaymentMethodType.mobileMoney;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _providerController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref.read(subscriptionRepositoryProvider).initiate({
        'method_type': _methodType.apiValue,
        if (_providerController.text.trim().isNotEmpty)
          'method_provider': _providerController.text.trim(),
        if (_accountController.text.trim().isNotEmpty)
          'method_account_number': _accountController.text.trim(),
      });

      await ref.read(subscriptionProvider.notifier).refresh();
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  StatusTone _tone(SubscriptionStatus status) => switch (status) {
    SubscriptionStatus.paid => StatusTone.success,
    SubscriptionStatus.pending => StatusTone.warning,
    SubscriptionStatus.overdue => StatusTone.error,
    SubscriptionStatus.never => StatusTone.neutral,
  };

  @override
  Widget build(BuildContext context) {
    final subscriptionAsync = ref.watch(subscriptionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mon abonnement')),
      body: SafeArea(
        child: subscriptionAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                friendlyErrorMessage(error),
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ),
          data: (subscription) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            "Droits d'utilisation de l'app",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        StatusBadge(
                          label: subscription.status.label,
                          tone: _tone(subscription.status),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _currency.format(subscription.amount),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    if (subscription.nextDueDate != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        subscription.status == SubscriptionStatus.overdue
                            ? 'Échéance dépassée le ${DateFormat('dd/MM/yyyy').format(subscription.nextDueDate!)}'
                            : "Valable jusqu'au ${DateFormat('dd/MM/yyyy').format(subscription.nextDueDate!)}",
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (subscription.status != SubscriptionStatus.pending) ...[
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const Text(
                  'Moyen de paiement',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<PaymentMethodType>(
                  initialValue: _methodType,
                  items: PaymentMethodType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _methodType = value);
                  },
                ),
                if (_methodType != PaymentMethodType.cash) ...[
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Opérateur (ex. Flooz, T-Money)',
                    controller: _providerController,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Numéro de compte / téléphone',
                    controller: _accountController,
                    keyboardType: TextInputType.phone,
                  ),
                ],
                const SizedBox(height: 24),
                AppButton(
                  label: subscription.status == SubscriptionStatus.paid
                      ? 'Renouveler'
                      : 'Payer maintenant',
                  isLoading: _isSubmitting,
                  onPressed: _submit,
                ),
              ] else
                const Text(
                  'Paiement envoyé, en attente de validation par un administrateur.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
