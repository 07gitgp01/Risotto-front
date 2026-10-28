import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/app_routes.dart';
import '../application/my_profile_controller.dart';
import '../application/photo_picker.dart';
import '../data/profile_models.dart';
import 'widgets/profile_details.dart';

enum _PhotoAction { camera, gallery, remove }

class MyProfileScreen extends ConsumerWidget {
  const MyProfileScreen({super.key});

  Future<void> _changePhoto(
    BuildContext context,
    WidgetRef ref,
    Profile profile,
  ) async {
    final action = await showModalBottomSheet<_PhotoAction>(
      context: context,
      showDragHandle: true,
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
        messenger.showSnackBar(
          const SnackBar(content: Text('Photo supprimée.')),
        );
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
      messenger.showSnackBar(
        const SnackBar(content: Text('Photo mise à jour.')),
      );
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProfileProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil'),
        actions: [
          if (profile.value != null)
            IconButton(
              tooltip: 'Modifier le profil',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push(AppRoutes.editProfile),
            ),
        ],
      ),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  error is ApiException
                      ? error.message
                      : 'Impossible de charger le profil.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(myProfileProvider),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
        data: (profile) => profile == null
            ? const SizedBox.shrink()
            : ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  ProfileDetails(
                    profile: profile,
                    avatarAction: IconButton.filled(
                      tooltip: 'Changer la photo',
                      icon: const Icon(Icons.photo_camera_outlined),
                      onPressed: () => _changePhoto(context, ref, profile),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _VisibilitySummary(profile: profile),
                ],
              ),
      ),
    );
  }
}

class _VisibilitySummary extends StatelessWidget {
  const _VisibilitySummary({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final visibility = profile.visibility ?? ProfileVisibility.connections;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Visibilité : ${visibility.label}',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(visibility.description),
            const SizedBox(height: 8),
            Text(
              [
                profile.shareEmail == true
                    ? 'Email partagé'
                    : 'Email non partagé',
                profile.sharePhone == true
                    ? 'téléphone partagé'
                    : 'téléphone non partagé',
              ].join(' · '),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
