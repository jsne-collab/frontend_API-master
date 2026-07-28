import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_phone_field.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/domain/auth_provider.dart';
import '../../../auth/domain/user_model.dart';
import '../../domain/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _idCardController;
  late String _phone;

  DateTime? _dateOfBirth;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  String? _errorMessage;
  String? _successMessage;

  User get _user => ref.read(authControllerProvider).user!;

  @override
  void initState() {
    super.initState();
    final user = _user;
    _nameController = TextEditingController(text: user.name);
    _emailController = TextEditingController(text: user.email);
    _phone = user.phone;
    _addressController = TextEditingController(
      text: user.profile.address ?? '',
    );
    _cityController = TextEditingController(text: user.profile.city ?? '');
    _idCardController = TextEditingController(
      text: user.profile.idCardNumber ?? '',
    );
    _dateOfBirth = user.profile.dateOfBirth;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _idCardController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _pickAndUploadAvatar() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() {
      _isUploadingAvatar = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(profileControllerProvider)
          .uploadAvatar(_user.id, picked.path);
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Se déconnecter'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await ref.read(profileControllerProvider).updateProfile(_user.id, {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phone,
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'id_card_number': _idCardController.text.trim(),
        if (_dateOfBirth != null)
          'date_of_birth': DateFormat('yyyy-MM-dd').format(_dateOfBirth!),
      });
      if (mounted) {
        setState(() => _successMessage = 'Profil mis à jour avec succès.');
      }
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'À propos',
            onPressed: () => context.push('/about'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: _AvatarPicker(
                    avatarUrl: user.profile.avatarUrl,
                    isUploading: _isUploadingAvatar,
                    onTap: _pickAndUploadAvatar,
                  ),
                ),
                const SizedBox(height: 32),
                if (_errorMessage != null) ...[
                  _Banner(text: _errorMessage!, color: AppColors.error),
                  const SizedBox(height: 16),
                ],
                if (_successMessage != null) ...[
                  _Banner(text: _successMessage!, color: AppColors.success),
                  const SizedBox(height: 16),
                ],
                AppTextField(
                  label: 'Nom complet',
                  controller: _nameController,
                  prefixIcon: const Icon(Icons.badge_outlined),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Ce champ est requis.'
                      : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ce champ est requis.';
                    }
                    if (!value.contains('@')) return 'Email invalide.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppPhoneField(
                  label: 'Téléphone',
                  initialValue: _phone,
                  onChanged: (phone) => _phone = phone.completeNumber,
                  validator: (phone) =>
                      (phone == null || phone.number.trim().isEmpty)
                      ? 'Ce champ est requis.'
                      : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Adresse',
                  controller: _addressController,
                  prefixIcon: const Icon(Icons.home_outlined),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Ville',
                  controller: _cityController,
                  prefixIcon: const Icon(Icons.location_city_outlined),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: "Numéro de pièce d'identité",
                  controller: _idCardController,
                  prefixIcon: const Icon(Icons.credit_card_outlined),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _pickDateOfBirth,
                  borderRadius: BorderRadius.circular(10),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date de naissance',
                      prefixIcon: Icon(Icons.cake_outlined),
                    ),
                    child: Text(
                      _dateOfBirth != null
                          ? DateFormat('dd/MM/yyyy').format(_dateOfBirth!)
                          : 'Non renseignée',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'Enregistrer',
                  isLoading: _isSaving,
                  onPressed: _submit,
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Changer le mot de passe',
                  variant: AppButtonVariant.outline,
                  onPressed: () => context.push('/profile/change-password'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({
    required this.avatarUrl,
    required this.isUploading,
    required this.onTap,
  });

  final String? avatarUrl;
  final bool isUploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.primaryLight,
            backgroundImage: avatarUrl != null
                ? CachedNetworkImageProvider(avatarUrl!)
                : null,
            child: avatarUrl == null
                ? const Icon(Icons.person, size: 48, color: Colors.white)
                : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: isUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : const Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: AppColors.primary,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: TextStyle(color: color)),
    );
  }
}
