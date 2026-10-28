import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../profile/presentation/widgets/profile_avatar.dart';
import '../application/contacts_providers.dart';

class ContactsScreen extends ConsumerWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contacts = ref.watch(savedContactsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mes contacts')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.scan),
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scanner'),
      ),
      body: contacts.when(
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
        data: (contacts) => contacts.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Aucun contact pour l’instant.\nScannez le QR code d’un membre pour enregistrer sa carte.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(savedContactsProvider.notifier).refresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: contacts.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    final card = contact.card;
                    return ListTile(
                      leading: ProfileAvatar(
                        initials: card.initials,
                        photoUrl: card.photoUrl,
                        name: card.fullName,
                        radius: 22,
                      ),
                      title: Text(card.fullName),
                      subtitle: Text(
                        contact.note ?? card.headline ?? card.position ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () =>
                          context.push(AppRoutes.contactDetail(card.userId)),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
