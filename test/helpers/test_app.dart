import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:risotto/app.dart';
import 'package:risotto/core/network/api_health_repository.dart';
import 'package:risotto/core/realtime/realtime_client.dart';
import 'package:risotto/core/storage/session_storage.dart';
import 'package:risotto/features/auth/data/auth_repository.dart';
import 'package:risotto/features/connections/data/connections_repository.dart';
import 'package:risotto/features/contacts/application/contacts_providers.dart';
import 'package:risotto/features/contacts/data/contacts_repository.dart';
import 'package:risotto/features/contacts/presentation/scan_screen.dart';
import 'package:risotto/features/messaging/data/messaging_repository.dart';
import 'package:risotto/features/notifications/application/push_registration.dart';
import 'package:risotto/features/notifications/data/notifications_repository.dart';
import 'package:risotto/features/profile/application/photo_picker.dart';
import 'package:risotto/features/profile/data/profile_repository.dart';

import 'fake_auth_repository.dart';
import 'fake_connections_repository.dart';
import 'fake_contacts_repository.dart';
import 'fake_messaging.dart';
import 'fake_notifications.dart';
import 'fake_profile_repository.dart';
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
/// By default the signed-in user already has a profile.
Future<void> pumpRisottoApp(
  WidgetTester tester, {
  FakeAuthRepository? auth,
  InMemorySessionStorage? storage,
  FakeApiHealthRepository? health,
  FakeProfileRepository? profiles,
  FakePhotoPicker? photoPicker,
  FakeContactsRepository? contacts,
  FakeCardSharer? cardSharer,
  List<String> scannerPayloads = const [],
  FakeConnectionsRepository? connections,
  FakeMessagingRepository? messaging,
  FakeRealtimeClient? realtime,
  FakeNotificationsRepository? notifications,
  FakePushService? push,
  List<Override> extraOverrides = const [],
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
        profileRepositoryProvider.overrideWithValue(
          profiles ?? FakeProfileRepository(mine: testProfile()),
        ),
        photoPickerProvider.overrideWithValue(photoPicker ?? FakePhotoPicker()),
        contactsRepositoryProvider.overrideWithValue(
          contacts ?? FakeContactsRepository(),
        ),
        cardSharerProvider.overrideWithValue(cardSharer ?? FakeCardSharer()),
        qrScannerBuilderProvider.overrideWithValue(
          fakeScanner(scannerPayloads),
        ),
        connectionsRepositoryProvider.overrideWithValue(
          connections ?? FakeConnectionsRepository(),
        ),
        messagingRepositoryProvider.overrideWithValue(
          messaging ?? FakeMessagingRepository(),
        ),
        // Never open a real socket in widget tests.
        realtimeClientProvider.overrideWithValue(
          realtime ?? FakeRealtimeClient(),
        ),
        notificationsRepositoryProvider.overrideWithValue(
          notifications ?? FakeNotificationsRepository(),
        ),
        pushServiceProvider.overrideWithValue(push ?? FakePushService()),
        ...extraOverrides,
      ],
      child: const RisottoApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Brings [finder] on screen: lazily built lists are scrolled until it exists.
Future<void> revealFinder(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    // The page's main list (the last one: pushed routes are built after earlier ones).
    final page = find.byType(ListView).last;
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find
          .descendant(of: page, matching: find.byType(Scrollable))
          .first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

/// Fills a TextFormField identified by its label.
Future<void> enterField(WidgetTester tester, String label, String text) async {
  final finder = find.widgetWithText(TextFormField, label);
  await revealFinder(tester, finder);
  await tester.enterText(finder, text);
}

/// Scrolls [text] into view, then taps it (forms can be taller than the test screen).
Future<void> tapText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  await revealFinder(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
