import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/domain/auth_provider.dart';
import '../../../auth/domain/user_model.dart';
import '../../domain/maintenance_model.dart';
import '../../domain/maintenance_provider.dart';

class MaintenanceDetailScreen extends ConsumerStatefulWidget {
  const MaintenanceDetailScreen({super.key, required this.requestId});

  final int requestId;

  @override
  ConsumerState<MaintenanceDetailScreen> createState() =>
      _MaintenanceDetailScreenState();
}

class _MaintenanceDetailScreenState
    extends ConsumerState<MaintenanceDetailScreen> {
  final _commentController = TextEditingController();
  bool _isSendingComment = false;
  bool _isUpdatingStatus = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSendingComment = true);
    try {
      await ref
          .read(maintenanceRepositoryProvider)
          .addComment(widget.requestId, text);
      _commentController.clear();
      ref.invalidate(maintenanceRequestDetailProvider(widget.requestId));
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _isSendingComment = false);
    }
  }

  Future<void> _updateStatus(MaintenanceStatus status) async {
    setState(() => _isUpdatingStatus = true);
    try {
      await ref
          .read(maintenanceRepositoryProvider)
          .updateStatus(widget.requestId, status.apiValue);
      ref.invalidate(maintenanceRequestDetailProvider(widget.requestId));
      await ref.read(myMaintenanceRequestsProvider.notifier).refresh();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  StatusTone _statusTone(MaintenanceStatus status) => switch (status) {
    MaintenanceStatus.newRequest => StatusTone.warning,
    MaintenanceStatus.inProgress => StatusTone.neutral,
    MaintenanceStatus.resolved => StatusTone.success,
    MaintenanceStatus.rejected => StatusTone.error,
  };

  @override
  Widget build(BuildContext context) {
    final requestAsync = ref.watch(
      maintenanceRequestDetailProvider(widget.requestId),
    );
    final isOwner =
        ref.watch(authControllerProvider).user?.role == UserRole.owner;

    return Scaffold(
      appBar: AppBar(title: const Text('Demande de maintenance')),
      body: SafeArea(
        child: requestAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text(
              error.toString(),
              style: const TextStyle(color: AppColors.error),
            ),
          ),
          data: (request) => Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  request.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              StatusBadge(
                                label: request.status.label,
                                tone: _statusTone(request.status),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            request.property.title,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (isOwner)
                            Text(
                              'Locataire : ${request.tenant.name}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          const SizedBox(height: 12),
                          Text(request.description),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              StatusBadge(
                                label: request.priority.label,
                                tone: StatusTone.warning,
                              ),
                              const Spacer(),
                              Text(
                                DateFormat(
                                  'dd/MM/yyyy',
                                ).format(request.createdAt),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          if (request.photoUrl != null) ...[
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                request.photoUrl!,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ],
                          if (isOwner) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Statut',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<MaintenanceStatus>(
                              initialValue: request.status,
                              items: MaintenanceStatus.values
                                  .map(
                                    (status) => DropdownMenuItem(
                                      value: status,
                                      child: Text(status.label),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _isUpdatingStatus
                                  ? null
                                  : (value) {
                                      if (value != null) {
                                        _updateStatus(value);
                                      }
                                    },
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Discussion',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    if (request.comments.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'Aucun message pour le moment.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    else
                      ...request.comments.map(
                        (comment) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      comment.author.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat(
                                        'dd/MM HH:mm',
                                      ).format(comment.createdAt),
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(comment.comment),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                            hintText: 'Écrire un message...',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _isSendingComment ? null : _sendComment,
                        icon: _isSendingComment
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
