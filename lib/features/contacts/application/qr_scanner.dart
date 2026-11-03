import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Outcome of reading an image from the gallery.
class GalleryScan {
  const GalleryScan(this.payload);

  /// Null when the image holds no QR code.
  final String? payload;
}

/// Camera QR reader. Replaced by a fake in widget tests (no camera there).
abstract interface class QrScanner {
  /// Camera preview; calls [onPayload] for every decoded QR code.
  Widget view(BuildContext context, ValueChanged<String> onPayload);

  Future<void> toggleTorch();

  /// Lets the user pick an image, then reads it. Null if they cancel.
  Future<GalleryScan?> scanFromGallery();
}

class DeviceQrScanner implements QrScanner {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  final _picker = ImagePicker();

  @override
  Widget view(
    BuildContext context,
    ValueChanged<String> onPayload,
  ) => MobileScanner(
    controller: _controller,
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
  );

  @override
  Future<void> toggleTorch() => _controller.toggleTorch();

  @override
  Future<GalleryScan?> scanFromGallery() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) {
      return null;
    }
    final capture = await _controller.analyzeImage(
      file.path,
      formats: const [BarcodeFormat.qrCode],
    );
    return GalleryScan(capture?.barcodes.firstOrNull?.rawValue);
  }

  void dispose() => _controller.dispose();
}

/// One scanner per visit of the scan screen.
final qrScannerProvider = Provider.autoDispose<QrScanner>((ref) {
  final scanner = DeviceQrScanner();
  ref.onDispose(scanner.dispose);
  return scanner;
});
