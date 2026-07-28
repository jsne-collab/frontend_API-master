enum UserRole {
  owner,
  tenant,
  admin;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => UserRole.tenant,
    );
  }
}

class UserProfile {
  const UserProfile({
    this.avatarUrl,
    this.address,
    this.city,
    this.idCardNumber,
    this.dateOfBirth,
  });

  factory UserProfile.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const UserProfile();

    return UserProfile(
      avatarUrl: json['avatar_url'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      idCardNumber: json['id_card_number'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'] as String)
          : null,
    );
  }

  final String? avatarUrl;
  final String? address;
  final String? city;
  final String? idCardNumber;
  final DateTime? dateOfBirth;
}

class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.emailVerifiedAt,
    this.profile = const UserProfile(),
    this.profileCompleted = true,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String? ?? '',
      role: UserRole.fromString(json['role'] as String),
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.tryParse(json['email_verified_at'] as String)
          : null,
      profile: UserProfile.fromJson(json['profile'] as Map<String, dynamic>?),
      profileCompleted: json['profile_completed'] as bool? ?? true,
    );
  }

  final int id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final DateTime? emailVerifiedAt;
  final UserProfile profile;
  final bool profileCompleted;

  bool get isEmailVerified => emailVerifiedAt != null;
}
