import 'package:flutter/material.dart';

import '../../data/profile_models.dart';
import 'profile_avatar.dart';

/// Read-only profile card shared by the own profile and other users' profiles.
class ProfileDetails extends StatelessWidget {
  const ProfileDetails({required this.profile, this.avatarAction, super.key});

  final Profile profile;

  /// Optional button overlaid on the avatar (e.g. change photo).
  final Widget? avatarAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = <(IconData, String, String?)>[
      (Icons.work_outline, 'Poste', profile.position),
      (Icons.place_outlined, 'Ville', profile.location),
      (Icons.mail_outline, 'Email', profile.email),
      (Icons.phone_outlined, 'Téléphone', profile.phone),
      (Icons.link, 'Site web', profile.website),
    ].where((row) => row.$3 != null).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ProfileAvatar(
                initials: profile.initials,
                photoUrl: profile.photoUrl,
                name: profile.fullName,
                radius: 56,
              ),
              if (avatarAction != null)
                Positioned(right: -8, bottom: -8, child: avatarAction!),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Semantics(
          header: true,
          child: Text(
            profile.fullName,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (profile.headline != null) ...[
          const SizedBox(height: 4),
          Text(
            profile.headline!,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
        ],
        if (profile.access != ProfileAccess.full) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.lock_outline, color: theme.colorScheme.secondary),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Ce profil est restreint : connectez-vous avec ce membre pour en voir davantage.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (profile.bio != null) ...[
          const SizedBox(height: 24),
          Text('À propos', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(profile.bio!, style: theme.textTheme.bodyLarge),
        ],
        if (rows.isNotEmpty) ...[
          const SizedBox(height: 16),
          for (final (icon, label, value) in rows)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(icon, color: theme.colorScheme.secondary),
              title: Text(value!),
              subtitle: Text(label),
            ),
        ],
      ],
    );
  }
}
