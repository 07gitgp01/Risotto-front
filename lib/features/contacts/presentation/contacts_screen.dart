import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/risotto_colors.dart';
import '../../../core/widgets/risotto_ui.dart';
import '../../profile/presentation/widgets/profile_avatar.dart';
import '../application/contacts_providers.dart';
import '../data/contacts_models.dart';

/// Cards saved by scanning, with a local search (same style as Réseau).
class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  String _query = '';

  bool _matches(SavedContact contact) {
    if (_query.isEmpty) {
      return true;
    }
    final card = contact.card;
    return [
      card.fullName,
      card.position ?? '',
      card.company ?? '',
      contact.note ?? '',
    ].join(' ').toLowerCase().contains(_query.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final contacts = ref.watch(savedContactsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mes contacts')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: RisottoColors.saffron,
        foregroundColor: RisottoColors.charcoal,
        onPressed: () => context.push(AppRoutes.scan),
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scanner'),
      ),
      body: contacts.when(
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
                      : 'Impossible de charger les contacts.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(savedContactsProvider),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
        data: (contacts) {
          final shown = contacts.where(_matches).toList();
          return RefreshIndicator(
            onRefresh: () => ref.read(savedContactsProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                if (contacts.isEmpty)
                  const InfoPanel(
                    icon: Icons.qr_code_scanner,
                    text:
                        'Aucun contact pour l’instant.\nScannez le QR code d’un membre pour enregistrer sa carte.',
                  )
                else ...[
                  TextField(
                    onChanged: (value) => setState(() => _query = value.trim()),
                    decoration: const InputDecoration(
                      hintText: 'Rechercher un contact',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  SectionHeader(
                    title: contacts.length == 1
                        ? '1 carte enregistrée'
                        : '${contacts.length} cartes enregistrées',
                  ),
                  if (shown.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'Aucun contact ne correspond.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  for (final contact in shown) ...[
                    _ContactCard(contact: contact),
                    const SizedBox(height: 12),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.contact});

  final SavedContact contact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final card = contact.card;
    final role = card.position ?? card.headline;
    return SurfaceCard(
      onTap: () => context.push(AppRoutes.contactDetail(card.userId)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileAvatar(
            initials: card.initials,
            photoUrl: card.photoUrl,
            name: card.fullName,
            radius: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(card.fullName, style: theme.textTheme.titleMedium),
                if (role != null)
                  Text(
                    role,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: RisottoColors.basil,
                    ),
                  ),
                if (contact.note != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.edit_note, size: 18),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          contact.note!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
