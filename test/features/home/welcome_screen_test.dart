import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:risotto/app.dart';
import 'package:risotto/core/network/api_health_repository.dart';
import 'package:risotto/core/theme/risotto_colors.dart';

class FakeApiHealthRepository implements ApiHealthRepository {
  FakeApiHealthRepository(this.results);

  /// Returned in order, one per call.
  final List<bool> results;
  int calls = 0;

  @override
  Future<bool> isHealthy() async => results[calls++];
}

Widget buildApp(FakeApiHealthRepository repository) => ProviderScope(
  overrides: [apiHealthRepositoryProvider.overrideWithValue(repository)],
  child: const RisottoApp(),
);

void main() {
  testWidgets('shows the brand on a cream background', (tester) async {
    await tester.pumpWidget(buildApp(FakeApiHealthRepository([true])));
    await tester.pumpAndSettle();

    expect(find.text('Risotto'), findsOneWidget);
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    final context = tester.element(find.byType(Scaffold));
    expect(
      scaffold.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      RisottoColors.cream,
    );
  });

  testWidgets('shows a connected status when the API is healthy', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(FakeApiHealthRepository([true])));
    await tester.pumpAndSettle();

    expect(find.text('Serveur connecté'), findsOneWidget);
  });

  testWidgets('shows an error and retries on tap', (tester) async {
    final repository = FakeApiHealthRepository([false, true]);
    await tester.pumpWidget(buildApp(repository));
    await tester.pumpAndSettle();
    expect(find.text('Serveur injoignable'), findsOneWidget);

    await tester.tap(find.text('Vérifier la connexion'));
    await tester.pumpAndSettle();

    expect(find.text('Serveur connecté'), findsOneWidget);
    expect(repository.calls, 2);
  });

  testWidgets('saffron button text is charcoal', (tester) async {
    await tester.pumpWidget(buildApp(FakeApiHealthRepository([true])));
    await tester.pumpAndSettle();

    final text = tester.widget<Text>(find.text('Vérifier la connexion'));
    final style = DefaultTextStyle.of(
      tester.element(find.text('Vérifier la connexion')),
    );
    expect(text.style?.color ?? style.style.color, RisottoColors.charcoal);
  });

  testWidgets('meets Android tap target and text contrast guidelines', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(buildApp(FakeApiHealthRepository([true])));
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });
}
