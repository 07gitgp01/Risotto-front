import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:risotto/core/network/api_exception.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/in_memory_session_storage.dart';
import '../../helpers/test_app.dart';

void main() {
  late FakeAuthRepository auth;
  late InMemorySessionStorage storage;

  setUp(() {
    auth = FakeAuthRepository();
    storage = InMemorySessionStorage();
  });

  /// Signed out, the app opens on the welcome screen: go on to the login form.
  Future<void> start(WidgetTester tester) async {
    await pumpRisottoApp(tester, auth: auth, storage: storage);
    if (storage.session == null) {
      await openLogin(tester);
    }
  }

  group('login', () {
    testWidgets('signed-out users land on the welcome screen', (tester) async {
      await pumpRisottoApp(tester, auth: auth, storage: storage);
      expect(find.text('Partagez vos contacts d’un scan'), findsOneWidget);

      await tapText(tester, 'Commencer');
      expect(find.text('Créer un compte'), findsOneWidget);
    });

    testWidgets('the welcome screen leads to the login form', (tester) async {
      await start(tester);
      expect(find.text('Ravi de vous revoir !'), findsOneWidget);
    });

    testWidgets('validates the form before calling the API', (tester) async {
      await start(tester);
      await tapText(tester, 'Se connecter');

      expect(find.text('Saisissez votre email.'), findsOneWidget);
      expect(find.text('Saisissez votre mot de passe.'), findsOneWidget);
      expect(auth.calls, isEmpty);
    });

    testWidgets('signs in and shows home', (tester) async {
      await start(tester);
      await enterField(tester, 'Email', 'alice@example.com');
      await enterField(tester, 'Mot de passe', 'risotto-2026');
      await tapText(tester, 'Se connecter');

      expect(auth.calls, ['login']);
      expect(find.textContaining('Bonjour'), findsOneWidget);
      expect(storage.session, isNotNull);
    });

    testWidgets('shows a clear error on wrong credentials', (tester) async {
      auth.failWith = const ApiException(ApiErrorKind.unauthorized);
      await start(tester);
      await enterField(tester, 'Email', 'alice@example.com');
      await enterField(tester, 'Mot de passe', 'wrong');
      await tapText(tester, 'Se connecter');

      expect(find.text('Email ou mot de passe incorrect.'), findsOneWidget);
      expect(find.text('Ravi de vous revoir !'), findsOneWidget);
    });

    testWidgets('explains that a suspended account cannot sign in', (
      tester,
    ) async {
      auth.failWith = const ApiException(
        ApiErrorKind.unauthorized,
        statusCode: 403,
      );
      await start(tester);
      await enterField(tester, 'Email', 'alice@example.com');
      await enterField(tester, 'Mot de passe', 'risotto-2026');
      await tapText(tester, 'Se connecter');

      expect(
        find.text('Ce compte a été suspendu. Contactez l’équipe Risotto.'),
        findsOneWidget,
      );
    });

    testWidgets('shows a network error message', (tester) async {
      auth.failWith = const ApiException(ApiErrorKind.network);
      await start(tester);
      await enterField(tester, 'Email', 'alice@example.com');
      await enterField(tester, 'Mot de passe', 'x');
      await tapText(tester, 'Se connecter');

      expect(
        find.textContaining('Impossible de joindre le serveur'),
        findsOneWidget,
      );
    });

    testWidgets('the password can be revealed', (tester) async {
      await start(tester);
      final field = find.descendant(
        of: find.widgetWithText(TextFormField, 'Mot de passe'),
        matching: find.byType(EditableText),
      );
      expect(tester.widget<EditableText>(field).obscureText, isTrue);
      await tester.tap(find.byTooltip('Afficher le mot de passe'));
      await tester.pump();
      expect(tester.widget<EditableText>(field).obscureText, isFalse);
    });
  });

  group('register', () {
    Future<void> openRegister(WidgetTester tester) async {
      await start(tester);
      await tapText(tester, 'Créer un compte');
    }

    testWidgets('applies the password policy and confirmation', (tester) async {
      await openRegister(tester);
      await enterField(tester, 'Email', 'bob@example.com');
      await enterField(tester, 'Mot de passe', 'short');
      await enterField(tester, 'Confirmer le mot de passe', 'other');
      await tapText(tester, 'Créer mon compte');

      expect(find.text('Au moins 8 caractères.'), findsOneWidget);
      expect(
        find.text('Les mots de passe ne correspondent pas.'),
        findsOneWidget,
      );
      expect(auth.calls, isEmpty);
    });

    testWidgets('creates the account and signs in', (tester) async {
      await openRegister(tester);
      await enterField(tester, 'Email', 'bob@example.com');
      await enterField(tester, 'Mot de passe', 'risotto-2026');
      await enterField(tester, 'Confirmer le mot de passe', 'risotto-2026');
      await tapText(tester, 'Créer mon compte');

      expect(auth.calls, ['register']);
      expect(find.textContaining('Bonjour'), findsOneWidget);
    });

    testWidgets('explains that the email is taken', (tester) async {
      auth.failWith = const ApiException(ApiErrorKind.conflict);
      await openRegister(tester);
      await enterField(tester, 'Email', 'bob@example.com');
      await enterField(tester, 'Mot de passe', 'risotto-2026');
      await enterField(tester, 'Confirmer le mot de passe', 'risotto-2026');
      await tapText(tester, 'Créer mon compte');

      expect(
        find.text('Un compte existe déjà avec cet email.'),
        findsOneWidget,
      );
    });
  });

  group('password reset', () {
    testWidgets('request a code, then set a new password', (tester) async {
      await start(tester);
      await tapText(tester, 'Mot de passe oublié ?');

      await enterField(tester, 'Email', 'Alice@Example.com');
      await tapText(tester, 'Recevoir un code');
      expect(auth.calls, ['requestPasswordReset']);
      expect(auth.lastArgs['email'], 'alice@example.com');

      // The reset screen opens with the email prefilled.
      expect(find.text('Nouveau mot de passe'), findsWidgets);

      await enterField(tester, 'Code à 6 chiffres', '042517');
      await enterField(tester, 'Nouveau mot de passe', 'nouveau-2027');
      await enterField(tester, 'Confirmer le mot de passe', 'nouveau-2027');
      await tapText(tester, 'Changer le mot de passe');

      expect(auth.calls.last, 'resetPassword');
      expect(auth.lastArgs, {
        'email': 'alice@example.com',
        'code': '042517',
        'newPassword': 'nouveau-2027',
      });
      expect(find.text('Ravi de vous revoir !'), findsOneWidget);
      expect(find.textContaining('Mot de passe modifié'), findsOneWidget);
    });

    testWidgets('reports an invalid code', (tester) async {
      await start(tester);
      await tapText(tester, 'Mot de passe oublié ?');
      await enterField(tester, 'Email', 'alice@example.com');
      await tapText(tester, 'Recevoir un code');

      auth.failWith = const ApiException(ApiErrorKind.invalidInput);
      await enterField(tester, 'Code à 6 chiffres', '000000');
      await enterField(tester, 'Nouveau mot de passe', 'nouveau-2027');
      await enterField(tester, 'Confirmer le mot de passe', 'nouveau-2027');
      await tapText(tester, 'Changer le mot de passe');

      expect(find.textContaining('Code invalide ou expiré'), findsOneWidget);
    });

    testWidgets('the code field only accepts 6 digits', (tester) async {
      await start(tester);
      await tapText(tester, 'Mot de passe oublié ?');
      await enterField(tester, 'Email', 'alice@example.com');
      await tapText(tester, 'Recevoir un code');

      await enterField(tester, 'Code à 6 chiffres', '12ab345678');
      await tester.pump();
      expect(find.text('123456'), findsOneWidget);
    });
  });

  group('session', () {
    testWidgets('a stored session opens home directly', (tester) async {
      storage.session = testSession();
      await start(tester);
      expect(find.textContaining('Bonjour'), findsOneWidget);
    });

    testWidgets('logout returns to the welcome screen', (tester) async {
      storage.session = testSession();
      await start(tester);
      await signOut(tester);

      expect(find.text('Partagez vos contacts d’un scan'), findsOneWidget);
      expect(storage.session, isNull);
      expect(auth.calls, contains('logout'));
    });
  });

  testWidgets('auth screens meet tap target and contrast guidelines', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await start(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
