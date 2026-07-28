enum NotificationType {
  paymentValidated,
  paymentReminder,
  newMessage,
  maintenanceRequestCreated,
  maintenanceComment,
  other;

  static NotificationType fromString(String value) {
    return switch (value) {
      'payment_validated' => NotificationType.paymentValidated,
      'payment_reminder' => NotificationType.paymentReminder,
      'new_message' => NotificationType.newMessage,
      'maintenance_request_created' => NotificationType.maintenanceRequestCreated,
      'maintenance_comment' => NotificationType.maintenanceComment,
      _ => NotificationType.other,
    };
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as int,
      type: NotificationType.fromString(json['type'] as String),
      title: json['title'] as String,
      message: json['message'] as String,
      isRead: json['is_read'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final int id;
  final NotificationType type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
}
