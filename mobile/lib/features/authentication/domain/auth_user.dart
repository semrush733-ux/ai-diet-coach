/// Authenticated account as returned by the backend.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.emailVerified,
    required this.onboarded,
  });

  final int id;
  final String email;
  final String displayName;
  final bool emailVerified;
  final bool onboarded;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: (json['id'] as num).toInt(),
        email: json['email'] as String? ?? '',
        displayName: json['display_name'] as String? ??
            json['name'] as String? ??
            '',
        emailVerified: json['email_verified'] == true ||
            json['email_verified_at'] != null,
        onboarded: json['onboarded'] == true || json['onboarded_at'] != null,
      );

  AuthUser copyWith({bool? onboarded, bool? emailVerified}) => AuthUser(
        id: id,
        email: email,
        displayName: displayName,
        emailVerified: emailVerified ?? this.emailVerified,
        onboarded: onboarded ?? this.onboarded,
      );
}
