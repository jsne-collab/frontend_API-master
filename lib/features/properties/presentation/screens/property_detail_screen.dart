import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/domain/auth_provider.dart';
import '../../domain/property_model.dart';
import '../../domain/property_provider.dart';

class PropertyDetailScreen extends ConsumerStatefulWidget {
  const PropertyDetailScreen({super.key, required this.propertyId});

  final int propertyId;

  @override
  ConsumerState<PropertyDetailScreen> createState() =>
      _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends ConsumerState<PropertyDetailScreen> {
  bool _isUploadingImage = false;

  Future<void> _addPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _isUploadingImage = true);

    try {
      await ref
          .read(propertyRepositoryProvider)
          .uploadImage(widget.propertyId, picked.path);
      ref.invalidate(propertyDetailProvider(widget.propertyId));
      await ref.read(myPropertiesProvider.notifier).refresh();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _deletePhoto(int imageId) async {
    try {
      await ref
          .read(propertyRepositoryProvider)
          .deleteImage(widget.propertyId, imageId);
      ref.invalidate(propertyDetailProvider(widget.propertyId));
      await ref.read(myPropertiesProvider.notifier).refresh();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _confirmDeleteProperty() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce bien ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(propertyRepositoryProvider).delete(widget.propertyId);
      await ref.read(myPropertiesProvider.notifier).refresh();
      if (mounted) context.pop();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final propertyAsync = ref.watch(propertyDetailProvider(widget.propertyId));
    final currentUserId = ref.watch(authControllerProvider).user?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Détail du bien')),
      body: propertyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (property) {
          final isOwner = property.ownerId == currentUserId;

          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Gallery(
                    property: property,
                    isOwner: isOwner,
                    isUploading: _isUploadingImage,
                    onAddPhoto: _addPhoto,
                    onDeletePhoto: _deletePhoto,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                property.title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            StatusBadge(
                              label: property.status.label,
                              tone: switch (property.status) {
                                PropertyStatus.available => StatusTone.success,
                                PropertyStatus.maintenance =>
                                  StatusTone.warning,
                                PropertyStatus.rented => StatusTone.neutral,
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${property.address}, ${property.city}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 24,
                          runSpacing: 12,
                          children: [
                            _InfoChip(
                              icon: Icons.category_outlined,
                              label: property.type.label,
                            ),
                            _InfoChip(
                              icon: Icons.bed_outlined,
                              label: '${property.roomsCount} pièces',
                            ),
                            if (property.surfaceArea != null)
                              _InfoChip(
                                icon: Icons.square_foot_outlined,
                                label:
                                    '${property.surfaceArea!.toStringAsFixed(0)} m²',
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _PriceRow(property: property),
                        if (property.description != null &&
                            property.description!.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const Text(
                            'Description',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            property.description!,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        if (isOwner) ...[
                          const SizedBox(height: 32),
                          AppButton(
                            label: 'Modifier',
                            variant: AppButtonVariant.outline,
                            onPressed: () =>
                                context.push('/properties/${property.id}/edit'),
                          ),
                          const SizedBox(height: 12),
                          AppButton(
                            label: 'Supprimer ce bien',
                            variant: AppButtonVariant.outline,
                            onPressed: _confirmDeleteProperty,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Gallery extends StatelessWidget {
  const _Gallery({
    required this.property,
    required this.isOwner,
    required this.isUploading,
    required this.onAddPhoto,
    required this.onDeletePhoto,
  });

  final Property property;
  final bool isOwner;
  final bool isUploading;
  final VoidCallback onAddPhoto;
  final ValueChanged<int> onDeletePhoto;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          ...property.images.map(
            (image) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: image.url,
                      width: 260,
                      height: 190,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (isOwner)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: GestureDetector(
                        onTap: () => onDeletePhoto(image.id),
                        child: const CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.black54,
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isOwner)
            GestureDetector(
              onTap: isUploading ? null : onAddPhoto,
              child: Container(
                width: 120,
                height: 190,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                  ),
                ),
                child: isUploading
                    ? const Center(child: CircularProgressIndicator())
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Ajouter',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          if (property.images.isEmpty && !isOwner)
            Container(
              width: 260,
              height: 190,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.home_work_outlined,
                color: Colors.white,
                size: 48,
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.property});

  final Property property;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
      decimalDigits: 0,
    );

    return Row(
      children: [
        Expanded(
          child: _AmountBlock(
            label: 'Loyer mensuel',
            amount: currency.format(property.monthlyRent),
          ),
        ),
        Expanded(
          child: _AmountBlock(
            label: 'Caution',
            amount: currency.format(property.depositAmount),
          ),
        ),
      ],
    );
  }
}

class _AmountBlock extends StatelessWidget {
  const _AmountBlock({required this.label, required this.amount});

  final String label;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
