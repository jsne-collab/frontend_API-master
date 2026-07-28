import 'package:flutter/material.dart';

/// Logo responsive pour les écrans sur fond clair (Connexion, Inscription) :
/// icône seule (badge navy + marque dorée) en `compact`, lockup complet
/// (icône + nom) dès `medium`/`expanded` où la place verticale ne manque
/// plus. Toujours `BoxFit.contain`, jamais étiré.
class BrandedHeader extends StatelessWidget {
  const BrandedHeader({super.key, this.compactHeight = 64, this.fullWidth = 220});

  final double compactHeight;
  final double fullWidth;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 600;

    if (isCompact) {
      return Image.asset(
        'assets/branding/Logo_Icone_512_Transparent.png',
        height: compactHeight,
        fit: BoxFit.contain,
      );
    }

    return Image.asset(
      'assets/branding/Logo_Complet_2400.png',
      width: fullWidth,
      fit: BoxFit.contain,
    );
  }
}
