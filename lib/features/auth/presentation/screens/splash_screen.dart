import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/auth_provider.dart';

/// Écran de démarrage : restaure la session (token stocké) avant de
/// laisser le router go_router rediriger vers /login ou /{role}/home.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authControllerProvider.notifier).bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryLight],
          ),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(isCompact ? 32 : 64),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Marque seule (transparente) — la version avec badge/texte
                // "Logo_Complet" est prévue pour un fond clair, pas pour ce
                // dégradé navy (voir docs branding).
                Image.asset(
                  'assets/branding/Logo_Marque_Seule_Android_Foreground.png',
                  width: 96,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Gestion Locative',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 32),
                const CircularProgressIndicator(color: AppColors.accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
