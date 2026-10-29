import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:risotto/core/network/api_exception.dart';
import 'package:risotto/core/router/app_router.dart';
import 'package:risotto/core/router/app_routes.dart';
import 'package:risotto/features/admin/data/admin_models.dart';
import 'package:risotto/features/admin/data/admin_repository.dart';
import 'package:risotto/features/auth/application/auth_controller.dart';
import 'package:risotto/features/auth/data/auth_models.dart';

import '../../helpers/fake_admin.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/in_memory_session_storage.dart';
import '../../helpers/test_app.dart';

const _admin = AuthUser(
  id: 'user-1',
  email: 'alice@example.com',
  isAdmin: true,
);

void main() {
  late FakeAdminRepository admin;

  setUp(() => admin = FakeAdminRepository());

  Future<void> start(WidgetTester tester, {AuthUser user = _admin}) {
    final auth = FakeAuthRepository()..user = user;
    return pumpRisottoApp(
      tester,
      auth: auth,
      storage: InMemorySessionStorage(testSession(user: user)),
      extraOverrides: [adminRepositoryProvider.overrideWithValue(admin)],
    );
  }

  Future<void> openAdmin(WidgetTester tester) async {
    await start(tester);
    await openTab(tester, 'Profil');
    await tapText(tester, 'Administration');
  }

  test('the role comes from the API and survives the stored session', () {
    final user = AuthUser.fromJson({
      'id': 'a',
      'email': 'a@example.com',
      'role': 'admin',
    });
    expect(user.isAdmin, isTrue);
    expect(AuthUser.fromJson(user.toJson()), user);
    expect(
      AuthUser.fromJson({'id': 'b', 'email': 'b@example.com'}).isAdmin,
      isFalse,
    );
  });

  test('a member is sent back home from the admin route', () {
    expect(
      appRedirect(
        const Authenticated(testUser),
        ProfileStatus.present,
        AppRoutes.admin,
      ),
      AppRoutes.home,
    );
    expect(
      appRedirect(
        const Authenticated(_admin),
        ProfileStatus.present,
        AppRoutes.admin,
      ),
      isNull,
    );
  });

  testWidgets('a member has no administration entry', (tester) async {
    await start(tester, user: testUser);
    await openTab(tester, 'Profil');
    await revealFinder(tester, find.text('Se déconnecter'));
    expect(find.text('Administration'), findsNothing);
  });

  Finder inCard(String accountId, String text) => find.descendant(
    of: find.byKey(ValueKey('account-$accountId')),
    matching: find.text(text),
  );

  testWidgets('shows the platform figures and the accounts', (tester) async {
    final semantics = tester.ensureSemantics();
    await openAdmin(tester);

    expect(find.bySemanticsLabel('12 Membres'), findsOneWidget);
    expect(find.bySemanticsLabel('42 Messages (7 j)'), findsOneWidget);
    await revealFinder(tester, find.text('4 comptes'));
    await revealFinder(tester, find.text('Bob Durand'));
    await revealFinder(tester, find.text('Profil non créé'));
    expect(find.text('newbie@example.com'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('suspends a member after confirmation, then reactivates', (
    tester,
  ) async {
    await openAdmin(tester);
    await revealFinder(tester, find.byKey(const ValueKey('account-newbie')));
    // Neither the admin herself nor an already suspended member can be suspended.
    expect(inCard('user-1', 'Suspendre'), findsNothing);
    expect(inCard('carol', 'Réactiver'), findsOneWidget);

    await revealFinder(tester, inCard('bob', 'Suspendre'));
    await tester.tap(inCard('bob', 'Suspendre'));
    await tester.pumpAndSettle();
    expect(find.text('Suspendre Bob Durand ?'), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(admin.calls, isNot(contains('suspend:bob')));

    await tester.tap(inCard('bob', 'Suspendre'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Suspendre'));
    await tester.pumpAndSettle();
    expect(admin.calls, contains('suspend:bob'));
    expect(find.text('Bob Durand suspendu.'), findsOneWidget);
    expect(inCard('bob', 'Suspendu'), findsOneWidget);

    await tester.tap(inCard('bob', 'Réactiver'));
    await tester.pumpAndSettle();
    expect(admin.calls, contains('reactivate:bob'));
  });

  testWidgets('searches and filters the accounts', (tester) async {
    final field = find.widgetWithText(TextField, 'Rechercher par nom ou email');
    await openAdmin(tester);
    await revealFinder(tester, field);
    await tester.enterText(field, 'bob');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(admin.calls, contains('accounts:bob:all:0'));
    expect(find.text('1 compte'), findsOneWidget);

    await tester.enterText(field, '');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    final suspendedSegment = find.descendant(
      of: find.byType(SegmentedButton<AccountFilter>),
      matching: find.text('Suspendus'),
    );
    await revealFinder(tester, suspendedSegment);
    await tester.tap(suspendedSegment);
    await tester.pumpAndSettle();
    expect(admin.calls, contains('accounts::suspended:0'));
    await revealFinder(tester, find.text('Carol Petit'));
    expect(find.text('Bob Durand'), findsNothing);
  });

  testWidgets('shows an error with a retry when the API refuses', (
    tester,
  ) async {
    admin.failWith = const ApiException(ApiErrorKind.network);
    await openAdmin(tester);
    expect(find.text('Réessayer'), findsWidgets);

    admin.failWith = null;
    await tester.tap(find.text('Réessayer').last);
    await tester.pumpAndSettle();
    await revealFinder(tester, find.text('Bob Durand'));
  });
}
