import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';

class QuickLink {
  const QuickLink({required this.icon, required this.label, required this.route});

  final IconData icon;
  final String label;
  final String route;
}

/// Accès rapides vers les modules qui n'ont pas encore de barre de
/// navigation dédiée (prévue en finitions) — évite de perdre l'accès à
/// Biens/Baux/Quittances/Messages en remplaçant l'accueil placeholder.
class QuickLinks extends StatelessWidget {
  const QuickLinks({super.key, required this.links});

  final List<QuickLink> links;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: Row(
        children: links
            .map(
              (link) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => context.push(link.route),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(link.icon, color: AppColors.primary, size: 22),
                          const SizedBox(height: 6),
                          Text(
                            link.label,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
