import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../leases/domain/lease_model.dart';
import '../../../leases/domain/lease_provider.dart';
import '../../domain/maintenance_model.dart';
import '../../domain/maintenance_provider.dart';
import '../../../../core/network/error_message.dart';

class MaintenanceCreateScreen extends ConsumerStatefulWidget {
  const MaintenanceCreateScreen({super.key});

  @override
  ConsumerState<MaintenanceCreateScreen> createState() =>
      _MaintenanceCreateScreenState();
}

class _MaintenanceCreateScreenState
    extends ConsumerState<MaintenanceCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  Lease? _selectedLease;
  MaintenancePriority _priority = MaintenancePriority.medium;
  XFile? _photo;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) setState(() => _photo = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLease == null) {
      setState(() => _errorMessage = 'Sélectionnez un bien.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref.read(maintenanceRepositoryProvider).create({
        'property_id': _selectedLease!.property.id,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'priority': _priority.name,
      }, photoPath: _photo?.path);

      await ref.read(myMaintenanceRequestsProvider.notifier).refresh();
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
      appBar: AppBar(title: const Text('Signaler un problème')),
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
                leasesAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (error, _) => Text(friendlyErrorMessage(error)),
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
                      onChanged: (value) =>
                          setState(() => _selectedLease = value),
                    );
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Titre',
                  controller: _titleController,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Ce champ est requis.'
                      : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Description',
                  controller: _descriptionController,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Ce champ est requis.'
                      : null,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Priorité',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<MaintenancePriority>(
                  initialValue: _priority,
                  items: MaintenancePriority.values
                      .map(
                        (priority) => DropdownMenuItem(
                          value: priority,
                          child: Text(priority.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _priority = value);
                  },
                ),
                const SizedBox(height: 20),
                const Text('Photo (optionnel)', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                if (_photo != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(_photo!.path),
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 8),
                AppButton(
                  label: _photo == null ? 'Ajouter une photo' : 'Changer la photo',
                  variant: AppButtonVariant.outline,
                  onPressed: _pickPhoto,
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'Envoyer la demande',
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
