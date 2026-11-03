import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:risotto/app.dart';
import 'package:risotto/core/offline/response_cache.dart';
import 'package:risotto/core/realtime/realtime_client.dart';
import 'package:risotto/core/storage/session_storage.dart';
import 'package:risotto/features/auth/data/auth_repository.dart';
import 'package:risotto/features/connections/data/connections_repository.dart';
import 'package:risotto/features/contacts/application/contacts_providers.dart';
import 'package:risotto/features/contacts/data/contacts_repository.dart';
import 'package:risotto/features/contacts/application/qr_scanner.dart';
import 'package:risotto/features/dashboard/data/dashboard_repository.dart';
import 'package:risotto/features/messaging/data/messaging_repository.dart';
import 'package:risotto/features/notifications/application/push_registration.dart';
import 'package:risotto/features/notifications/data/notifications_repository.dart';
import 'package:risotto/features/profile/application/photo_picker.dart';
import 'package:risotto/features/profile/data/profile_repository.dart';

import 'fake_auth_repository.dart';
import 'fake_connections_repository.dart';
import 'fake_contacts_repository.dart';
import 'fake_dashboard.dart';
import 'fake_messaging.dart';
import 'fake_notifications.dart';
import 'fake_profile_repository.dart';
import 'in_memory_session_storage.dart';

/// Pumps the whole app with fakes for every external dependency.
/// By default the signed-in user already has a profile.
Future<void> pumpRisottoApp(
  WidgetTester tester, {
  FakeAuthRepository? auth,
  InMemorySessionStorage? storage,
  FakeProfileRepository? profiles,
  FakePhotoPicker? photoPicker,
  FakeContactsRepository? contacts,
  FakeCardSharer? cardSharer,
  List<String> scannerPayloads = const [],
  FakeQrScanner? scanner,
  FakeConnectionsRepository? connections,
  FakeMessagingRepository? messaging,
  FakeRealtimeClient? realtime,
  FakeNotificationsRepository? notifications,
  FakePushService? push,
  FakeDashboardRepository? dashboard,
  ResponseCache? responseCache,
  List<Override> extraOverrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth ?? FakeAuthRepository()),
        sessionStorageProvider.overrideWithValue(
          storage ?? InMemorySessionStorage(),
        ),
        profileRepositoryProvider.overrideWithValue(
          profiles ?? FakeProfileRepository(mine: testProfile()),
        ),
        photoPickerProvider.overrideWithValue(photoPicker ?? FakePhotoPicker()),
        contactsRepositoryProvider.overrideWithValue(
          contacts ?? FakeContactsRepository(),
        ),
        cardSharerProvider.overrideWithValue(cardSharer ?? FakeCardSharer()),
        qrScannerProvider.overrideWithValue(
          scanner ?? FakeQrScanner(scannerPayloads),
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
        dashboardRepositoryProvider.overrideWithValue(
          dashboard ?? FakeDashboardRepository(),
        ),
        responseCacheProvider.overrideWithValue(
          responseCache ?? MemoryResponseCache(),
        ),
        ...extraOverrides,
      ],
      child: const RisottoApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Brings [finder] on screen: lazily built lists are scrolled until it exists.
Future<void> revealFinder(WidgetTester tester, Finder finder) async {
  // A focused text field would scroll itself back into view and hide the target.
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump();
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

/// From the welcome screen (signed out) to the login form.
Future<void> openLogin(WidgetTester tester) =>
    tapText(tester, 'J’ai déjà un compte');

/// Opens a main tab from the bottom navigation bar.
Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

/// "Ma carte" (QR code), from the middle button of the bottom bar.
Future<void> openMyCard(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Ma carte'));
  await tester.pumpAndSettle();
}

/// Signs out from the Profil tab.
Future<void> signOut(WidgetTester tester) async {
  await openTab(tester, 'Profil');
  await tapText(tester, 'Se déconnecter');
}

/// Member search, from the Réseau tab.
Future<void> openSearch(WidgetTester tester) async {
  await openTab(tester, 'Réseau');
  await tester.tap(find.text('Rechercher par nom, métier ou entreprise'));
  await tester.pumpAndSettle();
}

/// "Mes contacts", from the Profil tab.
Future<void> openContacts(WidgetTester tester) async {
  await openTab(tester, 'Profil');
  await tapText(tester, 'Mes contacts');
}
