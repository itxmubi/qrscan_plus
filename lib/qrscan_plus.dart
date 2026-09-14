import 'dart:async';

import 'package:flutter/services.dart';

/// camera access denied const.
// ignore: constant_identifier_names
const CameraAccessDenied = 'PERMISSION_NOT_GRANTED';

/// method channel.
const MethodChannel _channel = MethodChannel('qr_scan');

/// Scanning Bar Code or QR Code return content.
///
/// Returns `null` when the scanner is closed without reading a code.
Future<String?> scan() => _channel.invokeMethod<String>('scan');

/// Scanning Photo Bar Code or QR Code return content.
///
/// Returns `null` when the picker is cancelled or no code is found.
Future<String?> scanPhoto() => _channel.invokeMethod<String>('scan_photo');

/// Scanning the image of the specified path.
///
/// Returns `null` when no code is found.
Future<String?> scanPath(String path) {
  assert(path.isNotEmpty);
  return _channel.invokeMethod<String>('scan_path', {'path': path});
}

/// Parse to code string with uint8list.
///
/// Returns `null` when no code is found.
Future<String?> scanBytes(Uint8List uint8list) {
  assert(uint8list.isNotEmpty);
  return _channel.invokeMethod<String>('scan_bytes', {'bytes': uint8list});
}

/// Generating QR Code PNG bytes.
Future<Uint8List?> generateBarCode(String code) {
  assert(code.isNotEmpty);
  return _channel.invokeMethod<Uint8List>('generate_barcode', {'code': code});
}
