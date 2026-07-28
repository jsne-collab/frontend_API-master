enum LeaseStatus {
  pending,
  active,
  terminated,
  expired;

  static LeaseStatus fromString(String value) {
    return LeaseStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => LeaseStatus.pending,
    );
  }

  String get label => switch (this) {
    LeaseStatus.pending => 'En attente',
    LeaseStatus.active => 'Actif',
    LeaseStatus.terminated => 'Résilié',
    LeaseStatus.expired => 'Expiré',
  };
}

class LeaseProperty {
  const LeaseProperty({
    required this.id,
    required this.title,
    required this.address,
    required this.city,
  });

  factory LeaseProperty.fromJson(Map<String, dynamic> json) {
    return LeaseProperty(
      id: json['id'] as int,
      title: json['title'] as String,
      address: json['address'] as String,
      city: json['city'] as String,
    );
  }

  final int id;
  final String title;
  final String address;
  final String city;
}

class LeaseUnit {
  const LeaseUnit({required this.id, required this.unitName});

  factory LeaseUnit.fromJson(Map<String, dynamic> json) {
    return LeaseUnit(
      id: json['id'] as int,
      unitName: json['unit_name'] as String,
    );
  }

  final int id;
  final String unitName;
}

class LeasePerson {
  const LeasePerson({
    required this.id,
    required this.name,
    this.phone,
    this.email,
  });

  factory LeasePerson.fromJson(Map<String, dynamic> json) {
    return LeasePerson(
      id: json['id'] as int,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
    );
  }

  final int id;
  final String name;
  final String? phone;
  final String? email;
}

class Lease {
  const Lease({
    required this.id,
    required this.property,
    this.unit,
    required this.tenant,
    required this.owner,
    required this.startDate,
    required this.endDate,
    required this.monthlyRent,
    required this.depositAmount,
    required this.status,
    this.contractPdfUrl,
  });

  factory Lease.fromJson(Map<String, dynamic> json) {
    return Lease(
      id: json['id'] as int,
      property: LeaseProperty.fromJson(
        json['property'] as Map<String, dynamic>,
      ),
      unit: json['unit'] != null
          ? LeaseUnit.fromJson(json['unit'] as Map<String, dynamic>)
          : null,
      tenant: LeasePerson.fromJson(json['tenant'] as Map<String, dynamic>),
      owner: LeasePerson.fromJson(json['owner'] as Map<String, dynamic>),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      monthlyRent: (json['monthly_rent'] as num).toDouble(),
      depositAmount: (json['deposit_amount'] as num).toDouble(),
      status: LeaseStatus.fromString(json['status'] as String),
      contractPdfUrl: json['contract_pdf_url'] as String?,
    );
  }

  final int id;
  final LeaseProperty property;
  final LeaseUnit? unit;
  final LeasePerson tenant;
  final LeasePerson owner;
  final DateTime startDate;
  final DateTime endDate;
  final double monthlyRent;
  final double depositAmount;
  final LeaseStatus status;
  final String? contractPdfUrl;
}
