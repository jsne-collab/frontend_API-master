enum PropertyType {
  maison,
  appartement,
  studio,
  chambre;

  static PropertyType fromString(String value) {
    return PropertyType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => PropertyType.appartement,
    );
  }

  String get label => switch (this) {
    PropertyType.maison => 'Maison',
    PropertyType.appartement => 'Appartement',
    PropertyType.studio => 'Studio',
    PropertyType.chambre => 'Chambre',
  };
}

enum PropertyStatus {
  available,
  rented,
  maintenance;

  static PropertyStatus fromString(String value) {
    return PropertyStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => PropertyStatus.available,
    );
  }

  String get label => switch (this) {
    PropertyStatus.available => 'Disponible',
    PropertyStatus.rented => 'Loué',
    PropertyStatus.maintenance => 'En maintenance',
  };
}

class PropertyImage {
  const PropertyImage({
    required this.id,
    required this.url,
    required this.isPrimary,
  });

  factory PropertyImage.fromJson(Map<String, dynamic> json) {
    return PropertyImage(
      id: json['id'] as int,
      url: json['url'] as String,
      isPrimary: json['is_primary'] as bool? ?? false,
    );
  }

  final int id;
  final String url;
  final bool isPrimary;
}

class Property {
  const Property({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.type,
    required this.address,
    required this.city,
    this.surfaceArea,
    required this.roomsCount,
    required this.monthlyRent,
    required this.depositAmount,
    required this.status,
    this.description,
    this.images = const [],
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'] as int,
      ownerId: json['owner_id'] as int,
      title: json['title'] as String,
      type: PropertyType.fromString(json['type'] as String),
      address: json['address'] as String,
      city: json['city'] as String,
      surfaceArea: (json['surface_area'] as num?)?.toDouble(),
      roomsCount: json['rooms_count'] as int,
      monthlyRent: (json['monthly_rent'] as num).toDouble(),
      depositAmount: (json['deposit_amount'] as num).toDouble(),
      status: PropertyStatus.fromString(json['status'] as String),
      description: json['description'] as String?,
      images: json['images'] != null
          ? (json['images'] as List)
                .map((e) => PropertyImage.fromJson(e as Map<String, dynamic>))
                .toList()
          : const [],
    );
  }

  final int id;
  final int ownerId;
  final String title;
  final PropertyType type;
  final String address;
  final String city;
  final double? surfaceArea;
  final int roomsCount;
  final double monthlyRent;
  final double depositAmount;
  final PropertyStatus status;
  final String? description;
  final List<PropertyImage> images;

  String? get primaryImageUrl {
    if (images.isEmpty) return null;
    final primary = images.where((image) => image.isPrimary);
    return primary.isNotEmpty ? primary.first.url : images.first.url;
  }
}
