import 'package:flutter/material.dart';

/// Contraint la largeur d'un contenu (formulaires d'authentification) sans
/// jamais l'étirer bord à bord au-delà de la taille d'un téléphone, même
/// sur un écran large — largeur pleine à l'intérieur de cette contrainte.
class MaxWidthBody extends StatelessWidget {
  const MaxWidthBody({super.key, required this.child, this.maxWidth = 440});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
