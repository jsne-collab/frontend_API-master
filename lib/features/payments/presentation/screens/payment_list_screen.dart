import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/domain/auth_provider.dart';
import '../../../auth/domain/user_model.dart';
import '../../domain/payment_model.dart';
import '../../domain/payment_provider.dart';

final _currency = NumberFormat.currency(
  locale: 'fr_FR',
  symbol: 'FCFA',
  decimalDigits: 0,
);
final _monthFormat = DateFormat('MMMM yyyy', 'fr_FR');
final _dateFormat = DateFormat('dd/MM/yyyy');

class PaymentListScreen extends ConsumerWidget {
  const PaymentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(myPaymentsProvider);
    final statsAsync = ref.watch(paymentStatsProvider);
    final isOwner =
        ref.watch(authControllerProvider).user?.role == UserRole.owner;

    return AppScaffold(
      currentRoute: '/payments',
      appBar: AppBar(title: const Text('Mes paiements')),
      floatingActionButton: !isOwner
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/payments/initiate'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Payer'),
            )
          : null,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(myPaymentsProvider.notifier).refresh();
            ref.invalidate(paymentStatsProvider);
          },
          child: paymentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      error.toString(),
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ),
              ],
            ),
            data: (payments) {
              if (payments.isEmpty) {
                return ListView(
                  children: const [_EmptyState()],
                );
              }

              final groups = _groupByMonth(payments);

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: _HeroPaymentsCard(statsAsync: statsAsync),
                    ),
                  ),
                  for (final group in groups) ...[
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _MonthHeaderDelegate(label: group.label),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      sliver: SliverList.separated(
                        itemCount: group.payments.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => _PaymentCard(
                          payment: group.payments[index],
                          isOwner: isOwner,
                        ),
                      ),
                    ),
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<_MonthGroup> _groupByMonth(List<Payment> payments) {
    final sorted = [...payments]
      ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));

    final groups = <String, List<Payment>>{};
    for (final payment in sorted) {
      final key = '${payment.paymentDate.year}-${payment.paymentDate.month}';
      groups.putIfAbsent(key, () => []).add(payment);
    }

    return groups.entries
        .map(
          (entry) => _MonthGroup(
            label: _capitalize(_monthFormat.format(entry.value.first.paymentDate)),
            payments: entry.value,
          ),
        )
        .toList();
  }

  String _capitalize(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
}

class _MonthGroup {
  const _MonthGroup({required this.label, required this.payments});

  final String label;
  final List<Payment> payments;
}

class _MonthHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _MonthHeaderDelegate({required this.label});

  final String label;

  @override
  double get minExtent => 36;

  @override
  double get maxExtent => 36;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _MonthHeaderDelegate oldDelegate) =>
      oldDelegate.label != label;
}

class _HeroPaymentsCard extends StatelessWidget {
  const _HeroPaymentsCard({required this.statsAsync});

  final AsyncValue<PaymentStats> statsAsync;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: statsAsync.when(
        loading: () => const SizedBox(
          height: 72,
          child: Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
        error: (error, _) => Text(
          error.toString(),
          style: const TextStyle(color: Colors.white),
        ),
        data: (stats) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Total validé',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              _currency.format(stats.totalValidated),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (stats.totalPending > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${_currency.format(stats.totalPending)} en attente',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PaymentCard extends ConsumerStatefulWidget {
  const _PaymentCard({required this.payment, required this.isOwner});

  final Payment payment;
  final bool isOwner;

  @override
  ConsumerState<_PaymentCard> createState() => _PaymentCardState();
}

class _PaymentCardState extends ConsumerState<_PaymentCard> {
  bool _isValidating = false;

  Future<void> _validate() async {
    setState(() => _isValidating = true);
    try {
      await ref.read(paymentRepositoryProvider).update(widget.payment.id, {
        'status': 'validated',
      });
      await ref.read(myPaymentsProvider.notifier).refresh();
      ref.invalidate(paymentStatsProvider);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _isValidating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final payment = widget.payment;

    return AppCard(
      onTap: () => context.push('/payments/${payment.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  payment.periodCovered,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              StatusBadge(
                label: payment.status.label,
                tone: _toneFor(payment.status),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            payment.propertyTitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (widget.isOwner)
            Text(
              'Locataire : ${payment.tenantName}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Enregistré le ${_dateFormat.format(payment.paymentDate)}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Text(
                _currency.format(payment.amount),
                style: TextStyle(
                  color: payment.status == PaymentStatus.validated
                      ? AppColors.accent
                      : AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (widget.isOwner && payment.status == PaymentStatus.pending) ...[
            const SizedBox(height: 12),
            AppButton(
              label: 'Valider',
              isLoading: _isValidating,
              onPressed: _validate,
            ),
          ],
        ],
      ),
    );
  }

  StatusTone _toneFor(PaymentStatus status) => switch (status) {
    PaymentStatus.validated => StatusTone.success,
    PaymentStatus.pending => StatusTone.warning,
    PaymentStatus.late => StatusTone.error,
    PaymentStatus.partial => StatusTone.warning,
  };
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
              Icons.receipt_long_outlined,
              size: 56,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 16),
            Text(
              "Aucun paiement pour l'instant.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
