import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:risotto/app.dart';
import 'package:risotto/core/offline/connectivity.dart';
import 'package:risotto/core/offline/response_cache.dart';

import '../../helpers/fake_dashboard.dart';
import '../../helpers/fake_messaging.dart';
import '../../helpers/in_memory_session_storage.dart';
import '../../helpers/test_app.dart';

ProviderContainer containerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(RisottoApp)));

void main() {
  group('offline', () {
    testWidgets('shows a banner while offline and retries on demand', (
      tester,
    ) async {
      final dashboard = FakeDashboardRepository(busyDashboardJson());
      await pumpRisottoApp(
        tester,
        storage: InMemorySessionStorage(testSession()),
        dashboard: dashboard,
      );
      expect(find.textContaining('Hors ligne'), findsNothing);

      containerOf(tester).read(offlineProvider.notifier).markOffline();
      await tester.pump();
      expect(find.textContaining('Hors ligne'), findsOneWidget);

      final loads = dashboard.loads;
      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();
      expect(dashboard.loads, greaterThan(loads));

      containerOf(tester).read(offlineProvider.notifier).markOnline();
      await tester.pump();
      expect(find.textContaining('Hors ligne'), findsNothing);
    });

    testWidgets('signing out wipes the offline cache', (tester) async {
      final cache = MemoryResponseCache();
      await cache.write('user-1', '/dashboard?', {'secret': true});
      await pumpRisottoApp(
        tester,
        storage: InMemorySessionStorage(testSession()),
        responseCache: cache,
      );
      await tester.tap(find.byTooltip('Se déconnecter'));
      await tester.pumpAndSettle();

      expect(await cache.read('user-1', '/dashboard?'), isNull);
    });
  });

  group('accessibility', () {
    void largeText(WidgetTester tester) {
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    }

    testWidgets('login stays usable with a large text size', (tester) async {
      largeText(tester);
      await pumpRisottoApp(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('Connexion'), findsOneWidget);
    });

    testWidgets('the dashboard stays usable with a large text size', (
      tester,
    ) async {
      largeText(tester);
      await pumpRisottoApp(
        tester,
        storage: InMemorySessionStorage(testSession()),
        dashboard: FakeDashboardRepository(busyDashboardJson()),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Bonjour, Alice'), findsOneWidget);
    });

    testWidgets('chat bubbles are read as one sentence', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpRisottoApp(
        tester,
        storage: InMemorySessionStorage(testSession()),
        messaging: FakeMessagingRepository(
          messages: [
            chatMessage('m2', 'bob', 'Ça marche'),
            chatMessage('m1', 'user-1', 'On se voit demain ?'),
          ],
          unread: 1,
        ),
      );
      await tapText(tester, 'Messages');
      await tapText(tester, 'Bob Durand');

      expect(
        find.bySemanticsLabel(RegExp(r'^Vous, On se voit demain \?, ')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp(r'^Message reçu, Ça marche, ')),
        findsOneWidget,
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('notifications screen meets the guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpRisottoApp(
        tester,
        storage: InMemorySessionStorage(testSession()),
      );
      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pumpAndSettle();
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  });
}
