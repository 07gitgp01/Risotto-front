import 'package:flutter/material.dart';

import '../../../profile/presentation/widgets/profile_avatar.dart';
import '../../data/contacts_models.dart';

/// Visual business card: avatar, name, position and the shared contact details.
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ProfileAvatar(
                  initials: card.initials,
                  photoUrl: card.photoUrl,
                  name: card.fullName,
                  radius: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.fullName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (card.headline != null)
                        Text(card.headline!, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
            if (details.isNotEmpty) const SizedBox(height: 8),
            for (final (icon, label, value) in details)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(icon, color: theme.colorScheme.secondary),
                title: Text(value!),
                subtitle: Text(label),
              ),
          ],
        ),
      ),
    );
  }
}
