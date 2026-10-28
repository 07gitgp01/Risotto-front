import 'package:flutter_test/flutter_test.dart';
import 'package:risotto/core/router/app_router.dart';
import 'package:risotto/core/router/app_routes.dart';
import 'package:risotto/features/auth/application/auth_controller.dart';

import '../../helpers/in_memory_session_storage.dart';

void main() {
  const signedIn = Authenticated(testUser);

  test('waits on the splash screen while the session is unknown', () {
    expect(authRedirect(const AuthUnknown(), AppRoutes.home), AppRoutes.splash);
    expect(authRedirect(const AuthUnknown(), AppRoutes.splash), isNull);
  });

  test('sends signed-out users to login, except on public routes', () {
    expect(
      authRedirect(const Unauthenticated(), AppRoutes.home),
      AppRoutes.login,
    );
    expect(
      authRedirect(const Unauthenticated(), AppRoutes.splash),
      AppRoutes.login,
    );
    for (final route in AppRoutes.publicRoutes) {
      expect(authRedirect(const Unauthenticated(), route), isNull);
    }
  });

  test('sends signed-in users away from auth screens', () {
    expect(authRedirect(signedIn, AppRoutes.login), AppRoutes.home);
    expect(authRedirect(signedIn, AppRoutes.splash), AppRoutes.home);
    expect(authRedirect(signedIn, AppRoutes.home), isNull);
  });

  test('resetPasswordFor encodes the email', () {
    expect(
      AppRoutes.resetPasswordFor('a+b@example.com'),
      '/reset-password?email=a%2Bb%40example.com',
    );
  });
}
