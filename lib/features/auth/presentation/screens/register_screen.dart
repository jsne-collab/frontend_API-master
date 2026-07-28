import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_phone_field.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/branded_header.dart';
import '../../../../core/widgets/max_width_body.dart';
import '../../domain/auth_provider.dart';
import '../../domain/user_model.dart';
import '../widgets/role_selector.dart';
import '../widgets/terms_checkbox.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();
  String _phone = '';

  UserRole _role = UserRole.tenant;
  bool _isLoading = false;
  bool _termsAccepted = false;
  String? _errorMessage;
  Map<String, List<String>> _fieldErrors = const {};

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _fieldErrors = const {};
    });

    try {
      await ref
          .read(authControllerProvider.notifier)
          .register(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phone,
            password: _passwordController.text,
            passwordConfirmation: _passwordConfirmationController.text,
            role: _role,
          );
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _fieldErrors = e.fieldErrors;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 600;
            final blockSpacing = isCompact ? 16.0 : 24.0;

            final form = MaxWidthBody(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: BrandedHeader(compactHeight: 56)),
                    const SizedBox(height: 24),
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
                    AppTextField(
                      label: 'Nom complet',
                      controller: _nameController,
                      prefixIcon: const Icon(Icons.badge_outlined),
                      errorText: _fieldErrors['name']?.first,
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'Ce champ est requis.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Email',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(Icons.email_outlined),
                      errorText: _fieldErrors['email']?.first,
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
                      errorText: _fieldErrors['phone']?.first,
                      onChanged: (phone) => _phone = phone.completeNumber,
                      validator: (phone) =>
                          (phone == null || phone.number.trim().isEmpty)
                          ? 'Ce champ est requis.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Mot de passe',
                      controller: _passwordController,
                      obscureText: true,
                      prefixIcon: const Icon(Icons.lock_outline),
                      errorText: _fieldErrors['password']?.first,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ce champ est requis.';
                        }
                        if (value.length < 8) return '8 caractères minimum.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Confirmer le mot de passe',
                      controller: _passwordConfirmationController,
                      obscureText: true,
                      prefixIcon: const Icon(Icons.lock_outline),
                      validator: (value) => value != _passwordController.text
                          ? 'Les mots de passe ne correspondent pas.'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    TermsCheckbox(
                      accepted: _termsAccepted,
                      onChanged: (value) =>
                          setState(() => _termsAccepted = value),
                    ),
                    SizedBox(height: blockSpacing),
                    AppButton(
                      label: 'Créer mon compte',
                      isLoading: _isLoading,
                      onPressed: _termsAccepted ? _submit : null,
                    ),
                  ],
                ),
              ),
            );

            if (isCompact) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: form,
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 48,
                  ),
                  child: Center(child: form),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
