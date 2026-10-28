import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../application/contacts_providers.dart';
import '../data/contacts_models.dart';
import 'widgets/contact_card_view.dart';

class ContactDetailScreen extends ConsumerWidget {
  const ContactDetailScreen({required this.contactId, super.key});

  final String contactId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contact = ref
        .watch(savedContactsProvider)
        .value
        ?.where((c) => c.card.userId == contactId)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact'),
        actions: [
          if (contact != null)
            IconButton(
              tooltip: 'Supprimer le contact',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, ref, contact),
            ),
        ],
      ),
      body: contact == null
          ? const Center(child: Text('Ce contact n’existe plus.'))
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                ContactCardView(card: contact.card),
                const SizedBox(height: 16),
                _NoteEditor(contact: contact),
                const SizedBox(height: 16),
                Builder(
                  builder: (buttonContext) => OutlinedButton.icon(
                    icon: const Icon(Icons.ios_share),
                    label: const Text('Exporter (vCard)'),
                    onPressed: () {
                      final box =
                          buttonContext.findRenderObject() as RenderBox?;
                      ref
                          .read(cardSharerProvider)
                          .share(
                            contact.card,
                            origin: box == null
                                ? null
                                : box.localToGlobal(Offset.zero) & box.size,
                          );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    SavedContact contact,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer ${contact.card.fullName} ?'),
        content: const Text(
          'La carte et votre note seront retirées de vos contacts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(savedContactsProvider.notifier).remove(contactId);
      if (context.mounted) {
        context.pop();
      }
      messenger.showSnackBar(
        const SnackBar(content: Text('Contact supprimé.')),
      );
    } on ApiException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

class _NoteEditor extends ConsumerStatefulWidget {
  const _NoteEditor({required this.contact});

  final SavedContact contact;

  @override
  ConsumerState<_NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends ConsumerState<_NoteEditor> {
  late final _note = TextEditingController(text: widget.contact.note);
  bool _saving = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_note.text.trim().length > 500) {
      return;
    }
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(savedContactsProvider.notifier)
          .updateNote(widget.contact.card.userId, _note.text);
      messenger.showSnackBar(
        const SnackBar(content: Text('Note enregistrée.')),
      );
    } on ApiException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _note,
          maxLines: 3,
          maxLength: 500,
          decoration: const InputDecoration(
            labelText: 'Note privée',
            hintText: 'Où vous êtes-vous rencontrés ?',
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('Enregistrer la note'),
          ),
        ),
      ],
    );
  }
}
