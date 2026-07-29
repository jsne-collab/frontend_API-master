import '../../subscription/domain/subscription_model.dart';

class OwnerLeaseInfo {
  const OwnerLeaseInfo({
    required this.propertyTitle,
    required this.tenantName,
    required this.monthlyRent,
  });

  factory OwnerLeaseInfo.fromJson(Map<String, dynamic> json) {
    final property = json['property'] as Map<String, dynamic>;
    final tenant = json['tenant'] as Map<String, dynamic>;

    return OwnerLeaseInfo(
      propertyTitle: property['title'] as String,
      tenantName: tenant['name'] as String,
      monthlyRent: (json['monthly_rent'] as num).toDouble(),
    );
  }

  final String propertyTitle;
  final String tenantName;
  final double monthlyRent;
}

class SubscriptionHistoryEntry {
  const SubscriptionHistoryEntry({
    required this.id,
    required this.amount,
    required this.periodStart,
    required this.periodEnd,
    required this.status,
  });

  factory SubscriptionHistoryEntry.fromJson(Map<String, dynamic> json) {
    return SubscriptionHistoryEntry(
      id: json['id'] as int,
      amount: (json['amount'] as num).toDouble(),
      periodStart: DateTime.parse(json['period_start'] as String),
      periodEnd: DateTime.parse(json['period_end'] as String),
      status: json['status'] as String,
    );
  }

  final int id;
  final double amount;
  final DateTime periodStart;
  final DateTime periodEnd;
  final String status;
}

class OwnerDetail {
  const OwnerDetail({
    required this.name,
    required this.email,
    required this.phone,
    required this.leases,
    required this.subscriptions,
    required this.subscriptionStatus,
    this.nextDueDate,
  });

  factory OwnerDetail.fromJson(Map<String, dynamic> json) {
    final owner = json['owner'] as Map<String, dynamic>;
    final leases = json['leases'] as List;
    final subscriptions = json['subscriptions'] as List;

    return OwnerDetail(
      name: owner['name'] as String,
      email: owner['email'] as String,
      phone: owner['phone'] as String? ?? '',
      leases: leases
          .map((e) => OwnerLeaseInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      subscriptions: subscriptions
          .map(
            (e) => SubscriptionHistoryEntry.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      subscriptionStatus: SubscriptionStatus.fromString(
        json['subscription_status'] as String,
      ),
      nextDueDate: json['next_due_date'] != null
          ? DateTime.tryParse(json['next_due_date'] as String)
          : null,
    );
  }

  final String name;
  final String email;
  final String phone;
  final List<OwnerLeaseInfo> leases;
  final List<SubscriptionHistoryEntry> subscriptions;
  final SubscriptionStatus subscriptionStatus;
  final DateTime? nextDueDate;
}
