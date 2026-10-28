import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/risotto_colors.dart';
import '../application/contacts_providers.dart';
import 'widgets/contact_card_view.dart';

/// My personal QR code and the card people get when they scan it.
class MyCardScreen extends ConsumerWidget {
  const MyCardScreen({super.key});

  Future<void> _rotate(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Générer un nouveau QR code ?'),
        content: const Text(
          'L’ancien QR code ne fonctionnera plus. Les contacts qui ont déjà '
          'enregistré votre carte la conservent.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Générer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(myQrCodeProvider.notifier).rotate();
      messenger.showSnackBar(
        const SnackBar(content: Text('Nouveau QR code généré.')),
      );
    } on ApiException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qr = ref.watch(myQrCodeProvider);
    final card = ref.watch(myCardProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ma carte'),
        actions: [
          IconButton(
            tooltip: 'Générer un nouveau QR code',
            icon: const Icon(Icons.autorenew),
            onPressed: () => _rotate(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Faites scanner ce code pour partager votre carte ou recevoir une demande de mise en relation.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          Center(
            child: qr.when(
              loading: () => const SizedBox.square(
                dimension: 240,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Text(
                error is ApiException ? error.message : 'QR code indisponible.',
              ),
              data: (code) => Semantics(
                label: 'Votre QR code personnel',
                image: true,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    // White quiet zone: scanners need strong contrast.
                    color: RisottoColors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(
                    data: code.payload,
                    size: 240,
                    backgroundColor: RisottoColors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: RisottoColors.charcoal,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: RisottoColors.charcoal,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          card.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (card) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ContactCardView(card: card),
                const SizedBox(height: 16),
                Builder(
                  builder: (buttonContext) => OutlinedButton.icon(
                    icon: const Icon(Icons.ios_share),
                    label: const Text('Partager ma carte (vCard)'),
                    onPressed: () {
                      final box =
                          buttonContext.findRenderObject() as RenderBox?;
                      ref
                          .read(cardSharerProvider)
                          .share(
                            card,
                            origin: box == null
                                ? null
                                : box.localToGlobal(Offset.zero) & box.size,
                          );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Email et téléphone n’apparaissent que si vous les partagez (Mon profil > Modifier).',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
