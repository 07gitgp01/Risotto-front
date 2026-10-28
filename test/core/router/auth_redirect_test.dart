import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:risotto/core/router/app_router.dart';
import 'package:risotto/core/router/app_routes.dart';
import 'package:risotto/features/auth/application/auth_controller.dart';

import '../../helpers/in_memory_session_storage.dart';

void main() {
  const signedIn = Authenticated(testUser);
  const unknown = ProfileStatus.unknown;
  const present = ProfileStatus.present;
  const missing = ProfileStatus.missing;

  test('waits on the splash screen while the session is unknown', () {
    expect(
      appRedirect(const AuthUnknown(), unknown, AppRoutes.home),
      AppRoutes.splash,
    );
    expect(appRedirect(const AuthUnknown(), unknown, AppRoutes.splash), isNull);
  });

  test('sends signed-out users to login, except on public routes', () {
    expect(
      appRedirect(const Unauthenticated(), unknown, AppRoutes.home),
      AppRoutes.login,
    );
    expect(
      appRedirect(const Unauthenticated(), unknown, AppRoutes.myProfile),
      AppRoutes.login,
    );
    for (final route in AppRoutes.publicRoutes) {
      expect(appRedirect(const Unauthenticated(), unknown, route), isNull);
    }
  });

  test('sends signed-in users away from auth screens', () {
    expect(appRedirect(signedIn, present, AppRoutes.login), AppRoutes.home);
    expect(appRedirect(signedIn, present, AppRoutes.splash), AppRoutes.home);
    expect(appRedirect(signedIn, present, AppRoutes.home), isNull);
    expect(appRedirect(signedIn, present, AppRoutes.myProfile), isNull);
  });

  test('forces profile creation when it is missing', () {
    expect(
      appRedirect(signedIn, missing, AppRoutes.home),
      AppRoutes.profileSetup,
    );
    expect(appRedirect(signedIn, missing, AppRoutes.profileSetup), isNull);
    expect(
      appRedirect(signedIn, present, AppRoutes.profileSetup),
      AppRoutes.home,
    );
  });

  test('never blocks the user while the profile status is unknown', () {
    expect(appRedirect(signedIn, unknown, AppRoutes.home), isNull);
    expect(appRedirect(signedIn, unknown, AppRoutes.myProfile), isNull);
  });

  test('profileStatusOf maps the async profile', () {
    expect(profileStatusOf(const AsyncLoading()), unknown);
    expect(profileStatusOf(const AsyncError('x', StackTrace.empty)), unknown);
    expect(profileStatusOf(const AsyncData(null)), missing);
    expect(profileStatusOf(const AsyncData('profile')), present);
  });

  test('route helpers encode their parameters', () {
    expect(
      AppRoutes.resetPasswordFor('a+b@example.com'),
      '/reset-password?email=a%2Bb%40example.com',
    );
    expect(AppRoutes.userProfile('u1'), '/users/u1');
  });
}
