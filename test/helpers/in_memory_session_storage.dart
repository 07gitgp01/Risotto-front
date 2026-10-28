import 'package:risotto/core/storage/session_storage.dart';
import 'package:risotto/features/auth/data/auth_models.dart';

class InMemorySessionStorage implements SessionStorage {
  InMemorySessionStorage([this.session]);

  AuthSession? session;
  int clears = 0;

  @override
  Future<AuthSession?> read() async => session;

  @override
  Future<void> save(AuthSession session) async => this.session = session;

  @override
  Future<void> clear() async {
    clears++;
    session = null;
  }
}

const testUser = AuthUser(id: 'user-1', email: 'alice@example.com');

AuthSession testSession({
  String access = 'access-1',
  String refresh = 'refresh-1',
  AuthUser user = testUser,
}) => AuthSession(
  tokens: AuthTokens(accessToken: access, refreshToken: refresh),
  user: user,
);
