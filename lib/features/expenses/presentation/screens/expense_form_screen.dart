import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/error_message.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../dashboard/domain/dashboard_provider.dart';
import '../../../properties/domain/property_model.dart';
import '../../../properties/domain/property_provider.dart';
import '../../domain/expense_model.dart';
import '../../domain/expense_provider.dart';

/// Écran manquant jusqu'ici : le calcul du solde net existait déjà côté
/// dashboard mais aucun écran ne permettait au propriétaire d'enregistrer une
/// charge, donc "Charges totales" restait toujours à 0 en pratique (audit du
/// 13/08/2026).
class ExpenseFormScreen extends ConsumerStatefulWidget {
  const ExpenseFormScreen({super.key});

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  Property? _selectedProperty;
  ExpenseCategory _category = ExpenseCategory.maintenance;
  DateTime _expenseDate = DateTime.now();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() => _expenseDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProperty == null) {
      setState(() => _errorMessage = 'Sélectionnez un bien.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref.read(expenseRepositoryProvider).create({
        'property_id': _selectedProperty!.id,
        'category': _category.name,
        'amount': double.parse(_amountController.text),
        'expense_date': DateFormat('yyyy-MM-dd').format(_expenseDate),
        if (_descriptionController.text.trim().isNotEmpty)
          'description': _descriptionController.text.trim(),
      });

      await ref.read(myExpensesProvider.notifier).refresh();
      ref.invalidate(ownerDashboardProvider);
      if (mounted) context.pop();
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final propertiesAsync = ref.watch(myPropertiesProvider);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter une charge')),
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
                const Text('Bien', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                propertiesAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (error, _) => Text(friendlyErrorMessage(error)),
                  data: (properties) {
                    if (properties.isEmpty) {
                      return const Text(
                        "Vous n'avez pas encore de bien enregistré.",
                        style: TextStyle(color: AppColors.textSecondary),
                      );
                    }

                    _selectedProperty ??= properties.first;

                    return DropdownButtonFormField<Property>(
                      initialValue: _selectedProperty,
                      items: properties
                          .map(
                            (property) => DropdownMenuItem(
                              value: property,
                              child: Text(property.title),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedProperty = value),
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Catégorie',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<ExpenseCategory>(
                  initialValue: _category,
                  items: ExpenseCategory.values
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _category = value);
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
                const Text('Date', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(),
                    child: Text(dateFormat.format(_expenseDate)),
                  ),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Description (optionnel)',
                  controller: _descriptionController,
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'Enregistrer la charge',
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
