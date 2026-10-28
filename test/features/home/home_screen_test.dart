import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:risotto/core/theme/risotto_colors.dart';

import '../../helpers/in_memory_session_storage.dart';
import '../../helpers/test_app.dart';

void main() {
  Future<void> startSignedIn(
    WidgetTester tester, [
    FakeApiHealthRepository? health,
  ]) => pumpRisottoApp(
    tester,
    storage: InMemorySessionStorage(testSession()),
    health: health,
  );

  testWidgets('greets the user on a cream background', (tester) async {
    await startSignedIn(tester);

    expect(find.text('Bienvenue'), findsOneWidget);
    expect(find.text(testUser.email), findsOneWidget);
    final context = tester.element(find.byType(Scaffold));
    expect(Theme.of(context).scaffoldBackgroundColor, RisottoColors.cream);
  });

  testWidgets('shows a connected status when the API is healthy', (
    tester,
  ) async {
    await startSignedIn(tester);
    expect(find.text('Serveur connecté'), findsOneWidget);
  });

  testWidgets('shows an error and retries on tap', (tester) async {
    final health = FakeApiHealthRepository([false, true]);
    await startSignedIn(tester, health);
    expect(find.text('Serveur injoignable'), findsOneWidget);

    await tester.tap(find.text('Vérifier la connexion'));
    await tester.pumpAndSettle();

    expect(find.text('Serveur connecté'), findsOneWidget);
    expect(health.calls, 2);
  });

  testWidgets('saffron button text is charcoal', (tester) async {
    await startSignedIn(tester);
    final label = find.text('Vérifier la connexion');
    final text = tester.widget<Text>(label);
    final inherited = DefaultTextStyle.of(tester.element(label)).style.color;
    expect(text.style?.color ?? inherited, RisottoColors.charcoal);
  });

  testWidgets('meets tap target and text contrast guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await startSignedIn(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
