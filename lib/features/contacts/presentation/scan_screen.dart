import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/risotto_colors.dart';
import '../../../core/widgets/risotto_ui.dart';
import '../application/qr_scanner.dart';
import '../data/contacts_models.dart';
import '../data/contacts_repository.dart';
import 'scan_result_screen.dart';

/// Design: scanner_qr.
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  // The camera reports the same code many times per second.
  bool _busy = false;
  bool _resultOpen = false;
  bool _torchOn = false;
  String? _lastPayload;

  void _say(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _onPayload(String payload) async {
    if (_busy || _resultOpen || payload == _lastPayload) {
      return;
    }
    _lastPayload = payload;
    if (!looksLikeRisottoQr(payload)) {
      _say('Ce QR code n’est pas un QR code Risotto.');
      return;
    }

    setState(() => _busy = true);
    ScanResult? result;
    try {
      result = await ref.read(contactsRepositoryProvider).scan(payload);
    } on ApiException catch (error) {
      _say(
        error.statusCode == 404 ? 'QR code inconnu ou expiré.' : error.message,
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
    if (result == null || !mounted) {
      _lastPayload = null;
      return;
    }

    _resultOpen = true;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ScanResultScreen(payload: payload, result: result!),
      ),
    );
    _resultOpen = false;
    // Allows scanning the same code again after coming back.
    _lastPayload = null;
  }

  Future<void> _toggleTorch() async {
    try {
      await ref.read(qrScannerProvider).toggleTorch();
      setState(() => _torchOn = !_torchOn);
    } on Object {
      _say('Lampe indisponible sur cet appareil.');
    }
  }

  Future<void> _fromGallery() async {
    GalleryScan? scan;
    try {
      scan = await ref.read(qrScannerProvider).scanFromGallery();
    } on Object {
      _say('Impossible de lire cette image.');
      return;
    }
    if (scan == null || !mounted) {
      return;
    }
    final payload = scan.payload;
    if (payload == null) {
      _say('Aucun QR code trouvé dans cette image.');
      return;
    }
    // An image is a deliberate choice: always read it, even if seen before.
    _lastPayload = null;
    await _onPayload(payload);
  }

  @override
  Widget build(BuildContext context) {
    final scanner = ref.watch(qrScannerProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Scanner un QR code')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Row(
            children: [
              const IconTile(Icons.qr_code_scanner),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connexion instantanée',
                      style: theme.textTheme.titleMedium,
                    ),
                    const Text('Scannez la carte Risotto d’un membre'),
                  ],
                ),
              ),
              ActionChip(
                avatar: Icon(
                  _torchOn ? Icons.flashlight_off : Icons.flashlight_on,
                  size: 18,
                ),
                label: Text(_torchOn ? 'Éteindre' : 'Lampe'),
                onPressed: _toggleTorch,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              height: 340,
              child: ColoredBox(
                color: RisottoColors.charcoal,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    scanner.view(context, _onPayload),
                    const IgnorePointer(child: _Viewfinder()),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 16,
                      child: IgnorePointer(
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: RisottoColors.charcoal.withValues(
                                alpha: 0.75,
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 10,
                                  color: RisottoColors.basilSoft,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Caméra active',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_busy) const PageLoading(),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Placez le QR code dans le cadre',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          const Text(
            'Le scan est automatique. Vous pourrez ensuite vous connecter '
            'au membre ou enregistrer sa carte.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SurfaceCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _ToolTile(
                        icon: Icons.flashlight_on_outlined,
                        tone: PillTone.saffron,
                        title: 'Éclairage',
                        subtitle: _torchOn
                            ? 'Éteindre la lampe'
                            : 'Allumer la lampe',
                        onTap: _toggleTorch,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ToolTile(
                        icon: Icons.photo_library_outlined,
                        tone: PillTone.basil,
                        title: 'Galerie',
                        subtitle: 'Importer une image',
                        onTap: _fromGallery,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.qr_code_2),
                    label: const Text('Afficher mon code'),
                    onPressed: () => context.pushReplacement(AppRoutes.myCard),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const InfoPanel(
            icon: Icons.verified_user_outlined,
            text:
                'Seuls les QR codes Risotto sont reconnus, et chacun est '
                'vérifié par nos serveurs avant d’afficher une carte.',
          ),
        ],
      ),
    );
  }
}

/// Saffron corners around the scanning area.
class _Viewfinder extends StatelessWidget {
  const _Viewfinder();

  @override
  Widget build(BuildContext context) {
    const side = BorderSide(color: RisottoColors.saffron, width: 5);
    Widget corner(Alignment alignment, Border border) => Align(
      alignment: alignment,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(border: border),
      ),
    );
    return Center(
      child: SizedBox(
        width: 220,
        height: 220,
        child: Stack(
          children: [
            corner(Alignment.topLeft, const Border(top: side, left: side)),
            corner(Alignment.topRight, const Border(top: side, right: side)),
            corner(
              Alignment.bottomLeft,
              const Border(bottom: side, left: side),
            ),
            corner(
              Alignment.bottomRight,
              const Border(bottom: side, right: side),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    required this.icon,
    required this.tone,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final PillTone tone;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: RisottoColors.cream,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              IconTile(icon, tone: tone),
              const SizedBox(height: 8),
              Text(title, style: theme.textTheme.titleSmall),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
