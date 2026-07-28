import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Écran générique pour un document légal (CGU, politique de
/// confidentialité...). Contenu provisoire pour la soutenance — à faire
/// relire par un juriste avant toute publication sur les stores.
class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.paragraphs,
  });

  final String title;
  final List<String> paragraphs;

  static const termsOfService = LegalDocumentScreen(
    title: 'Conditions Générales d\'Utilisation',
    paragraphs: [
      'Ces Conditions Générales d\'Utilisation ("CGU") régissent l\'accès et '
          'l\'usage de l\'application Gestion Locative par les propriétaires et '
          'les locataires.',
      'En créant un compte, vous confirmez avoir la capacité juridique de '
          'contracter et vous engagez à fournir des informations exactes '
          '(identité, coordonnées, informations relatives aux biens et aux baux).',
      'L\'application met en relation propriétaires et locataires pour la '
          'gestion des baux, des paiements de loyer et des demandes de '
          'maintenance. Gestion Locative n\'est pas partie aux contrats de bail '
          'conclus entre utilisateurs.',
      'Chaque utilisateur est responsable de l\'exactitude des données qu\'il '
          'saisit (montants, dates, documents) et de la conservation de la '
          'confidentialité de ses identifiants de connexion.',
      'Ce document est fourni à titre provisoire dans le cadre du projet '
          'académique et sera complété avant toute mise en production.',
    ],
  );

  static const privacyPolicy = LegalDocumentScreen(
    title: 'Politique de confidentialité',
    paragraphs: [
      'Gestion Locative collecte les données nécessaires au fonctionnement du '
          'service : identité, coordonnées, informations sur les biens, baux, '
          'paiements et échanges entre propriétaires et locataires.',
      'Ces données sont utilisées exclusivement pour permettre la gestion '
          'locative (création de baux, suivi des paiements, notifications, '
          'messagerie) et ne sont jamais vendues à des tiers.',
      'Les documents générés (contrats, quittances) et les photos de profil '
          'ou de biens sont stockés de manière sécurisée et accessibles '
          'uniquement aux utilisateurs concernés par le bail correspondant.',
      'Vous pouvez à tout moment demander la modification ou la suppression '
          'de vos données personnelles en contactant le support.',
      'Ce document est fourni à titre provisoire dans le cadre du projet '
          'académique et sera complété avant toute mise en production.',
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: paragraphs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (context, index) => Text(
            paragraphs[index],
            style: const TextStyle(height: 1.5, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}
