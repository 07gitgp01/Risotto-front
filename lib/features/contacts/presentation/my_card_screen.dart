import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/risotto_colors.dart';
import '../../../core/widgets/risotto_ui.dart';
import '../application/contacts_providers.dart';

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
    final card = ref.watch(myCardProvider).value;
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const Center(
            child: StatusPill(
              'Carte active · Prête à scanner',
              icon: Icons.circle,
            ),
          ),
          const SizedBox(height: 16),
          SurfaceCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                qr.when(
                  loading: () => const SizedBox.square(
                    dimension: 240,
                    child: PageLoading(),
                  ),
                  error: (error, _) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      error is ApiException
                          ? error.message
                          : 'QR code indisponible.',
                      textAlign: TextAlign.center,
                    ),
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
                        border: Border.all(color: RisottoColors.outline),
                      ),
                      child: QrImageView(
                        data: code.payload,
                        size: 240,
                        backgroundColor: RisottoColors.white,
                        // High correction: the logo in the middle stays readable.
                        errorCorrectionLevel: QrErrorCorrectLevel.H,
                        embeddedImage: const AssetImage(
                          'assets/brand/png/logo-mark-512.png',
                        ),
                        embeddedImageStyle: const QrEmbeddedImageStyle(
                          size: Size(48, 48),
                        ),
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
                if (card != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    card.fullName,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                  if (card.headline != null)
                    Text(
                      card.headline!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: RisottoColors.basil,
                      ),
                    ),
                  if (card.company != null || card.location != null)
                    Text(
                      [
                        card.company,
                        card.location,
                      ].whereType<String>().join(' • '),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  if (card.email != null)
                    Text(
                      card.email!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (card != null)
            Builder(
              builder: (buttonContext) => FilledButton.icon(
                icon: const Icon(Icons.share_outlined),
                label: const Text('Partager ma carte (vCard)'),
                onPressed: () {
                  final box = buttonContext.findRenderObject() as RenderBox?;
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
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: RisottoColors.basil,
              foregroundColor: RisottoColors.white,
            ),
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scanner un code'),
            onPressed: () => context.push(AppRoutes.scan),
          ),
          const SizedBox(height: 16),
          const InfoPanel(
            icon: Icons.info_outline,
            text:
                'Présentez ce code lors de vos événements et rendez-vous : un scan suffit '
                'pour partager votre carte. Email et téléphone n’y figurent que si vous les '
                'partagez (Profil > Modifier).',
          ),
        ],
      ),
    );
  }
}
