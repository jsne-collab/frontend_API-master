import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/domain/auth_provider.dart';
import '../../domain/lease_model.dart';
import '../../domain/lease_provider.dart';
import '../../../../core/network/error_message.dart';

class LeaseDetailScreen extends ConsumerStatefulWidget {
  const LeaseDetailScreen({super.key, required this.leaseId});

  final int leaseId;

  @override
  ConsumerState<LeaseDetailScreen> createState() => _LeaseDetailScreenState();
}

class _LeaseDetailScreenState extends ConsumerState<LeaseDetailScreen> {
  bool _isActing = false;

  Future<void> _terminate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Résilier ce bail ?'),
        content: const Text('Le bien redeviendra disponible immédiatement.'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            child: const Text('Résilier'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await _run(
      () => ref.read(leaseRepositoryProvider).terminate(widget.leaseId),
    );
  }

  Future<void> _renew() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      helpText: 'Nouvelle date de fin',
    );
    if (picked == null || !mounted) return;

    await _run(
      () => ref
          .read(leaseRepositoryProvider)
          .renew(widget.leaseId, DateFormat('yyyy-MM-dd').format(picked)),
    );
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce bail ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isActing = true);
    try {
      await ref.read(leaseRepositoryProvider).delete(widget.leaseId);
      await ref.read(myLeasesProvider.notifier).refresh();
      if (mounted) context.pop();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _isActing = true);
    try {
      await action();
      ref.invalidate(leaseDetailProvider(widget.leaseId));
      await ref.read(myLeasesProvider.notifier).refresh();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final leaseAsync = ref.watch(leaseDetailProvider(widget.leaseId));
    final currentUserId = ref.watch(authControllerProvider).user?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Détail du bail')),
      body: leaseAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(friendlyErrorMessage(error))),
        data: (lease) {
          final isOwner = lease.owner.id == currentUserId;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lease.property.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      StatusBadge(
                        label: lease.status.label,
                        tone: _toneFor(lease.status),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${lease.property.address}, ${lease.property.city}'
                    '${lease.unit != null ? ' — ${lease.unit!.unitName}' : ''}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  _Section(title: 'Locataire', person: lease.tenant),
                  const SizedBox(height: 16),
                  _Section(title: 'Propriétaire', person: lease.owner),
                  const SizedBox(height: 24),
                  _DatesAndAmounts(lease: lease),
                  if (lease.contractPdfUrl != null) ...[
                    const SizedBox(height: 24),
                    AppButton(
                      label: 'Voir le contrat (PDF)',
                      variant: AppButtonVariant.outline,
                      onPressed: () => context.push(
                        '/leases/${lease.id}/contract',
                        extra: lease.contractPdfUrl,
                      ),
                    ),
                  ],
                  if (isOwner) ...[
                    const SizedBox(height: 24),
                    if (lease.status == LeaseStatus.active ||
                        lease.status == LeaseStatus.pending) ...[
                      AppButton(
                        label: 'Modifier',
                        variant: AppButtonVariant.outline,
                        onPressed: () =>
                            context.push('/leases/${lease.id}/edit'),
                      ),
                      const SizedBox(height: 12),
                      AppButton(
                        label: 'Résilier',
                        variant: AppButtonVariant.outline,
                        isLoading: _isActing,
                        onPressed: _terminate,
                      ),
                    ],
                    if (lease.status == LeaseStatus.active ||
                        lease.status == LeaseStatus.expired) ...[
                      const SizedBox(height: 12),
                      AppButton(
                        label: 'Renouveler',
                        isLoading: _isActing,
                        onPressed: _renew,
                      ),
                    ],
                    if (lease.status == LeaseStatus.pending) ...[
                      const SizedBox(height: 12),
                      AppButton(
                        label: 'Supprimer',
                        variant: AppButtonVariant.outline,
                        isLoading: _isActing,
                        onPressed: _delete,
                      ),
                    ],
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  StatusTone _toneFor(LeaseStatus status) => switch (status) {
    LeaseStatus.active => StatusTone.success,
    LeaseStatus.pending => StatusTone.warning,
    LeaseStatus.terminated => StatusTone.error,
    LeaseStatus.expired => StatusTone.neutral,
  };
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.person});

  final String title;
  final LeasePerson person;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(person.name, style: const TextStyle(fontWeight: FontWeight.w500)),
        if (person.phone != null)
          Text(
            person.phone!,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
      ],
    );
  }
}

class _DatesAndAmounts extends StatelessWidget {
  const _DatesAndAmounts({required this.lease});

  final Lease lease;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _InfoBlock(
                label: 'Début',
                value: dateFormat.format(lease.startDate),
              ),
            ),
            Expanded(
              child: _InfoBlock(
                label: 'Fin',
                value: dateFormat.format(lease.endDate),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _InfoBlock(
                label: 'Loyer mensuel',
                value: currency.format(lease.monthlyRent),
              ),
            ),
            Expanded(
              child: _InfoBlock(
                label: 'Caution',
                value: currency.format(lease.depositAmount),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
