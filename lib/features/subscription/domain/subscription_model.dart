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

enum SubscriptionPlan {
  monthly,
  yearly;

  String get apiValue => switch (this) {
    SubscriptionPlan.monthly => 'monthly',
    SubscriptionPlan.yearly => 'yearly',
  };
}

class SubscriptionPlanOption {
  const SubscriptionPlanOption({required this.label, required this.amount});

  factory SubscriptionPlanOption.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanOption(
      label: json['label'] as String,
      amount: (json['amount'] as num).toDouble(),
    );
  }

  final String label;
  final double amount;
}

class SubscriptionInfo {
  const SubscriptionInfo({
    required this.status,
    required this.plans,
    this.nextDueDate,
  });

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) {
    final plans = json['plans'] as Map<String, dynamic>;

    return SubscriptionInfo(
      status: SubscriptionStatus.fromString(json['status'] as String),
      plans: plans.map(
        (key, value) => MapEntry(
          key,
          SubscriptionPlanOption.fromJson(value as Map<String, dynamic>),
        ),
      ),
      nextDueDate: json['next_due_date'] != null
          ? DateTime.tryParse(json['next_due_date'] as String)
          : null,
    );
  }

  final SubscriptionStatus status;
  // Clés : 'monthly' / 'yearly' — voir SubscriptionPlan.apiValue.
  final Map<String, SubscriptionPlanOption> plans;
  final DateTime? nextDueDate;
}
