import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/risotto_colors.dart';
import '../../../core/widgets/risotto_ui.dart';
import '../../connections/application/connections_providers.dart';
import '../../messaging/application/open_chat.dart';
import '../../profile/data/profile_models.dart';
import '../../profile/presentation/widgets/profile_avatar.dart';
import '../application/contacts_providers.dart';
import '../data/contacts_models.dart';
import '../data/contacts_repository.dart';

/// Design: r_sultat_du_scan. Mutual connections, sectors and the bio are not
/// shown: the scanned card does not carry them.
class ScanResultScreen extends ConsumerStatefulWidget {
  const ScanResultScreen({
    required this.payload,
    required this.result,
    super.key,
  });

  final String payload;
  final ScanResult result;

  @override
  ConsumerState<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends ConsumerState<ScanResultScreen> {
  final _note = TextEditingController();
  late bool _saved = widget.result.saved;
  late ConnectionStatus _connection = widget.result.connection.status;
  bool _saving = false;
  bool _connecting = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _say(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  /// Via the QR payload: works even if the profile is private.
  Future<void> _connect() async {
    setState(() => _connecting = true);
    try {
      final connection = await ref
          .read(connectionActionsProvider)
          .request(qrPayload: widget.payload);
      final accepted = connection.status == 'accepted';
      if (mounted) {
        setState(
          () => _connection = accepted
              ? ConnectionStatus.connected
              : ConnectionStatus.pendingOutgoing,
        );
        _say(
          accepted
              ? 'Vous êtes maintenant en relation.'
              : 'Demande de mise en relation envoyée.',
        );
      }
    } on ApiException catch (error) {
      _say(
        error.kind == ApiErrorKind.conflict
            ? 'Une demande existe déjà ou a été refusée récemment.'
            : error.message,
      );
    } finally {
      if (mounted) {
        setState(() => _connecting = false);
      }
    }
  }

  /// Saves the card, then the private meeting note if there is one.
  Future<void> _save() async {
    setState(() => _saving = true);
    final repository = ref.read(contactsRepositoryProvider);
    try {
      await repository.scan(widget.payload, saveContact: true);
      final note = _note.text.trim();
      if (note.isNotEmpty) {
        await repository.updateNote(widget.result.card.userId, note);
      }
      ref.invalidate(savedContactsProvider);
      if (mounted) {
        setState(() => _saved = true);
        _say('Contact enregistré.');
      }
    } on ApiException catch (error) {
      _say(error.message);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final card = result.card;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Résultat du scan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const Center(
            child: StatusPill(
              'QR code vérifié sur le réseau Risotto',
              icon: Icons.verified_outlined,
            ),
          ),
          const SizedBox(height: 16),
          SurfaceCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 8,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    gradient: LinearGradient(
                      colors: [RisottoColors.saffron, RisottoColors.basil],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ProfileAvatar(
                            initials: card.initials,
                            photoUrl: card.photoUrl,
                            name: card.fullName,
                            radius: 48,
                          ),
                          if (_connection == ConnectionStatus.connected)
                            Positioned(
                              right: -2,
                              bottom: -2,
                              child: Semantics(
                                label: 'En relation',
                                child: const CircleAvatar(
                                  radius: 14,
                                  backgroundColor: RisottoColors.basil,
                                  child: Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        card.fullName,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall,
                      ),
                      if (card.position != null)
                        Text(
                          card.position!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: RisottoColors.basil,
                          ),
                        ),
                      if (card.headline != null) ...[
                        const SizedBox(height: 4),
                        Text(card.headline!, textAlign: TextAlign.center),
                      ],
                      if (card.location != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.place_outlined, size: 18),
                            const SizedBox(width: 4),
                            Flexible(child: Text(card.location!)),
                          ],
                        ),
                      ],
                      for (final (icon, value) in [
                        (Icons.mail_outline, card.email),
                        (Icons.phone_outlined, card.phone),
                        (Icons.language, card.website),
                      ])
                        if (value != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Icon(icon, color: RisottoColors.basil),
                                const SizedBox(width: 12),
                                Expanded(child: Text(value)),
                              ],
                            ),
                          ),
                      if (!result.isSelf && !_saved) ...[
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Icon(Icons.edit_note),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Contexte de rencontre',
                                style: theme.textTheme.titleSmall,
                              ),
                            ),
                            Text('Privé', style: theme.textTheme.labelMedium),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _note,
                          maxLength: 500,
                          decoration: const InputDecoration(
                            hintText: 'Ex. : rencontré au salon de Lyon',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (result.isSelf)
            const Text(
              'C’est votre propre QR code.',
              textAlign: TextAlign.center,
            )
          else ...[
            switch (_connection) {
              ConnectionStatus.none => FilledButton.icon(
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Envoyer une demande'),
                onPressed: _connecting ? null : _connect,
              ),
              ConnectionStatus.pendingOutgoing => const InfoPanel(
                icon: Icons.hourglass_empty,
                text: 'Demande de mise en relation envoyée.',
              ),
              ConnectionStatus.pendingIncoming => FilledButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('Accepter sa demande'),
                onPressed: _connecting ? null : _connect,
              ),
              ConnectionStatus.connected => const InfoPanel(
                icon: Icons.handshake_outlined,
                text: 'Vous êtes en relation.',
              ),
            },
            const SizedBox(height: 12),
            if (_saved)
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  backgroundColor: RisottoColors.basilSoft,
                  foregroundColor: RisottoColors.basil,
                ),
                icon: const Icon(Icons.check),
                label: const Text('Voir dans mes contacts'),
                onPressed: () {
                  final router = GoRouter.of(context);
                  Navigator.of(context).pop();
                  router.push<void>(AppRoutes.contacts).ignore();
                },
              )
            else
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  backgroundColor: RisottoColors.basilSoft,
                  foregroundColor: RisottoColors.basil,
                ),
                icon: const Icon(Icons.contact_page_outlined),
                label: const Text('Enregistrer le contact'),
                onPressed: _saving ? null : _save,
              ),
            // Messaging is reserved to connections.
            if (_connection == ConnectionStatus.connected) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Écrire un message'),
                onPressed: () =>
                    openChatWith(context, ref, widget.result.card.userId),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
