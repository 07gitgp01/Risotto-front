import 'package:flutter/material.dart';

import '../../../../core/theme/risotto_colors.dart';
import '../../../../core/widgets/risotto_ui.dart';
import '../../data/profile_models.dart';
import 'profile_avatar.dart';

/// Another member's profile as cards: identity, about, contact details
/// (same look as Mon profil and the scanned card).
class ProfileDetails extends StatelessWidget {
  const ProfileDetails({required this.profile, super.key});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = <(IconData, String, String?)>[
      (Icons.work_outline, 'Poste', profile.position),
      (Icons.mail_outline, 'Email', profile.email),
      (Icons.phone_outlined, 'Téléphone', profile.phone),
      (Icons.link, 'Site web', profile.website),
    ].where((row) => row.$3 != null).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SurfaceCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 8,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  gradient: LinearGradient(
                    colors: [RisottoColors.saffron, RisottoColors.basil],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    ProfileAvatar(
                      initials: profile.initials,
                      photoUrl: profile.photoUrl,
                      name: profile.fullName,
                      radius: 52,
                    ),
                    const SizedBox(height: 12),
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
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: RisottoColors.basil,
                        ),
                      ),
                    if (profile.location != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.place_outlined, size: 18),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              profile.location!,
                              style: theme.textTheme.labelMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (profile.access != ProfileAccess.full) ...[
          const SizedBox(height: 16),
          const InfoPanel(
            icon: Icons.lock_outline,
            text:
                'Ce profil est restreint : connectez-vous avec ce membre pour en voir davantage.',
          ),
        ],
        if (profile.bio != null) ...[
          const SizedBox(height: 16),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('À propos', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(profile.bio!, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ],
        if (rows.isNotEmpty) ...[
          const SizedBox(height: 16),
          SurfaceCard(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Text(
                    'Coordonnées',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                for (final (icon, label, value) in rows)
                  ListTile(
                    leading: IconTile(icon, tone: PillTone.basil, size: 40),
                    title: Text(value!),
                    subtitle: Text(label),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
