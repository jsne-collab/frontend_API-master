import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../auth/domain/auth_provider.dart';
import '../../../auth/domain/user_model.dart';
import '../../domain/maintenance_model.dart';
import '../../domain/maintenance_provider.dart';
import '../../../../core/network/error_message.dart';

enum _StatusFilter { all, newRequest, inProgress, resolved }

extension on _StatusFilter {
  String get label => switch (this) {
    _StatusFilter.all => 'Toutes',
    _StatusFilter.newRequest => 'Nouvelles',
    _StatusFilter.inProgress => 'En cours',
    _StatusFilter.resolved => 'Résolues',
  };

  bool matches(MaintenanceStatus status) => switch (this) {
    _StatusFilter.all => true,
    _StatusFilter.newRequest => status == MaintenanceStatus.newRequest,
    _StatusFilter.inProgress => status == MaintenanceStatus.inProgress,
    _StatusFilter.resolved => status == MaintenanceStatus.resolved,
  };
}

class MaintenanceListScreen extends ConsumerStatefulWidget {
  const MaintenanceListScreen({super.key});

  @override
  ConsumerState<MaintenanceListScreen> createState() =>
      _MaintenanceListScreenState();
}

class _MaintenanceListScreenState extends ConsumerState<MaintenanceListScreen> {
  _StatusFilter _filter = _StatusFilter.all;

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(myMaintenanceRequestsProvider);
    final isOwner =
        ref.watch(authControllerProvider).user?.role == UserRole.owner;

    return AppScaffold(
      currentRoute: '/maintenance',
      appBar: AppBar(title: const Text('Maintenance')),
      floatingActionButton: !isOwner
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/maintenance/create'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Signaler'),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: _StatusFilterChips(
                selected: _filter,
                onChanged: (filter) => setState(() => _filter = filter),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    ref.read(myMaintenanceRequestsProvider.notifier).refresh(),
                child: requestsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            friendlyErrorMessage(error),
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ),
                      ),
                    ],
                  ),
                  data: (requests) {
                    final filtered = requests
                        .where((r) => _filter.matches(r.status))
                        .toList();

                    if (filtered.isEmpty) {
                      return ListView(children: const [_EmptyState()]);
                    }

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: filtered
                          .map(
                            (request) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _MaintenanceCard(
                                request: request,
                                isOwner: isOwner,
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusFilterChips extends StatelessWidget {
  const _StatusFilterChips({required this.selected, required this.onChanged});

  final _StatusFilter selected;
  final ValueChanged<_StatusFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _StatusFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _StatusFilter.values[index];
          final isSelected = filter == selected;

          return ChoiceChip(
            label: Text(filter.label),
            selected: isSelected,
            onSelected: (_) => onChanged(filter),
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.surface,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            side: BorderSide(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.textSecondary.withValues(alpha: 0.3),
            ),
          );
        },
      ),
    );
  }
}

class _MaintenanceCard extends StatelessWidget {
  const _MaintenanceCard({required this.request, required this.isOwner});

  final MaintenanceRequestModel request;
  final bool isOwner;

  StatusTone _statusTone(MaintenanceStatus status) => switch (status) {
    MaintenanceStatus.newRequest => StatusTone.warning,
    MaintenanceStatus.inProgress => StatusTone.neutral,
    MaintenanceStatus.resolved => StatusTone.success,
    MaintenanceStatus.rejected => StatusTone.error,
  };

  Color _priorityColor(MaintenancePriority priority) => switch (priority) {
    MaintenancePriority.low => AppColors.textSecondary,
    MaintenancePriority.medium => AppColors.warning,
    MaintenancePriority.high => AppColors.error,
    MaintenancePriority.urgent => AppColors.error,
  };

  bool get _isUrgent =>
      request.priority == MaintenancePriority.high ||
      request.priority == MaintenancePriority.urgent;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final priorityColor = _priorityColor(request.priority);

    return AppCard(
      onTap: () => context.push('/maintenance/${request.id}'),
      accentColor: _isUrgent ? AppColors.error : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              StatusBadge(
                label: request.status.label,
                tone: _statusTone(request.status),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            request.property.title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          if (isOwner)
            Text(
              'Locataire : ${request.tenant.name}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.flag_outlined, size: 14, color: priorityColor),
              const SizedBox(width: 4),
              Text(
                request.priority.label,
                style: TextStyle(
                  color: priorityColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                dateFormat.format(request.createdAt),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.build_outlined,
              size: 56,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 16),
            Text(
              "Aucune demande de maintenance pour l'instant.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
