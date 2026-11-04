import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_app_lock.dart';
import '../../helpers/in_memory_session_storage.dart';
import '../../helpers/test_app.dart';

/// The fingerprint switch of the Profil tab (not the presence one).
Future<void> tapLockSwitch(WidgetTester tester) async {
  final label = find.text('Déverrouillage par empreinte');
  await revealFinder(tester, label);
  await tester.tap(
    find.descendant(
      of: find.ancestor(of: label, matching: find.byType(Row)).first,
      matching: find.byType(Switch),
    ),
  );
}

void main() {
  group('Fingerprint lock', () {
    testWidgets('can be turned on from the profile tab', (tester) async {
      final biometrics = FakeBiometricAuthenticator();
      final settings = InMemoryAppLockSettings();
      await pumpRisottoApp(
        tester,
        storage: InMemorySessionStorage(testSession()),
        biometrics: biometrics,
        appLock: settings,
      );

      await openTab(tester, 'Profil');
      await tapLockSwitch(tester);
      await tester.pumpAndSettle();

      expect(settings.enabled, isTrue);
      expect(biometrics.prompts, hasLength(1));
      expect(
        find.text('Empreinte demandée à chaque ouverture de Risotto.'),
        findsOneWidget,
      );
    });

    testWidgets('explains when the phone has no fingerprint', (tester) async {
      final settings = InMemoryAppLockSettings();
      await pumpRisottoApp(
        tester,
        storage: InMemorySessionStorage(testSession()),
        biometrics: FakeBiometricAuthenticator(available: false),
        appLock: settings,
      );

      await openTab(tester, 'Profil');
      await tapLockSwitch(tester);
      await tester.pumpAndSettle();

      expect(settings.enabled, isFalse);
      expect(find.textContaining('Configurez d’abord'), findsOneWidget);
    });

    testWidgets('opens the app once the fingerprint is given', (tester) async {
      final biometrics = FakeBiometricAuthenticator();
      await pumpRisottoApp(
        tester,
        storage: InMemorySessionStorage(testSession()),
        biometrics: biometrics,
        appLock: InMemoryAppLockSettings(enabled: true),
      );

      expect(biometrics.prompts, ['Déverrouillez Risotto']);
      expect(find.text('Risotto est verrouillé'), findsNothing);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('stays locked on failure, password fallback signs out', (
      tester,
    ) async {
      final biometrics = FakeBiometricAuthenticator(succeeds: false);
      final settings = InMemoryAppLockSettings(enabled: true);
      final storage = InMemorySessionStorage(testSession());
      await pumpRisottoApp(
        tester,
        storage: storage,
        biometrics: biometrics,
        appLock: settings,
      );

      expect(find.text('Risotto est verrouillé'), findsOneWidget);
      expect(find.text('Empreinte non reconnue. Réessayez.'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);

      biometrics.succeeds = true;
      await tester.tap(find.text('Déverrouiller'));
      await tester.pumpAndSettle();
      expect(find.text('Risotto est verrouillé'), findsNothing);
    });

    testWidgets(
      '"Utiliser mon mot de passe" signs out and turns the lock off',
      (tester) async {
        final settings = InMemoryAppLockSettings(enabled: true);
        final storage = InMemorySessionStorage(testSession());
        await pumpRisottoApp(
          tester,
          storage: storage,
          biometrics: FakeBiometricAuthenticator(succeeds: false),
          appLock: settings,
        );

        await tester.tap(find.text('Utiliser mon mot de passe'));
        await tester.pumpAndSettle();

        expect(storage.session, isNull);
        expect(settings.enabled, isFalse);
        expect(find.text('J’ai déjà un compte'), findsOneWidget);
      },
    );

    testWidgets('never shows the lock when signed out', (tester) async {
      final biometrics = FakeBiometricAuthenticator();
      await pumpRisottoApp(
        tester,
        biometrics: biometrics,
        appLock: InMemoryAppLockSettings(enabled: true),
      );

      expect(find.text('Risotto est verrouillé'), findsNothing);
      expect(find.text('J’ai déjà un compte'), findsOneWidget);
    });
  });
}
