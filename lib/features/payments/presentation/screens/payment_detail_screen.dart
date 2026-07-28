import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/domain/auth_provider.dart';
import '../../../auth/domain/user_model.dart';
import '../../../receipts/domain/receipt_provider.dart';
import '../../domain/payment_model.dart';
import '../../domain/payment_provider.dart';
import '../../../../core/network/error_message.dart';

final _currency = NumberFormat.currency(
  locale: 'fr_FR',
  symbol: 'FCFA',
  decimalDigits: 0,
);
final _dateFormat = DateFormat('dd/MM/yyyy');

class PaymentDetailScreen extends ConsumerStatefulWidget {
  const PaymentDetailScreen({super.key, required this.paymentId});

  final int paymentId;

  @override
  ConsumerState<PaymentDetailScreen> createState() =>
      _PaymentDetailScreenState();
}

class _PaymentDetailScreenState extends ConsumerState<PaymentDetailScreen> {
  bool _isValidating = false;

  Future<void> _validate() async {
    setState(() => _isValidating = true);
    try {
      await ref.read(paymentRepositoryProvider).update(widget.paymentId, {
        'status': 'validated',
      });
      ref.invalidate(paymentDetailProvider(widget.paymentId));
      await ref.read(myPaymentsProvider.notifier).refresh();
      ref.invalidate(paymentStatsProvider);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _isValidating = false);
    }
  }

  StatusTone _toneFor(PaymentStatus status) => switch (status) {
    PaymentStatus.validated => StatusTone.success,
    PaymentStatus.pending => StatusTone.warning,
    PaymentStatus.late => StatusTone.error,
    PaymentStatus.partial => StatusTone.warning,
  };

  @override
  Widget build(BuildContext context) {
    final paymentAsync = ref.watch(paymentDetailProvider(widget.paymentId));
    final isOwner =
        ref.watch(authControllerProvider).user?.role == UserRole.owner;

    return Scaffold(
      appBar: AppBar(title: const Text('Détail du paiement')),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: paymentAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                friendlyErrorMessage(error),
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ),
          data: (payment) => ListView(
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
                            payment.propertyTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        StatusBadge(
                          label: payment.status.label,
                          tone: _toneFor(payment.status),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _currency.format(payment.amount),
                      style: TextStyle(
                        color: payment.status == PaymentStatus.validated
                            ? AppColors.accent
                            : AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _InfoRow(label: 'Période couverte', value: payment.periodCovered),
                    _InfoRow(
                      label: 'Date de paiement',
                      value: _dateFormat.format(payment.paymentDate),
                    ),
                    if (isOwner)
                      _InfoRow(label: 'Locataire', value: payment.tenantName),
                    if (payment.paymentMethod != null)
                      _InfoRow(
                        label: 'Moyen de paiement',
                        value: payment.paymentMethod!.provider != null
                            ? '${payment.paymentMethod!.type.label} (${payment.paymentMethod!.provider})'
                            : payment.paymentMethod!.type.label,
                      ),
                    if (payment.reference != null)
                      _InfoRow(label: 'Référence', value: payment.reference!),
                  ],
                ),
              ),
              if (payment.status == PaymentStatus.validated) ...[
                const SizedBox(height: 16),
                _ReceiptCta(paymentId: payment.id),
              ],
              if (isOwner && payment.status == PaymentStatus.pending) ...[
                const SizedBox(height: 16),
                AppButton(
                  label: 'Valider ce paiement',
                  isLoading: _isValidating,
                  onPressed: _validate,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptCta extends ConsumerWidget {
  const _ReceiptCta({required this.paymentId});

  final int paymentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptsAsync = ref.watch(myReceiptsProvider);

    return receiptsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, _) => const SizedBox.shrink(),
      data: (receipts) {
        final matches = receipts.where((r) => r.payment.id == paymentId);
        if (matches.isEmpty) return const SizedBox.shrink();
        final receipt = matches.first;

        return AppButton(
          label: 'Voir la quittance',
          variant: AppButtonVariant.outline,
          onPressed: () => context.push(
            '/receipts/${receipt.id}/view',
            extra: receipt.pdfUrl,
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
