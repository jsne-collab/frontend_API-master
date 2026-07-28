import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_phone_field.dart';
import '../../../../core/widgets/max_width_body.dart';
import '../../domain/auth_provider.dart';
import '../../domain/user_model.dart';
import '../widgets/role_selector.dart';
import '../widgets/terms_checkbox.dart';

/// Étape obligatoire après une première connexion Google : Google ne
/// fournit ni le rôle ni le téléphone, tous deux indispensables au reste
/// de l'app. Aucun moyen de contourner cet écran — pas de bouton retour,
/// pas de fermeture (le middleware backend bloque aussi toute autre
/// route tant que ce n'est pas complété, en plus de la garde go_router).
class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String _phone = '';

  UserRole _role = UserRole.tenant;
  bool _isLoading = false;
  bool _termsAccepted = false;
  String? _errorMessage;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_termsAccepted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Ne navigue pas explicitement : le passage de profile_completed à
      // true déclenche la redirection via le refreshListenable du router
      // (même mécanisme que login/register), qui bascule automatiquement
      // vers /owner/home ou /tenant/home.
      await ref
          .read(authControllerProvider.notifier)
          .completeProfile(role: _role, phone: _phone);
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final firstName = (user?.name ?? '').split(' ').first;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: MaxWidthBody(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Center(
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.primaryLight,
                        backgroundImage: user?.profile.avatarUrl != null
                            ? CachedNetworkImageProvider(
                                user!.profile.avatarUrl!,
                              )
                            : null,
                        child: user?.profile.avatarUrl == null
                            ? const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Bienvenue $firstName, encore une étape',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Complète ton profil pour accéder à Gestion Locative.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 32),
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
                    RoleSelector(
                      role: _role,
                      onChanged: (role) => setState(() => _role = role),
                    ),
                    const SizedBox(height: 16),
                    AppPhoneField(
                      label: 'Téléphone',
                      onChanged: (phone) => _phone = phone.completeNumber,
                      validator: (phone) =>
                          (phone == null || phone.number.trim().isEmpty)
                          ? 'Ce champ est requis.'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    TermsCheckbox(
                      accepted: _termsAccepted,
                      onChanged: (value) =>
                          setState(() => _termsAccepted = value),
                    ),
                    const SizedBox(height: 20),
                    AppButton(
                      label: 'Terminer mon inscription',
                      isLoading: _isLoading,
                      onPressed: _termsAccepted ? _submit : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
