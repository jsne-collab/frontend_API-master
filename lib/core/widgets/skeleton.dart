import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';

/// Un bloc gris arrondi, à assembler pour dessiner la silhouette d'un écran
/// pendant son chargement (remplace le simple spinner générique par un
/// aperçu de la mise en page réelle — perçu comme plus premium).
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 8,
  });
///effet de chargement
  final double? width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Silhouette d'une ligne de liste : icône + deux lignes de texte, comme la
/// plupart des `AppCard` de listes (biens, baux, paiements, maintenance...).
class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          const SkeletonBox(width: 44, height: 44, borderRadius: 12),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: double.infinity, height: 14),
                const SizedBox(height: 8),
                SkeletonBox(width: MediaQuery.of(context).size.width * 0.35),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Enrobe une silhouette (`child`) de l'effet de balayage lumineux — à
/// utiliser comme état `loading:` d'un `.when()` à la place d'un spinner nu.
class SkeletonLoader extends StatelessWidget {
  const SkeletonLoader({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Shimmer.fromColors(
        baseColor: AppColors.background,
        highlightColor: Colors.white,
        child: child,
      ),
    );
  }
}

/// Silhouette générique pour un écran de liste : `count` lignes empilées.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 6});

  final int count;

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: Column(
        children: List.generate(count, (_) => const SkeletonListTile()),
      ),
    );
  }
}
