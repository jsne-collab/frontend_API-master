import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../leases/domain/lease_model.dart';
import '../../../leases/domain/lease_provider.dart';
import '../../domain/payment_model.dart';
import '../../domain/payment_provider.dart';

class PaymentInitiateScreen extends ConsumerStatefulWidget {
  const PaymentInitiateScreen({super.key});

  @override
  ConsumerState<PaymentInitiateScreen> createState() =>
      _PaymentInitiateScreenState();
}

class _PaymentInitiateScreenState extends ConsumerState<PaymentInitiateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _periodController = TextEditingController(
    text: DateFormat('yyyy-MM').format(DateTime.now()),
  );
  final _providerController = TextEditingController();
  final _accountController = TextEditingController();

  Lease? _selectedLease;
  PaymentMethodType _methodType = PaymentMethodType.mobileMoney;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _amountController.dispose();
    _periodController.dispose();
    _providerController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLease == null) {
      setState(() => _errorMessage = 'Sélectionnez un bail.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref.read(paymentRepositoryProvider).initiate({
        'lease_id': _selectedLease!.id,
        'amount': double.parse(_amountController.text),
        'period_covered': _periodController.text.trim(),
        'method_type': _methodType.apiValue,
        if (_providerController.text.trim().isNotEmpty)
          'method_provider': _providerController.text.trim(),
        if (_accountController.text.trim().isNotEmpty)
          'method_account_number': _accountController.text.trim(),
      });

      await ref.read(myPaymentsProvider.notifier).refresh();
      ref.invalidate(paymentStatsProvider);
      if (mounted) context.pop();
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final leasesAsync = ref.watch(myLeasesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Payer mon loyer')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                  'Bail',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                leasesAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (error, _) => Text(error.toString()),
                  data: (leases) {
                    final activeLeases = leases
                        .where((lease) => lease.status == LeaseStatus.active)
                        .toList();

                    if (activeLeases.isEmpty) {
                      return const Text(
                        "Vous n'avez pas de bail actif.",
                        style: TextStyle(color: AppColors.textSecondary),
                      );
                    }

                    _selectedLease ??= activeLeases.first;
                    if (_amountController.text.isEmpty) {
                      _amountController.text = _selectedLease!.monthlyRent
                          .toStringAsFixed(0);
                    }

                    return DropdownButtonFormField<Lease>(
                      initialValue: _selectedLease,
                      items: activeLeases
                          .map(
                            (lease) => DropdownMenuItem(
                              value: lease,
                              child: Text(lease.property.title),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() {
                        _selectedLease = value;
                        if (value != null) {
                          _amountController.text = value.monthlyRent
                              .toStringAsFixed(0);
                        }
                      }),
                    );
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Montant (FCFA)',
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ce champ est requis.';
                    }
                    if (double.tryParse(value.trim()) == null) {
                      return 'Nombre invalide.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Période couverte (ex. 2026-07)',
                  controller: _periodController,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Ce champ est requis.'
                      : null,
                ),
                const SizedBox(height: 20),
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
                  label: 'Envoyer le paiement',
                  isLoading: _isSubmitting,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
