import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/risotto_colors.dart';
import '../../../profile/data/profile_models.dart';
import '../../application/connections_providers.dart';

/// The connection action matching the current state with a member:
/// connect, cancel the request, accept/decline, or remove the connection.
class ConnectionButton extends ConsumerStatefulWidget {
  const ConnectionButton({
    required this.userId,
    required this.name,
    required this.state,
    this.compact = false,
    super.key,
  });

  final String userId;
  final String name;
  final MemberConnection state;

  /// Single small button (lists) instead of full-width buttons (profile).
  final bool compact;

  @override
  ConsumerState<ConnectionButton> createState() => _ConnectionButtonState();
}

class _ConnectionButtonState extends ConsumerState<ConnectionButton> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, String done) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } on ApiException catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            error.kind == ApiErrorKind.conflict
                ? 'Action impossible pour le moment (demande déjà envoyée ou refusée récemment).'
                : error.message,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<bool> _confirm(String title, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final actions = ref.read(connectionActionsProvider);
    final id = widget.state.connectionId;
    final onBusy = _busy ? null : () {};

    Widget primary(String label, IconData icon, VoidCallback onPressed) =>
        widget.compact
        ? FilledButton.tonalIcon(
            onPressed: onBusy == null ? null : onPressed,
            icon: Icon(icon),
            label: Text(label),
          )
        : FilledButton.icon(
            onPressed: onBusy == null ? null : onPressed,
            icon: Icon(icon),
            label: Text(label),
          );

    Widget secondary(String label, IconData icon, VoidCallback onPressed) =>
        OutlinedButton.icon(
          onPressed: onBusy == null ? null : onPressed,
          icon: Icon(icon),
          label: Text(label),
        );

    switch (widget.state.status) {
      case ConnectionStatus.none:
        return primary(
          'Se connecter',
          Icons.person_add_alt_1,
          () => _run(
            () => actions.request(userId: widget.userId),
            'Demande envoyée à ${widget.name}.',
          ),
        );
      case ConnectionStatus.pendingOutgoing:
        return secondary(
          'Annuler la demande',
          Icons.hourglass_top,
          () => _run(
            () => actions.remove(id!, widget.userId),
            'Demande annulée.',
          ),
        );
      case ConnectionStatus.pendingIncoming:
        // Design: "Refuser" neutral, "Accepter" basil, side by side.
        final decline = FilledButton(
          onPressed: onBusy == null
              ? null
              : () => _run(
                  () => actions.decline(id!, widget.userId),
                  'Demande refusée.',
                ),
          style: FilledButton.styleFrom(
            backgroundColor: RisottoColors.creamDark,
            foregroundColor: RisottoColors.charcoal,
          ),
          child: const Text('Refuser'),
        );
        final accept = FilledButton.icon(
          onPressed: onBusy == null
              ? null
              : () => _run(
                  () => actions.accept(id!, widget.userId),
                  'Vous êtes maintenant en relation avec ${widget.name}.',
                ),
          style: FilledButton.styleFrom(
            backgroundColor: RisottoColors.basil,
            foregroundColor: RisottoColors.white,
          ),
          icon: const Icon(Icons.check),
          label: const Text('Accepter'),
        );
        return Row(
          children: [
            Expanded(child: decline),
            const SizedBox(width: 12),
            Expanded(child: accept),
          ],
        );
      case ConnectionStatus.connected:
        return secondary('En relation', Icons.how_to_reg, () async {
          if (await _confirm(
            'Retirer ${widget.name} de vos relations ?',
            'Retirer',
          )) {
            await _run(
              () => actions.remove(id!, widget.userId),
              'Relation retirée.',
            );
          }
        });
    }
  }
}
