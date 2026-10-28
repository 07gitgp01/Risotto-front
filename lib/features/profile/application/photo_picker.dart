import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

enum PhotoSource { camera, gallery }

class PickedPhoto {
  const PickedPhoto(this.bytes, this.filename);

  final Uint8List bytes;
  final String filename;
}

/// Picks a photo from the camera or the gallery. Null if the user cancels.
abstract interface class PhotoPicker {
  Future<PickedPhoto?> pick(PhotoSource source);
}

class DevicePhotoPicker implements PhotoPicker {
  final _picker = ImagePicker();

  @override
  Future<PickedPhoto?> pick(PhotoSource source) async {
    final file = await _picker.pickImage(
      source: source == PhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      // The server resizes to 512 px; this keeps uploads small.
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.front,
    );
    if (file == null) {
      return null;
    }
    return PickedPhoto(await file.readAsBytes(), file.name);
  }
}

final photoPickerProvider = Provider<PhotoPicker>((ref) => DevicePhotoPicker());
