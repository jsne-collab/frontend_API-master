import '../../leases/domain/lease_model.dart';
import '../../maintenance/domain/maintenance_model.dart';
import '../../payments/domain/payment_model.dart';

class OwnerDashboard {
  const OwnerDashboard({
    required this.monthlyRevenue,
    required this.previousMonthRevenue,
    required this.revenueVariationPercent,
    required this.occupancyRate,
    required this.pendingPaymentsCount,
    required this.availablePropertiesCount,
    required this.totalPropertiesCount,
    required this.recentPayments,
    required this.openMaintenanceRequests,
  });

  factory OwnerDashboard.fromJson(Map<String, dynamic> json) {
    return OwnerDashboard(
      monthlyRevenue: (json['monthly_revenue'] as num).toDouble(),
      previousMonthRevenue: (json['previous_month_revenue'] as num).toDouble(),
      revenueVariationPercent: (json['revenue_variation_percent'] as num)
          .toDouble(),
      occupancyRate: (json['occupancy_rate'] as num).toDouble(),
      pendingPaymentsCount: json['pending_payments_count'] as int,
      availablePropertiesCount: json['available_properties_count'] as int,
      totalPropertiesCount: json['total_properties_count'] as int,
      recentPayments: (json['recent_payments'] as List)
          .map((e) => Payment.fromJson(e as Map<String, dynamic>))
          .toList(),
      openMaintenanceRequests: (json['open_maintenance_requests'] as List)
          .map(
            (e) => MaintenanceRequestModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  final double monthlyRevenue;
  final double previousMonthRevenue;
  final double revenueVariationPercent;
  final double occupancyRate;
  final int pendingPaymentsCount;
  final int availablePropertiesCount;
  final int totalPropertiesCount;
  final List<Payment> recentPayments;
  final List<MaintenanceRequestModel> openMaintenanceRequests;
}

class TenantDashboard {
  const TenantDashboard({
    this.currentLease,
    this.nextDueDate,
    required this.recentPayments,
    required this.openMaintenanceRequests,
  });

  factory TenantDashboard.fromJson(Map<String, dynamic> json) {
    return TenantDashboard(
      currentLease: json['current_lease'] != null
          ? Lease.fromJson(json['current_lease'] as Map<String, dynamic>)
          : null,
      nextDueDate: json['next_due_date'] != null
          ? DateTime.parse(json['next_due_date'] as String)
          : null,
      recentPayments: (json['recent_payments'] as List)
          .map((e) => Payment.fromJson(e as Map<String, dynamic>))
          .toList(),
      openMaintenanceRequests: (json['open_maintenance_requests'] as List)
          .map(
            (e) => MaintenanceRequestModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  final Lease? currentLease;
  final DateTime? nextDueDate;
  final List<Payment> recentPayments;
  final List<MaintenanceRequestModel> openMaintenanceRequests;
}

class RevenuePoint {
  const RevenuePoint({required this.month, required this.total});

  factory RevenuePoint.fromJson(Map<String, dynamic> json) {
    return RevenuePoint(
      month: json['month'] as String,
      total: (json['total'] as num).toDouble(),
    );
  }

  final String month;
  final double total;
}

class OccupancyProperty {
  const OccupancyProperty({
    required this.id,
    required this.title,
    required this.status,
  });

  factory OccupancyProperty.fromJson(Map<String, dynamic> json) {
    return OccupancyProperty(
      id: json['id'] as int,
      title: json['title'] as String,
      status: json['status'] as String,
    );
  }

  final int id;
  final String title;
  final String status;
}

class Occupancy {
  const Occupancy({required this.overallRate, required this.properties});

  factory Occupancy.fromJson(Map<String, dynamic> json) {
    return Occupancy(
      overallRate: (json['overall_rate'] as num).toDouble(),
      properties: (json['properties'] as List)
          .map((e) => OccupancyProperty.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final double overallRate;
  final List<OccupancyProperty> properties;
}
