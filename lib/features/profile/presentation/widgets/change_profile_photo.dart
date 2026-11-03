import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../application/my_profile_controller.dart';
import '../../application/photo_picker.dart';
import '../../data/profile_models.dart';

enum _PhotoAction { camera, gallery, remove }

/// Camera, gallery or removal, then upload (Mon profil and Modifier mon profil).
Future<void> changeProfilePhoto(
  BuildContext context,
  WidgetRef ref,
  Profile profile,
) async {
  final action = await showModalBottomSheet<_PhotoAction>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Prendre une photo'),
            onTap: () => Navigator.pop(context, _PhotoAction.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choisir dans la galerie'),
            onTap: () => Navigator.pop(context, _PhotoAction.gallery),
          ),
          if (profile.photoUrl != null)
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Supprimer la photo'),
              onTap: () => Navigator.pop(context, _PhotoAction.remove),
            ),
        ],
      ),
    ),
  );
  if (action == null || !context.mounted) {
    return;
  }

  final messenger = ScaffoldMessenger.of(context);
  final controller = ref.read(myProfileProvider.notifier);
  try {
    if (action == _PhotoAction.remove) {
      await controller.removePhoto();
      messenger.showSnackBar(const SnackBar(content: Text('Photo supprimée.')));
      return;
    }
    final picked = await ref
        .read(photoPickerProvider)
        .pick(
          action == _PhotoAction.camera
              ? PhotoSource.camera
              : PhotoSource.gallery,
        );
    if (picked == null) {
      return;
    }
    await controller.setPhoto(picked.bytes, picked.filename);
    messenger.showSnackBar(const SnackBar(content: Text('Photo mise à jour.')));
  } on ApiException catch (error) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          error.kind == ApiErrorKind.invalidInput
              ? 'Format non pris en charge : choisissez une image JPEG, PNG ou WebP.'
              : error.statusCode == 413
              ? 'Image trop lourde (5 Mo maximum).'
              : error.message,
        ),
      ),
    );
  }
}
