import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/risotto_colors.dart';
import '../../../core/widgets/risotto_ui.dart';
import '../../auth/application/auth_controller.dart';
import '../../contacts/application/contacts_providers.dart';
import '../../dashboard/application/dashboard_provider.dart';
import '../../shell/main_app_bar.dart';
import '../application/my_profile_controller.dart';
import '../application/photo_picker.dart';
import '../data/profile_models.dart';
import 'widgets/profile_avatar.dart';

enum _PhotoAction { camera, gallery, remove }

/// Profil tab (design: mon_profil): identity, my card, visibility, figures, links.
class MyProfileScreen extends ConsumerWidget {
  const MyProfileScreen({super.key});

  Future<void> _changePhoto(
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

  Future<void> _changeVisibility(
    BuildContext context,
    WidgetRef ref,
    Profile profile,
    ProfileVisibility visibility,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(myProfileProvider.notifier)
          .save(ProfileInput.fromProfile(profile, visibility: visibility));
      messenger.showSnackBar(
        SnackBar(content: Text('Visibilité : ${visibility.label}.')),
      );
    } on ApiException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProfileProvider);
    final summary = ref.watch(dashboardProvider).value;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const MainAppBar(title: 'Mon profil'),
      body: profile.when(
        loading: () => const PageLoading(),
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: [
                  _Header(
                    profile: profile,
                    onChangePhoto: () => _changePhoto(context, ref, profile),
                  ),
                  const SizedBox(height: 12),
                  SurfaceCard(
                    onTap: () => context.push(AppRoutes.myCard),
                    child: const Row(
                      children: [
                        IconTile(Icons.qr_code_2),
                        SizedBox(width: 12),
                        Expanded(child: _CardSummary()),
                        Icon(Icons.arrow_forward),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _VisibilityCard(
                    profile: profile,
                    onChanged: (visibility) =>
                        _changeVisibility(context, ref, profile, visibility),
                  ),
                  if (summary != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _Figure(
                            icon: Icons.group_outlined,
                            value: summary.connectionsCount,
                            label: 'Relations',
                            onTap: () => context.go(AppRoutes.network),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Figure(
                            icon: Icons.contacts_outlined,
                            value: summary.contactsCount,
                            label: 'Contacts',
                            onTap: () => context.push(AppRoutes.contacts),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (profile.bio != null) ...[
                    const SizedBox(height: 12),
                    SurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('À propos', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text(profile.bio!, style: theme.textTheme.bodyLarge),
                        ],
                      ),
                    ),
                  ],
                  _LinksCard(profile: profile),
                  const SizedBox(height: 12),
                  const _ActionsRow(),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text('Se déconnecter'),
                    onPressed: () =>
                        ref.read(authControllerProvider.notifier).logout(),
                  ),
                ],
              ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.profile, required this.onChangePhoto});

  final Profile profile;
  final VoidCallback onChangePhoto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              ProfileAvatar(
                initials: profile.initials,
                photoUrl: profile.photoUrl,
                name: profile.fullName,
                radius: 56,
              ),
              Positioned(
                right: -8,
                bottom: -8,
                child: IconButton.filled(
                  tooltip: 'Changer la photo',
                  style: IconButton.styleFrom(
                    backgroundColor: RisottoColors.basil,
                    foregroundColor: RisottoColors.white,
                  ),
                  icon: const Icon(Icons.photo_camera_outlined),
                  onPressed: onChangePhoto,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: Text(
              profile.fullName,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
          ),
          if (profile.headline != null)
            Text(
              profile.headline!,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                color: RisottoColors.basil,
              ),
            ),
          if (profile.position != null)
            Text(
              profile.position!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          if (profile.location != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.place_outlined, size: 18),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    profile.location!,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Modifier mon profil'),
              onPressed: () => context.push(AppRoutes.editProfile),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardSummary extends StatelessWidget {
  const _CardSummary();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                'Ma carte Risotto',
                style: theme.textTheme.titleSmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            const StatusPill('Active'),
          ],
        ),
        Text(
          'Partagez vos coordonnées en un scan',
          style: theme.textTheme.bodySmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _VisibilityCard extends StatelessWidget {
  const _VisibilityCard({required this.profile, required this.onChanged});

  final Profile profile;
  final ValueChanged<ProfileVisibility> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibility = profile.visibility ?? ProfileVisibility.connections;
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.visibility_outlined, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Visibilité : ${visibility.label}',
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedButton<ProfileVisibility>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: ProfileVisibility.public,
                icon: Icon(Icons.public, size: 18),
                label: Text('Public'),
              ),
              ButtonSegment(
                value: ProfileVisibility.connections,
                icon: Icon(Icons.group_outlined, size: 18),
                label: Text('Réseau'),
              ),
              ButtonSegment(
                value: ProfileVisibility.private,
                icon: Icon(Icons.lock_outline, size: 18),
                label: Text('Privé'),
              ),
            ],
            selected: {visibility},
            onSelectionChanged: (selection) => onChanged(selection.first),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: RisottoColors.basilSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              visibility.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: RisottoColors.charcoal,
              ),
            ),
          ),
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
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.icon,
    required this.value,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final int value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: '$value $label',
      excludeSemantics: true,
      child: SurfaceCard(
        onTap: onTap,
        child: Column(
          children: [
            IconTile(icon, tone: PillTone.basil, size: 40),
            const SizedBox(height: 8),
            Text('$value', style: theme.textTheme.headlineSmall),
            Text(label, style: theme.textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}

class _LinksCard extends StatelessWidget {
  const _LinksCard({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final rows = <(IconData, String, String?)>[
      (Icons.mail_outline, 'Email', profile.accountEmail),
      (Icons.phone_outlined, 'Téléphone', profile.phone),
      (Icons.link, 'Site web', profile.website),
    ].where((row) => row.$3 != null).toList();
    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SurfaceCard(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Coordonnées', style: Theme.of(context).textTheme.titleMedium),
            for (final (icon, label, value) in rows)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(icon, color: RisottoColors.basil),
                title: Text(value!),
                subtitle: Text(label),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionsRow extends ConsumerWidget {
  const _ActionsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = ref.watch(myCardProvider).value;
    Widget action(IconData icon, String label, VoidCallback? onTap) => Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: RisottoColors.basil),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),
      ),
    );
    return SurfaceCard(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          action(
            Icons.share_outlined,
            'Partager',
            card == null
                ? null
                : () => ref.read(cardSharerProvider).share(card),
          ),
          action(
            Icons.contacts_outlined,
            'Mes contacts',
            () => context.push(AppRoutes.contacts),
          ),
          action(
            Icons.tune,
            'Notifications',
            () => context.push(AppRoutes.notificationSettings),
          ),
        ],
      ),
    );
  }
}
