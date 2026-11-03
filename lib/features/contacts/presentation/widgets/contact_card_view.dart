import 'package:flutter/material.dart';

import '../../../../core/theme/risotto_colors.dart';
import '../../../../core/widgets/risotto_ui.dart';
import '../../../profile/presentation/widgets/profile_avatar.dart';
import '../../data/contacts_models.dart';

/// Visual business card: avatar, name, position and the shared contact details
/// (same look as the scan result card).
class ContactCardView extends StatelessWidget {
  const ContactCardView({required this.card, super.key});

  final ContactCard card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = <(IconData, String, String?)>[
      (Icons.work_outline, 'Poste', card.position),
      (Icons.place_outlined, 'Ville', card.location),
      (Icons.mail_outline, 'Email', card.email),
      (Icons.phone_outlined, 'Téléphone', card.phone),
      (Icons.link, 'Site web', card.website),
    ].where((row) => row.$3 != null).toList();

    return SurfaceCard(
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
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              children: [
                ProfileAvatar(
                  initials: card.initials,
                  photoUrl: card.photoUrl,
                  name: card.fullName,
                  radius: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  card.fullName,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                if (card.headline != null)
                  Text(
                    card.headline!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: RisottoColors.basil,
                    ),
                  ),
              ],
            ),
          ),
          for (final (icon, label, value) in details)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              leading: IconTile(icon, tone: PillTone.basil, size: 40),
              title: Text(value!),
              subtitle: Text(label),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
