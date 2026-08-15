import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Ton sémantique d'un statut métier (paiement, bail, maintenance...).
enum StatusTone { success, warning, error, neutral }

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.tone});

  final String label;
  final StatusTone tone;

  Color get _color => switch (tone) {
    StatusTone.success => AppColors.success,
    StatusTone.warning => AppColors.warning,
    StatusTone.error => AppColors.error,
    StatusTone.neutral => AppColors.textSecondary,
  };
///petit badge pour indiquer le statut d'un élément (paiement, bail, maintenance...) avec un code couleur
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
