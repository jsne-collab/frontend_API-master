import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Remplace l'écran rouge par défaut de Flutter en cas d'erreur de build
/// non interceptée — évite un crash silencieux ou un écran illisible pour
/// l'utilisateur final (branché sur `ErrorWidget.builder` dans `main.dart`).
class ErrorFallback extends StatelessWidget {
  const ErrorFallback({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 40, color: AppColors.error),
          SizedBox(height: 12),
          Text(
            "Une erreur inattendue est survenue.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
