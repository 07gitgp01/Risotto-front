import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:risotto/core/widgets/risotto_loader.dart';

void main() {
  Future<void> pumpLoader(WidgetTester tester, Widget loader) =>
      tester.pumpWidget(MaterialApp(home: Center(child: loader)));

  testWidgets('animates at the requested size', (tester) async {
    await pumpLoader(tester, const RisottoLoader(size: 48));
    expect(tester.getSize(find.byType(RisottoLoader)), const Size(48, 48));

    // Still animating after a full cycle (repeats forever).
    await tester.pump(const Duration(milliseconds: 1600));
    expect(tester.hasRunningAnimations, isTrue);
  });

  testWidgets('is announced to screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpLoader(tester, const RisottoLoader());
    expect(find.bySemanticsLabel('Chargement'), findsOneWidget);

    await pumpLoader(
      tester,
      const RisottoLoader(semanticsLabel: 'Connexion en cours'),
    );
    expect(find.bySemanticsLabel('Connexion en cours'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('stops its animation when removed', (tester) async {
    await pumpLoader(tester, const RisottoLoader());
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.hasRunningAnimations, isFalse);
  });
}
