/// Signed-in user as returned by the API.
class AuthUser {
  const AuthUser({required this.id, required this.email});

  factory AuthUser.fromJson(Map<String, dynamic> json) =>
      AuthUser(id: json['id'] as String, email: json['email'] as String);

  final String id;
  final String email;

  Map<String, dynamic> toJson() => {'id': id, 'email': email};

  @override
  bool operator ==(Object other) =>
      other is AuthUser && other.id == id && other.email == email;

  @override
  int get hashCode => Object.hash(id, email);
}

class AuthTokens {
  const AuthTokens({required this.accessToken, required this.refreshToken});

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String,
  );

  final String accessToken;
  final String refreshToken;
}

/// What is persisted in secure storage: tokens plus the user, so the app can
/// start signed in without a network round trip.
class AuthSession {
  const AuthSession({required this.tokens, required this.user});

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    tokens: AuthTokens.fromJson(json),
    user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
  );

  final AuthTokens tokens;
  final AuthUser user;

  AuthSession copyWith({AuthTokens? tokens, AuthUser? user}) =>
      AuthSession(tokens: tokens ?? this.tokens, user: user ?? this.user);

  Map<String, dynamic> toJson() => {
    'accessToken': tokens.accessToken,
    'refreshToken': tokens.refreshToken,
    'user': user.toJson(),
  };
}
