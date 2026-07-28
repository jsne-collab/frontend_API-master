import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_button.dart';

/// État d'erreur générique pour un écran ou une section (échec réseau,
/// chargement de document...) — jamais le message technique brut d'une
/// exception : un message compréhensible + un bouton Réessayer.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    this.message =
        'Impossible de charger les données. Vérifie ta connexion et réessaie.',
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: 160,
                child: AppButton(
                  label: 'Réessayer',
                  variant: AppButtonVariant.outline,
                  onPressed: onRetry,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
