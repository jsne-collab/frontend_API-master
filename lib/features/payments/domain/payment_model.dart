enum PaymentStatus {
  pending,
  validated,
  late,
  partial;

  static PaymentStatus fromString(String value) {
    return PaymentStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => PaymentStatus.pending,
    );
  }

  String get label => switch (this) {
    PaymentStatus.pending => 'En attente',
    PaymentStatus.validated => 'Validé',
    PaymentStatus.late => 'En retard',
    PaymentStatus.partial => 'Partiel',
  };
}

enum PaymentMethodType {
  mobileMoney,
  bankTransfer,
  cash;

  static PaymentMethodType fromString(String value) {
    return switch (value) {
      'mobile_money' => PaymentMethodType.mobileMoney,
      'bank_transfer' => PaymentMethodType.bankTransfer,
      _ => PaymentMethodType.cash,
    };
  }

  String get apiValue => switch (this) {
    PaymentMethodType.mobileMoney => 'mobile_money',
    PaymentMethodType.bankTransfer => 'bank_transfer',
    PaymentMethodType.cash => 'cash',
  };

  String get label => switch (this) {
    PaymentMethodType.mobileMoney => 'Mobile Money',
    PaymentMethodType.bankTransfer => 'Virement bancaire',
    PaymentMethodType.cash => 'Espèces',
  };
}

class PaymentMethodInfo {
  const PaymentMethodInfo({
    required this.id,
    required this.type,
    this.provider,
  });

  factory PaymentMethodInfo.fromJson(Map<String, dynamic> json) {
    return PaymentMethodInfo(
      id: json['id'] as int,
      type: PaymentMethodType.fromString(json['type'] as String),
      provider: json['provider'] as String?,
    );
  }

  final int id;
  final PaymentMethodType type;
  final String? provider;
}

class Payment {
  const Payment({
    required this.id,
    required this.leaseId,
    required this.propertyTitle,
    required this.tenantId,
    required this.tenantName,
    required this.amount,
    this.paymentMethod,
    required this.paymentDate,
    required this.periodCovered,
    required this.status,
    this.reference,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    final lease = json['lease'] as Map<String, dynamic>;
    final tenant = json['tenant'] as Map<String, dynamic>;

    return Payment(
      id: json['id'] as int,
      leaseId: lease['id'] as int,
      propertyTitle: lease['property_title'] as String,
      tenantId: tenant['id'] as int,
      tenantName: tenant['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      paymentMethod: json['payment_method'] != null
          ? PaymentMethodInfo.fromJson(
              json['payment_method'] as Map<String, dynamic>,
            )
          : null,
      paymentDate: DateTime.parse(json['payment_date'] as String),
      periodCovered: json['period_covered'] as String,
      status: PaymentStatus.fromString(json['status'] as String),
      reference: json['reference'] as String?,
    );
  }

  final int id;
  final int leaseId;
  final String propertyTitle;
  final int tenantId;
  final String tenantName;
  final double amount;
  final PaymentMethodInfo? paymentMethod;
  final DateTime paymentDate;
  final String periodCovered;
  final PaymentStatus status;
  final String? reference;
}

class PaymentStats {
  const PaymentStats({
    required this.totalValidated,
    required this.totalPending,
    required this.totalLate,
    required this.totalPartial,
    required this.countByStatus,
  });

  factory PaymentStats.fromJson(Map<String, dynamic> json) {
    final counts = json['count_by_status'] as Map<String, dynamic>;

    return PaymentStats(
      totalValidated: (json['total_validated'] as num).toDouble(),
      totalPending: (json['total_pending'] as num).toDouble(),
      totalLate: (json['total_late'] as num).toDouble(),
      totalPartial: (json['total_partial'] as num).toDouble(),
      countByStatus: counts.map((key, value) => MapEntry(key, value as int)),
    );
  }

  final double totalValidated;
  final double totalPending;
  final double totalLate;
  final double totalPartial;
  final Map<String, int> countByStatus;
}
