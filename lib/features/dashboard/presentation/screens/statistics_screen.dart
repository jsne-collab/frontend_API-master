import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/dashboard_model.dart';
import '../../domain/dashboard_provider.dart';
import '../widgets/revenue_chart.dart';
import '../../../../core/network/error_message.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final revenueAsync = ref.watch(revenueChartProvider);
    final occupancyAsync = ref.watch(occupancyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistiques')),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Revenus (6 derniers mois)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  revenueAsync.when(
                    loading: () => const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, _) => Text(
                      friendlyErrorMessage(error),
                      style: const TextStyle(color: AppColors.error),
                    ),
                    data: (points) => points.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              'Aucune donnée de revenus pour le moment.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          )
                        : RevenueChart(points: points),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            occupancyAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  friendlyErrorMessage(error),
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
              data: (occupancy) => _OccupancySection(occupancy: occupancy),
            ),
          ],
        ),
      ),
    );
  }
}

class _OccupancySection extends StatelessWidget {
  const _OccupancySection({required this.occupancy});

  final Occupancy occupancy;

  StatusTone _tone(String status) => switch (status) {
    'rented' => StatusTone.success,
    'maintenance' => StatusTone.warning,
    _ => StatusTone.neutral,
  };

  String _label(String status) => switch (status) {
    'rented' => 'Loué',
    'maintenance' => 'En maintenance',
    _ => 'Disponible',
  };

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Taux d'occupation",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: occupancy.overallRate / 100,
                      strokeWidth: 6,
                      backgroundColor: AppColors.background,
                      color: AppColors.accent,
                    ),
                    Text(
                      '${occupancy.overallRate.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  '${occupancy.properties.where((p) => p.status == 'rented').length} bien(s) loué(s) sur ${occupancy.properties.length}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          if (occupancy.properties.isNotEmpty) ...[
            const Divider(height: 32),
            ...occupancy.properties.map(
              (property) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        property.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(
                      label: _label(property.status),
                      tone: _tone(property.status),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
