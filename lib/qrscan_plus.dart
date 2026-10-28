import 'dart:async';

import 'package:flutter/services.dart';

/// Error code reported when camera access is denied on either platform.
const cameraAccessDenied = 'PERMISSION_DENIED';

/// Use [cameraAccessDenied] instead.
@Deprecated('Use cameraAccessDenied instead.')
// ignore: constant_identifier_names
const CameraAccessDenied = cameraAccessDenied;

// Native method channel.
const MethodChannel _channel = MethodChannel('qr_scan');

/// Opens the camera scanner and returns the first decoded payload.
///
/// Returns `null` when the scanner is closed without reading a code.
Future<String?> scan() => _channel.invokeMethod<String>('scan');

/// Opens the native photo picker and decodes the selected image.
///
/// Returns `null` when the picker is cancelled or no code is found.
Future<String?> scanPhoto() => _channel.invokeMethod<String>('scan_photo');

/// Decodes an image at an absolute file path or a `file://` URL.
///
/// Returns `null` when no code is found.
/// Throws [PlatformException] with `INVALID_ARGUMENT` for empty input.
Future<String?> scanPath(String path) async {
  if (path.trim().isEmpty) {
    throw PlatformException(
      code: 'INVALID_ARGUMENT',
      message: 'Image path must not be empty.',
    );
  }
  return _channel.invokeMethod<String>('scan_path', {'path': path});
}

/// Decodes a barcode or QR code from encoded image bytes.
///
/// Returns `null` when no code is found.
/// Throws [PlatformException] with `INVALID_ARGUMENT` for empty input.
Future<String?> scanBytes(Uint8List uint8list) async {
  if (uint8list.isEmpty) {
    throw PlatformException(
      code: 'INVALID_ARGUMENT',
      message: 'Image bytes must not be empty.',
    );
  }
  return _channel.invokeMethod<String>('scan_bytes', {'bytes': uint8list});
}

/// Generates a QR code as PNG bytes using error correction level M.
Future<Uint8List?> generateBarCode(String code) async {
  if (code.isEmpty) {
    throw PlatformException(
      code: 'INVALID_ARGUMENT',
      message: 'Code must not be empty.',
    );
  }
  return _channel.invokeMethod<Uint8List>('generate_barcode', {'code': code});
}
