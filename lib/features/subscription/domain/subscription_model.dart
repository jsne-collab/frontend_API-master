enum SubscriptionStatus {
  never,
  pending,
  paid,
  overdue;

  static SubscriptionStatus fromString(String value) {
    return SubscriptionStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => SubscriptionStatus.never,
    );
  }

  String get label => switch (this) {
    SubscriptionStatus.never => 'Jamais payé',
    SubscriptionStatus.pending => 'En attente de validation',
    SubscriptionStatus.paid => 'À jour',
    SubscriptionStatus.overdue => 'En retard',
  };
}

class SubscriptionInfo {
  const SubscriptionInfo({
    required this.status,
    required this.amount,
    this.nextDueDate,
  });

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) {
    return SubscriptionInfo(
      status: SubscriptionStatus.fromString(json['status'] as String),
      amount: (json['amount'] as num).toDouble(),
      nextDueDate: json['next_due_date'] != null
          ? DateTime.tryParse(json['next_due_date'] as String)
          : null,
    );
  }

  final SubscriptionStatus status;
  final double amount;
  final DateTime? nextDueDate;
}
