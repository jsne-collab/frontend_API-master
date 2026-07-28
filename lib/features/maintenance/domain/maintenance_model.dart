enum MaintenancePriority {
  low,
  medium,
  high,
  urgent;

  static MaintenancePriority fromString(String value) {
    return MaintenancePriority.values.firstWhere(
      (priority) => priority.name == value,
      orElse: () => MaintenancePriority.medium,
    );
  }

  String get label => switch (this) {
    MaintenancePriority.low => 'Faible',
    MaintenancePriority.medium => 'Moyenne',
    MaintenancePriority.high => 'Élevée',
    MaintenancePriority.urgent => 'Urgente',
  };
}

enum MaintenanceStatus {
  newRequest,
  inProgress,
  resolved,
  rejected;

  static MaintenanceStatus fromString(String value) {
    return switch (value) {
      'new' => MaintenanceStatus.newRequest,
      'in_progress' => MaintenanceStatus.inProgress,
      'resolved' => MaintenanceStatus.resolved,
      'rejected' => MaintenanceStatus.rejected,
      _ => MaintenanceStatus.newRequest,
    };
  }

  String get apiValue => switch (this) {
    MaintenanceStatus.newRequest => 'new',
    MaintenanceStatus.inProgress => 'in_progress',
    MaintenanceStatus.resolved => 'resolved',
    MaintenanceStatus.rejected => 'rejected',
  };

  String get label => switch (this) {
    MaintenanceStatus.newRequest => 'Nouvelle',
    MaintenanceStatus.inProgress => 'En cours',
    MaintenanceStatus.resolved => 'Résolue',
    MaintenanceStatus.rejected => 'Rejetée',
  };
}

class MaintenanceProperty {
  const MaintenanceProperty({required this.id, required this.title});

  factory MaintenanceProperty.fromJson(Map<String, dynamic> json) {
    return MaintenanceProperty(
      id: json['id'] as int,
      title: json['title'] as String,
    );
  }

  final int id;
  final String title;
}

class MaintenancePerson {
  const MaintenancePerson({
    required this.id,
    required this.name,
    this.role,
  });

  factory MaintenancePerson.fromJson(Map<String, dynamic> json) {
    return MaintenancePerson(
      id: json['id'] as int,
      name: json['name'] as String,
      role: json['role'] as String?,
    );
  }

  final int id;
  final String name;
  final String? role;
}

class MaintenanceComment {
  const MaintenanceComment({
    required this.id,
    required this.author,
    required this.comment,
    required this.createdAt,
  });

  factory MaintenanceComment.fromJson(Map<String, dynamic> json) {
    return MaintenanceComment(
      id: json['id'] as int,
      author: MaintenancePerson.fromJson(
        json['author'] as Map<String, dynamic>,
      ),
      comment: json['comment'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final int id;
  final MaintenancePerson author;
  final String comment;
  final DateTime createdAt;
}

class MaintenanceRequestModel {
  const MaintenanceRequestModel({
    required this.id,
    required this.property,
    required this.leaseId,
    required this.tenant,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    this.photoUrl,
    this.comments = const [],
    required this.createdAt,
  });

  factory MaintenanceRequestModel.fromJson(Map<String, dynamic> json) {
    return MaintenanceRequestModel(
      id: json['id'] as int,
      property: MaintenanceProperty.fromJson(
        json['property'] as Map<String, dynamic>,
      ),
      leaseId: json['lease_id'] as int,
      tenant: MaintenancePerson.fromJson(
        json['tenant'] as Map<String, dynamic>,
      ),
      title: json['title'] as String,
      description: json['description'] as String,
      priority: MaintenancePriority.fromString(json['priority'] as String),
      status: MaintenanceStatus.fromString(json['status'] as String),
      photoUrl: json['photo_url'] as String?,
      comments: json['comments'] != null
          ? (json['comments'] as List)
                .map((e) => MaintenanceComment.fromJson(e as Map<String, dynamic>))
                .toList()
          : const [],
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final int id;
  final MaintenanceProperty property;
  final int leaseId;
  final MaintenancePerson tenant;
  final String title;
  final String description;
  final MaintenancePriority priority;
  final MaintenanceStatus status;
  final String? photoUrl;
  final List<MaintenanceComment> comments;
  final DateTime createdAt;
}
