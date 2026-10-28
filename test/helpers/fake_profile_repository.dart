import 'dart:typed_data';

import 'package:risotto/core/network/api_exception.dart';
import 'package:risotto/features/profile/application/photo_picker.dart';
import 'package:risotto/features/profile/data/profile_models.dart';
import 'package:risotto/features/profile/data/profile_repository.dart';

Profile testProfile({
  String firstName = 'Alice',
  String lastName = 'Martin',
  String? headline = 'Cheffe de projet',
  String? photoUrl,
  ProfileVisibility visibility = ProfileVisibility.connections,
}) => Profile(
  userId: 'user-1',
  access: ProfileAccess.full,
  firstName: firstName,
  lastName: lastName,
  headline: headline,
  company: 'Risotto SAS',
  photoUrl: photoUrl,
  visibility: visibility,
  shareEmail: false,
  sharePhone: false,
  accountEmail: 'alice@example.com',
);

/// In-memory profile backend. [mine] null means "not created yet".
class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository({this.mine, Map<String, Profile>? others, this.lookup})
    : others = others ?? {};

  Profile? mine;
  final Map<String, Profile> others;

  /// Optional live source for other members (e.g. the connections fake).
  Profile? Function(String userId)? lookup;
  ApiException? failWith;
  ProfileInput? lastInput;
  final List<String> calls = [];

  // A 1x1 transparent PNG.
  static final pngBytes = Uint8List.fromList(const [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]);

  Future<T> _run<T>(String name, T Function() ok) {
    calls.add(name);
    final failure = failWith;
    return failure != null ? Future.error(failure) : Future.value(ok());
  }

  Profile _fromInput(ProfileInput input, {String? photoUrl}) => Profile(
    userId: 'user-1',
    access: ProfileAccess.full,
    firstName: input.firstName.trim(),
    lastName: input.lastName.trim(),
    headline: input.headline.trim().isEmpty ? null : input.headline.trim(),
    company: input.company.trim().isEmpty ? null : input.company.trim(),
    bio: input.bio.trim().isEmpty ? null : input.bio.trim(),
    photoUrl: photoUrl,
    visibility: input.visibility ?? ProfileVisibility.connections,
    shareEmail: input.shareEmail ?? false,
    sharePhone: input.sharePhone ?? false,
    accountEmail: 'alice@example.com',
  );

  @override
  Future<Profile?> getMine() => _run('getMine', () => mine);

  @override
  Future<Profile> create(ProfileInput input) => _run('create', () {
    lastInput = input;
    return mine = _fromInput(input);
  });

  @override
  Future<Profile> update(ProfileInput input) => _run('update', () {
    lastInput = input;
    return mine = _fromInput(input, photoUrl: mine?.photoUrl);
  });

  @override
  Future<Profile> uploadPhoto(Uint8List bytes, String filename) =>
      _run('uploadPhoto', () {
        final current = mine!;
        return mine = Profile(
          userId: current.userId,
          access: current.access,
          firstName: current.firstName,
          lastName: current.lastName,
          headline: current.headline,
          photoUrl: '/profiles/user-1/photo?v=${calls.length}',
          visibility: current.visibility,
          shareEmail: current.shareEmail,
          sharePhone: current.sharePhone,
          accountEmail: current.accountEmail,
        );
      });

  @override
  Future<void> deletePhoto() => _run('deletePhoto', () {
    final current = mine!;
    mine = Profile(
      userId: current.userId,
      access: current.access,
      firstName: current.firstName,
      lastName: current.lastName,
      headline: current.headline,
      visibility: current.visibility,
      shareEmail: current.shareEmail,
      sharePhone: current.sharePhone,
      accountEmail: current.accountEmail,
    );
  });

  @override
  Future<Profile> getById(String userId) => _run('getById', () {
    final profile = others[userId] ?? lookup?.call(userId);
    if (profile == null) {
      throw const ApiException(ApiErrorKind.invalidInput, statusCode: 404);
    }
    return profile;
  });

  @override
  Future<Uint8List> downloadPhoto(String photoUrl) =>
      _run('downloadPhoto', () => pngBytes);
}

class FakePhotoPicker implements PhotoPicker {
  PickedPhoto? next = PickedPhoto(FakeProfileRepository.pngBytes, 'me.png');
  PhotoSource? lastSource;

  @override
  Future<PickedPhoto?> pick(PhotoSource source) async {
    lastSource = source;
    return next;
  }
}
