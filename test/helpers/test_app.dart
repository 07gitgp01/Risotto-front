import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:risotto/app.dart';
import 'package:risotto/core/network/api_health_repository.dart';
import 'package:risotto/core/storage/session_storage.dart';
import 'package:risotto/features/auth/data/auth_repository.dart';

import 'fake_auth_repository.dart';
import 'in_memory_session_storage.dart';

class FakeApiHealthRepository implements ApiHealthRepository {
  FakeApiHealthRepository([List<bool>? results]) : results = results ?? [true];

  /// Returned in order, one per call; the last one repeats.
  final List<bool> results;
  int calls = 0;

  @override
  Future<bool> isHealthy() async {
    final index = calls < results.length ? calls : results.length - 1;
    calls++;
    return results[index];
  }
}

/// Pumps the whole app with fakes for every external dependency.
Future<void> pumpRisottoApp(
  WidgetTester tester, {
  FakeAuthRepository? auth,
  InMemorySessionStorage? storage,
  FakeApiHealthRepository? health,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth ?? FakeAuthRepository()),
        sessionStorageProvider.overrideWithValue(
          storage ?? InMemorySessionStorage(),
        ),
        apiHealthRepositoryProvider.overrideWithValue(
          health ?? FakeApiHealthRepository(),
        ),
      ],
      child: const RisottoApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Fills a TextFormField identified by its label.
Future<void> enterField(WidgetTester tester, String label, String text) =>
    tester.enterText(find.widgetWithText(TextFormField, label), text);

/// Scrolls [text] into view, then taps it (forms can be taller than the test screen).
Future<void> tapText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
