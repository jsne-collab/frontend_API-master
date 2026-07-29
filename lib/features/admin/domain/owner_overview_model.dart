import '../../subscription/domain/subscription_model.dart';

class OwnerOverview {
  const OwnerOverview({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.propertiesCount,
    required this.tenantCount,
    required this.subscriptionStatus,
    this.nextDueDate,
  });

  factory OwnerOverview.fromJson(Map<String, dynamic> json) {
    final owner = json['owner'] as Map<String, dynamic>;

    return OwnerOverview(
      id: owner['id'] as int,
      name: owner['name'] as String,
      email: owner['email'] as String,
      phone: owner['phone'] as String? ?? '',
      propertiesCount: json['properties_count'] as int,
      tenantCount: json['tenant_count'] as int,
      subscriptionStatus: SubscriptionStatus.fromString(
        json['subscription_status'] as String,
      ),
      nextDueDate: json['next_due_date'] != null
          ? DateTime.tryParse(json['next_due_date'] as String)
          : null,
    );
  }

  final int id;
  final String name;
  final String email;
  final String phone;
  final int propertiesCount;
  final int tenantCount;
  final SubscriptionStatus subscriptionStatus;
  final DateTime? nextDueDate;
}
