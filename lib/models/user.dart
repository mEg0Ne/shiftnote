class User {
  final int id;
  final String email;
  final String displayName;
  final String? bio;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.email,
    required this.displayName,
    this.bio,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromMap(Map<String, Object?> m) => User(
        id: m['id'] as int,
        email: m['email'] as String,
        displayName: m['display_name'] as String,
        bio: m['bio'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String),
        updatedAt: DateTime.parse(m['updated_at'] as String),
      );

  User copyWith({String? displayName, String? bio, DateTime? updatedAt}) => User(
        id: id,
        email: email,
        displayName: displayName ?? this.displayName,
        bio: bio,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

/// 認証用（ハッシュとソルト付き）。画面には渡さない。
class UserCredential {
  final User user;
  final String passwordHash;
  final String salt;
  const UserCredential(this.user, this.passwordHash, this.salt);
}
