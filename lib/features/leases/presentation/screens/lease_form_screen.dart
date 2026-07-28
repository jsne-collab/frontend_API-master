import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/domain/user_model.dart';
import '../../../properties/domain/property_model.dart';
import '../../../properties/domain/property_provider.dart';
import '../../domain/lease_provider.dart';
import '../../../../core/network/error_message.dart';

/// Écran unique pour créer un bail (leaseId == null) ou en modifier les
/// conditions (leaseId renseigné : dates/loyer/caution uniquement, le bien
/// et le locataire ne changent jamais après coup).
class LeaseFormScreen extends ConsumerStatefulWidget {
  const LeaseFormScreen({super.key, this.leaseId});

  final int? leaseId;

  bool get isEditing => leaseId != null;

  @override
  ConsumerState<LeaseFormScreen> createState() => _LeaseFormScreenState();
}

class _LeaseFormScreenState extends ConsumerState<LeaseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _rentController = TextEditingController();
  final _depositController = TextEditingController();
  final _guarantorNameController = TextEditingController();
  final _guarantorPhoneController = TextEditingController();
  final _occupationController = TextEditingController();
  final _monthlyIncomeController = TextEditingController();
  final _tenantSearchController = TextEditingController();

  Property? _selectedProperty;
  User? _selectedTenant;
  List<User> _tenantResults = [];
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSearchingTenant = false;
  bool _isSaving = false;
  bool _isLoadingInitial = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) _loadExisting();
  }

  Future<void> _loadExisting() async {
    setState(() => _isLoadingInitial = true);
    try {
      final lease = await ref
          .read(leaseRepositoryProvider)
          .show(widget.leaseId!);
      _rentController.text = lease.monthlyRent.toStringAsFixed(0);
      _depositController.text = lease.depositAmount.toStringAsFixed(0);
      _startDate = lease.startDate;
      _endDate = lease.endDate;
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isLoadingInitial = false);
    }
  }

  @override
  void dispose() {
    _rentController.dispose();
    _depositController.dispose();
    _guarantorNameController.dispose();
    _guarantorPhoneController.dispose();
    _occupationController.dispose();
    _monthlyIncomeController.dispose();
    _tenantSearchController.dispose();
    super.dispose();
  }

  Future<void> _searchTenant() async {
    final query = _tenantSearchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearchingTenant = true;
      _errorMessage = null;
    });

    try {
      final results = await ref.read(tenantSearchApiProvider).search(query);
      setState(() => _tenantResults = results);
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isSearchingTenant = false);
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!widget.isEditing && _selectedProperty == null) {
      setState(() => _errorMessage = 'Sélectionnez un bien.');
      return;
    }
    if (!widget.isEditing && _selectedTenant == null) {
      setState(() => _errorMessage = 'Sélectionnez un locataire.');
      return;
    }
    if (_startDate == null || _endDate == null) {
      setState(
        () => _errorMessage = 'Renseignez les dates de début et de fin.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final dateFormat = DateFormat('yyyy-MM-dd');

    try {
      final repository = ref.read(leaseRepositoryProvider);

      if (widget.isEditing) {
        await repository.update(widget.leaseId!, {
          'start_date': dateFormat.format(_startDate!),
          'end_date': dateFormat.format(_endDate!),
          'monthly_rent': double.parse(_rentController.text),
          'deposit_amount': double.parse(_depositController.text),
        });
        ref.invalidate(leaseDetailProvider(widget.leaseId!));
      } else {
        await repository.create({
          'property_id': _selectedProperty!.id,
          'tenant_id': _selectedTenant!.id,
          'start_date': dateFormat.format(_startDate!),
          'end_date': dateFormat.format(_endDate!),
          'monthly_rent': double.parse(_rentController.text),
          'deposit_amount': double.parse(_depositController.text),
          if (_guarantorNameController.text.trim().isNotEmpty)
            'guarantor_name': _guarantorNameController.text.trim(),
          if (_guarantorPhoneController.text.trim().isNotEmpty)
            'guarantor_phone': _guarantorPhoneController.text.trim(),
          if (_occupationController.text.trim().isNotEmpty)
            'occupation': _occupationController.text.trim(),
          if (_monthlyIncomeController.text.trim().isNotEmpty)
            'monthly_income': double.parse(
              _monthlyIncomeController.text.trim(),
            ),
        });
      }

      await ref.read(myLeasesProvider.notifier).refresh();
      if (mounted) context.pop();
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myProperties = ref.watch(myPropertiesProvider);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Modifier le bail' : 'Créer un bail'),
      ),
      body: SafeArea(
        child: _isLoadingInitial
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
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
                      if (!widget.isEditing) ...[
                        const Text(
                          'Bien',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        myProperties.when(
                          loading: () => const CircularProgressIndicator(),
                          error: (error, _) =>
                              Text(friendlyErrorMessage(error)),
                          data: (properties) =>
                              DropdownButtonFormField<Property>(
                                initialValue: _selectedProperty,
                                decoration: const InputDecoration(
                                  hintText: 'Sélectionner un bien',
                                ),
                                items: properties
                                    .map(
                                      (p) => DropdownMenuItem(
                                        value: p,
                                        child: Text(p.title),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedProperty = value;
                                    if (value != null) {
                                      _rentController.text = value.monthlyRent
                                          .toStringAsFixed(0);
                                      _depositController.text = value
                                          .depositAmount
                                          .toStringAsFixed(0);
                                    }
                                  });
                                },
                              ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Locataire',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                label: 'Nom, email ou téléphone',
                                controller: _tenantSearchController,
                                prefixIcon: const Icon(Icons.search),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              onPressed: _isSearchingTenant
                                  ? null
                                  : _searchTenant,
                              icon: _isSearchingTenant
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.arrow_forward),
                            ),
                          ],
                        ),
                        if (_tenantResults.isNotEmpty)
                          ..._tenantResults.map(
                            (tenant) => ListTile(
                              onTap: () => setState(() {
                                _selectedTenant = tenant;
                                _tenantResults = [];
                                _tenantSearchController.text = tenant.name;
                              }),
                              leading: const Icon(Icons.person_outline),
                              title: Text(tenant.name),
                              subtitle: Text(tenant.phone),
                            ),
                          ),
                        if (_selectedTenant != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Locataire sélectionné : ${_selectedTenant!.name}',
                              style: const TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: _DatePickerField(
                              label: 'Date de début',
                              value: _startDate,
                              formatted: _startDate != null
                                  ? dateFormat.format(_startDate!)
                                  : null,
                              onTap: () => _pickDate(isStart: true),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _DatePickerField(
                              label: 'Date de fin',
                              value: _endDate,
                              formatted: _endDate != null
                                  ? dateFormat.format(_endDate!)
                                  : null,
                              onTap: () => _pickDate(isStart: false),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Loyer mensuel (FCFA)',
                        controller: _rentController,
                        keyboardType: TextInputType.number,
                        validator: _numberValidator,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Caution (FCFA)',
                        controller: _depositController,
                        keyboardType: TextInputType.number,
                        validator: _numberValidator,
                      ),
                      if (!widget.isEditing) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'Garant (optionnel)',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        AppTextField(
                          label: 'Nom du garant',
                          controller: _guarantorNameController,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Téléphone du garant',
                          controller: _guarantorPhoneController,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Profession du locataire',
                          controller: _occupationController,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Revenu mensuel du locataire (FCFA)',
                          controller: _monthlyIncomeController,
                          keyboardType: TextInputType.number,
                        ),
                      ],
                      const SizedBox(height: 24),
                      AppButton(
                        label: widget.isEditing
                            ? 'Enregistrer'
                            : 'Créer le bail',
                        isLoading: _isSaving,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  String? _numberValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Ce champ est requis.';
    if (double.tryParse(value.trim()) == null) return 'Nombre invalide.';
    return null;
  }
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.value,
    required this.formatted,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final String? formatted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(formatted ?? 'Choisir'),
      ),
    );
  }
}
