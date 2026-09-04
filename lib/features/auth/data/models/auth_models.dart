class AuthAccount {
  const AuthAccount({
    required this.id,
    required this.email,
    required this.username,
    required this.role,
    required this.emailVerified,
    required this.phoneNumberVerified,
    this.phoneNumber,
    this.createdAt,
  });

  final String id;
  final String email;
  final String username;
  final String role;
  final bool emailVerified;
  final bool phoneNumberVerified;
  final String? phoneNumber;
  final DateTime? createdAt;

  factory AuthAccount.fromJson(Map<String, dynamic> json) => AuthAccount(
    id: json['id'] as String,
    email: json['email'] as String,
    username: json['username'] as String,
    role: json['role'] as String,
    emailVerified: json['email_verified'] as bool,
    phoneNumberVerified: json['phone_number_verified'] as bool,
    phoneNumber: json['phone_number'] as String?,
    createdAt: _dateTime(json['createdAt']),
  );
}

class TokenUser {
  const TokenUser({required this.id, required this.email, required this.role});

  final String id;
  final String? email;
  final String role;

  factory TokenUser.fromJson(Map<String, dynamic> json) => TokenUser(
    id: json['id'] as String,
    email: json['email'] as String?,
    role: json['role'] as String,
  );
}

class LoginResult {
  const LoginResult({required this.account, required this.token});

  final AuthAccount account;
  final String token;

  factory LoginResult.fromJson(Map<String, dynamic> json) => LoginResult(
    account: AuthAccount.fromJson(json['account'] as Map<String, dynamic>),
    token: json['token'] as String,
  );
}

class AuthUser {
  const AuthUser({required this.id, required this.email, required this.role});

  final String id;
  final String? email;
  final String role;

  factory AuthUser.fromAccount(AuthAccount account) =>
      AuthUser(id: account.id, email: account.email, role: account.role);

  factory AuthUser.fromToken(TokenUser user) =>
      AuthUser(id: user.id, email: user.email, role: user.role);
}

DateTime? _dateTime(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
