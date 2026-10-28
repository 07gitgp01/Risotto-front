import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/app_routes.dart';
import '../application/contacts_providers.dart';
import '../data/contacts_models.dart';
import '../data/contacts_repository.dart';
import 'widgets/contact_card_view.dart';

/// Builds the camera view; calls [onPayload] for every decoded QR code.
/// Replaced by a fake in widget tests (no camera there).
typedef QrScannerBuilder =
    Widget Function(BuildContext context, ValueChanged<String> onPayload);

final qrScannerBuilderProvider = Provider<QrScannerBuilder>(
  (ref) =>
      (context, onPayload) => MobileScanner(
        controller: MobileScannerController(
          formats: const [BarcodeFormat.qrCode],
        ),
        onDetect: (capture) {
          final value = capture.barcodes.firstOrNull?.rawValue;
          if (value != null) {
            onPayload(value);
          }
        },
        errorBuilder: (context, error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              error.errorCode == MobileScannerErrorCode.permissionDenied
                  ? 'Autorisez l’accès à l’appareil photo dans les réglages pour scanner un QR code.'
                  : 'Caméra indisponible.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
);

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  // The camera reports the same code many times per second.
  bool _busy = false;
  bool _sheetOpen = false;
  String? _lastPayload;

  Future<void> _onPayload(String payload) async {
    if (_busy || _sheetOpen || payload == _lastPayload) {
      return;
    }
    _lastPayload = payload;
    final messenger = ScaffoldMessenger.of(context);
    if (!looksLikeRisottoQr(payload)) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Ce QR code n’est pas un QR code Risotto.'),
        ),
      );
      return;
    }

    setState(() => _busy = true);
    ScanResult? result;
    try {
      result = await ref.read(contactsRepositoryProvider).scan(payload);
    } on ApiException catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            error.statusCode == 404
                ? 'QR code inconnu ou expiré.'
                : error.message,
          ),
        ),
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

    _sheetOpen = true;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ScannedCardSheet(payload: payload, result: result!),
    );
    _sheetOpen = false;
    // Allows scanning the same code again after closing the sheet.
    _lastPayload = null;
  }

  @override
  Widget build(BuildContext context) {
    final scanner = ref.watch(qrScannerBuilderProvider);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Scanner un QR code')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          scanner(context, _onPayload),
          IgnorePointer(
            child: Center(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 4,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
          if (_busy) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

class _ScannedCardSheet extends ConsumerStatefulWidget {
  const _ScannedCardSheet({required this.payload, required this.result});

  final String payload;
  final ScanResult result;

  @override
  ConsumerState<_ScannedCardSheet> createState() => _ScannedCardSheetState();
}

class _ScannedCardSheetState extends ConsumerState<_ScannedCardSheet> {
  late bool _saved = widget.result.saved;
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(contactsRepositoryProvider)
          .scan(widget.payload, saveContact: true);
      ref.invalidate(savedContactsProvider);
      if (mounted) {
        setState(() => _saved = true);
      }
      messenger.showSnackBar(
        const SnackBar(content: Text('Contact enregistré.')),
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
    final result = widget.result;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ContactCardView(card: result.card),
            const SizedBox(height: 16),
            if (result.isSelf)
              const Text(
                'C’est votre propre QR code.',
                textAlign: TextAlign.center,
              )
            else if (_saved)
              OutlinedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('Voir dans mes contacts'),
                onPressed: () {
                  Navigator.pop(context);
                  context.push(AppRoutes.contacts);
                },
              )
            else
              FilledButton.icon(
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Enregistrer le contact'),
                onPressed: _saving ? null : _save,
              ),
          ],
        ),
      ),
    );
  }
}
