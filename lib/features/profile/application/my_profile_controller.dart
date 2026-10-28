import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/profile_models.dart';
import '../data/profile_repository.dart';

/// The signed-in user's profile. `null` means it still has to be created.
class MyProfileController extends AsyncNotifier<Profile?> {
  ProfileRepository get _repository => ref.read(profileRepositoryProvider);

  @override
  Future<Profile?> build() async {
    // Reloads on sign-in / sign-out.
    final auth = ref.watch(authControllerProvider);
    if (auth is! Authenticated) {
      return null;
    }
    return _repository.getMine();
  }

  Future<void> create(ProfileInput input) async {
    state = AsyncData(await _repository.create(input));
  }

  Future<void> save(ProfileInput input) async {
    state = AsyncData(await _repository.update(input));
  }

  Future<void> setPhoto(Uint8List bytes, String filename) async {
    state = AsyncData(await _repository.uploadPhoto(bytes, filename));
  }

  Future<void> removePhoto() async {
    await _repository.deletePhoto();
    state = AsyncData(await _repository.getMine());
  }
}

final myProfileProvider = AsyncNotifierProvider<MyProfileController, Profile?>(
  MyProfileController.new,
);

/// Someone else's profile, as visible to the current user.
final profileByIdProvider = FutureProvider.autoDispose.family<Profile, String>(
  (ref, userId) => ref.watch(profileRepositoryProvider).getById(userId),
);

/// Photo bytes, fetched through the authenticated client (keyed by URL, which
/// changes on every upload).
final profilePhotoProvider = FutureProvider.family<Uint8List, String>(
  (ref, photoUrl) =>
      ref.watch(profileRepositoryProvider).downloadPhoto(photoUrl),
);
