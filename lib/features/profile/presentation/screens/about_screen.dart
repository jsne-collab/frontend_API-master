import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/theme/app_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('À propos')),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/branding/Logo_Complet_2400.png',
                  width: 240,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 24),
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    final version = snapshot.data;
                    final label = version != null
                        ? 'Version ${version.version} (${version.buildNumber})'
                        : 'Version —';

                    return Text(
                      label,
                      style: const TextStyle(color: AppColors.textSecondary),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
