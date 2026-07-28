import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/property_model.dart';
import '../../domain/property_provider.dart';

/// Écran unique pour créer un bien (propertyId == null) ou le modifier
/// (propertyId renseigné, formulaire pré-rempli).
class PropertyFormScreen extends ConsumerStatefulWidget {
  const PropertyFormScreen({super.key, this.propertyId});

  final int? propertyId;

  bool get isEditing => propertyId != null;

  @override
  ConsumerState<PropertyFormScreen> createState() => _PropertyFormScreenState();
}

class _PropertyFormScreenState extends ConsumerState<PropertyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _surfaceController = TextEditingController();
  final _roomsController = TextEditingController(text: '1');
  final _rentController = TextEditingController();
  final _depositController = TextEditingController();
  final _descriptionController = TextEditingController();

  PropertyType _type = PropertyType.appartement;
  bool _isLoadingInitial = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) _loadExisting();
  }

  Future<void> _loadExisting() async {
    setState(() => _isLoadingInitial = true);
    try {
      final property = await ref
          .read(propertyRepositoryProvider)
          .show(widget.propertyId!);
      _titleController.text = property.title;
      _addressController.text = property.address;
      _cityController.text = property.city;
      _surfaceController.text = property.surfaceArea?.toStringAsFixed(0) ?? '';
      _roomsController.text = property.roomsCount.toString();
      _rentController.text = property.monthlyRent.toStringAsFixed(0);
      _depositController.text = property.depositAmount.toStringAsFixed(0);
      _descriptionController.text = property.description ?? '';
      _type = property.type;
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isLoadingInitial = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _surfaceController.dispose();
    _roomsController.dispose();
    _rentController.dispose();
    _depositController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final data = {
      'title': _titleController.text.trim(),
      'type': _type.name,
      'address': _addressController.text.trim(),
      'city': _cityController.text.trim(),
      'rooms_count': int.parse(_roomsController.text),
      'monthly_rent': double.parse(_rentController.text),
      'deposit_amount': double.parse(_depositController.text),
      if (_surfaceController.text.trim().isNotEmpty)
        'surface_area': double.parse(_surfaceController.text.trim()),
      if (_descriptionController.text.trim().isNotEmpty)
        'description': _descriptionController.text.trim(),
    };

    try {
      final repository = ref.read(propertyRepositoryProvider);
      final Property saved;
      if (widget.isEditing) {
        saved = await repository.update(widget.propertyId!, data);
      } else {
        saved = await repository.create(data);
      }

      await ref.read(myPropertiesProvider.notifier).refresh();
      if (widget.isEditing) {
        ref.invalidate(propertyDetailProvider(widget.propertyId!));
      }

      if (mounted) {
        if (widget.isEditing) {
          context.pop();
        } else {
          context.pushReplacement('/properties/${saved.id}');
        }
      }
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _requiredValidator(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Ce champ est requis.' : null;

  String? _numberValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Ce champ est requis.';
    if (double.tryParse(value.trim()) == null) return 'Nombre invalide.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Modifier le bien' : 'Ajouter un bien'),
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
                      AppTextField(
                        label: 'Titre',
                        controller: _titleController,
                        prefixIcon: const Icon(Icons.title),
                        validator: _requiredValidator,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<PropertyType>(
                        initialValue: _type,
                        decoration: const InputDecoration(
                          labelText: 'Type de bien',
                        ),
                        items: PropertyType.values
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(type.label),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => _type = value);
                        },
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Adresse',
                        controller: _addressController,
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        validator: _requiredValidator,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Ville',
                        controller: _cityController,
                        prefixIcon: const Icon(Icons.location_city_outlined),
                        validator: _requiredValidator,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              label: 'Pièces',
                              controller: _roomsController,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Requis.';
                                }
                                if (int.tryParse(value.trim()) == null) {
                                  return 'Invalide.';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AppTextField(
                              label: 'Surface (m²)',
                              controller: _surfaceController,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Loyer mensuel (FCFA)',
                        controller: _rentController,
                        keyboardType: TextInputType.number,
                        prefixIcon: const Icon(Icons.payments_outlined),
                        validator: _numberValidator,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Caution (FCFA)',
                        controller: _depositController,
                        keyboardType: TextInputType.number,
                        prefixIcon: const Icon(Icons.savings_outlined),
                        validator: _numberValidator,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Description (optionnel)',
                        controller: _descriptionController,
                      ),
                      const SizedBox(height: 24),
                      AppButton(
                        label: widget.isEditing
                            ? 'Enregistrer'
                            : 'Créer le bien',
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
}
