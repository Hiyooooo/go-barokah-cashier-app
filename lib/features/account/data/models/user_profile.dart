class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.phoneNumber,
    required this.emailVerified,
    required this.phoneNumberVerified,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String? phoneNumber;
  final bool emailVerified;
  final bool phoneNumberVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    role: json['role'] as String,
    phoneNumber: json['phoneNumber'] as String?,
    emailVerified: json['emailVerified'] as bool,
    phoneNumberVerified: json['phoneNumberVerified'] as bool,
    createdAt: _dateTime(json['createdAt']),
    updatedAt: _dateTime(json['updatedAt']),
  );
}

DateTime? _dateTime(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
