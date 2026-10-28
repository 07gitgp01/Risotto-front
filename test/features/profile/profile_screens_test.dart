import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:risotto/core/router/app_routes.dart';
import 'package:risotto/core/network/api_exception.dart';
import 'package:risotto/features/profile/application/photo_picker.dart';
import 'package:risotto/features/profile/data/profile_models.dart';

import '../../helpers/fake_profile_repository.dart';
import '../../helpers/in_memory_session_storage.dart';
import '../../helpers/test_app.dart';

void main() {
  late FakeProfileRepository profiles;
  late FakePhotoPicker picker;

  setUp(() {
    profiles = FakeProfileRepository(mine: testProfile());
    picker = FakePhotoPicker();
  });

  Future<void> startSignedIn(WidgetTester tester) => pumpRisottoApp(
    tester,
    storage: InMemorySessionStorage(testSession()),
    profiles: profiles,
    photoPicker: picker,
  );

  Future<void> openMyProfile(WidgetTester tester) async {
    await startSignedIn(tester);
    await tester.tap(find.byTooltip('Mon profil'));
    await tester.pumpAndSettle();
  }

  group('setup', () {
    testWidgets('a user without profile is sent to the setup screen', (
      tester,
    ) async {
      profiles.mine = null;
      await startSignedIn(tester);
      expect(find.text('Votre profil'), findsOneWidget);
    });

    testWidgets('names are required', (tester) async {
      profiles.mine = null;
      await startSignedIn(tester);
      await tapText(tester, 'Créer mon profil');
      expect(find.text('Ce champ est obligatoire.'), findsNWidgets(2));
      expect(profiles.calls, isNot(contains('create')));
    });

    testWidgets('creating the profile opens home', (tester) async {
      profiles.mine = null;
      await startSignedIn(tester);
      await enterField(tester, 'Prénom', 'Alice');
      await enterField(tester, 'Nom', 'Martin');
      await enterField(tester, 'Titre (facultatif)', 'Cheffe de projet');
      await tapText(tester, 'Créer mon profil');

      expect(profiles.lastInput!.firstName, 'Alice');
      expect(find.text('Bienvenue, Alice'), findsOneWidget);
    });
  });

  group('my profile', () {
    testWidgets('shows the profile and its visibility', (tester) async {
      await openMyProfile(tester);
      expect(find.text('Alice Martin'), findsOneWidget);
      expect(find.text('Cheffe de projet'), findsOneWidget);
      expect(find.text('Visibilité : Relations'), findsOneWidget);
    });

    testWidgets('edits fields, visibility and sharing', (tester) async {
      await openMyProfile(tester);
      await tester.tap(find.byTooltip('Modifier le profil'));
      await tester.pumpAndSettle();

      await enterField(tester, 'Titre', 'CTO');
      await enterField(tester, 'Site web', 'https://alice.example.com');
      await tapText(tester, 'Public');
      await tapText(tester, 'Partager mon email');
      await tapText(tester, 'Enregistrer');

      final input = profiles.lastInput!;
      expect(input.headline, 'CTO');
      expect(input.website, 'https://alice.example.com');
      expect(input.visibility, ProfileVisibility.public);
      expect(input.shareEmail, isTrue);
      expect(find.text('Mon profil'), findsOneWidget);
      expect(find.text('Visibilité : Public'), findsOneWidget);
    });

    testWidgets('validates website and phone before saving', (tester) async {
      await openMyProfile(tester);
      await tester.tap(find.byTooltip('Modifier le profil'));
      await tester.pumpAndSettle();

      // Fields in screen order: the helper only scrolls downwards.
      await enterField(tester, 'Téléphone', 'appelle-moi');
      await enterField(tester, 'Site web', 'javascript:alert(1)');
      await tapText(tester, 'Enregistrer');

      expect(find.textContaining('Adresse web invalide'), findsOneWidget);
      expect(find.text('Numéro de téléphone invalide.'), findsOneWidget);
      expect(profiles.calls, isNot(contains('update')));
    });

    testWidgets('uploads a photo from the gallery', (tester) async {
      await openMyProfile(tester);
      await tester.tap(find.byTooltip('Changer la photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choisir dans la galerie'));
      await tester.pumpAndSettle();

      expect(picker.lastSource, PhotoSource.gallery);
      expect(profiles.calls, contains('uploadPhoto'));
      expect(find.text('Photo mise à jour.'), findsOneWidget);
      expect(profiles.calls, contains('downloadPhoto'));
    });

    testWidgets('a cancelled pick uploads nothing', (tester) async {
      picker.next = null;
      await openMyProfile(tester);
      await tester.tap(find.byTooltip('Changer la photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Prendre une photo'));
      await tester.pumpAndSettle();

      expect(picker.lastSource, PhotoSource.camera);
      expect(profiles.calls, isNot(contains('uploadPhoto')));
    });

    testWidgets('explains a rejected image format', (tester) async {
      await openMyProfile(tester);
      profiles.failWith = const ApiException(
        ApiErrorKind.invalidInput,
        statusCode: 400,
      );
      await tester.tap(find.byTooltip('Changer la photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choisir dans la galerie'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Format non pris en charge'), findsOneWidget);
    });

    testWidgets('removes the photo', (tester) async {
      profiles.mine = testProfile(photoUrl: '/profiles/user-1/photo?v=1');
      await openMyProfile(tester);
      await tester.tap(find.byTooltip('Changer la photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Supprimer la photo'));
      await tester.pumpAndSettle();

      expect(profiles.calls, contains('deletePhoto'));
      expect(profiles.mine!.photoUrl, isNull);
    });

    testWidgets('meets accessibility guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      await openMyProfile(tester);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  });

  group("someone else's profile", () {
    Future<void> openUser(WidgetTester tester, String userId) async {
      await startSignedIn(tester);
      unawaited(
        GoRouter.of(
          tester.element(find.byType(Scaffold).first),
        ).push(AppRoutes.userProfile(userId)),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a restricted profile explains what is hidden', (tester) async {
      profiles.others['bob'] = const Profile(
        userId: 'bob',
        access: ProfileAccess.preview,
        firstName: 'Bob',
        lastName: 'Durand',
        headline: 'Designer',
      );
      await openUser(tester, 'bob');

      expect(find.text('Bob Durand'), findsOneWidget);
      expect(find.text('Designer'), findsOneWidget);
      expect(find.textContaining('Ce profil est restreint'), findsOneWidget);
    });

    testWidgets('a full profile shows shared contact details', (tester) async {
      profiles.others['carol'] = const Profile(
        userId: 'carol',
        access: ProfileAccess.full,
        firstName: 'Carol',
        lastName: 'Petit',
        email: 'carol@example.com',
        jobTitle: 'CTO',
        company: 'Basilic',
      );
      await openUser(tester, 'carol');

      expect(find.text('carol@example.com'), findsOneWidget);
      expect(find.text('CTO · Basilic'), findsOneWidget);
      expect(find.textContaining('Ce profil est restreint'), findsNothing);
    });

    testWidgets('an unavailable profile shows a message', (tester) async {
      await openUser(tester, 'ghost');
      expect(find.text('Ce profil n’est pas disponible.'), findsOneWidget);
    });
  });
}
