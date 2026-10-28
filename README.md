# qrscan_plus

<p align="center">
  <a href="https://pub.dev/packages/qrscan_plus">
    <img src="https://img.shields.io/pub/v/qrscan_plus.svg" alt="pub version" />
  </a>
  <a href="https://pub.dev/packages/qrscan_plus/score">
    <img src="https://img.shields.io/pub/likes/qrscan_plus" alt="pub likes" />
  </a>
  <a href="https://pub.dev/packages/qrscan_plus/score">
    <img src="https://img.shields.io/pub/points/qrscan_plus" alt="pub points" />
  </a>
  <a href="https://pub.dev/packages/qrscan_plus/score">
    <img src="https://img.shields.io/pub/popularity/qrscan_plus" alt="popularity" />
  </a>
  <a href="https://github.com/itxmubi/qrscan_plus/actions">
    <img src="https://github.com/itxmubi/qrscan_plus/actions/workflows/ci.yml/badge.svg" alt="CI status" />
  </a>
  <a href="https://github.com/itxmubi/qrscan_plus/blob/master/LICENSE">
    <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT license" />
  </a>
</p>

<p align="center">
  A lightweight Flutter plugin for scanning QR codes & barcodes via camera or gallery,<br/>
  and generating QR code images — with full Android & iOS support. No JitPack required.
</p>

---

## ✨ Features

- 📷 **Camera scan** — launch the device camera to scan any QR code or barcode in real time
- 🖼 **Gallery scan** — pick an image with the system photo picker and decode it (no storage permissions)
- 📁 **Path scan** — decode a barcode from a local file path
- 🔢 **Bytes scan** — decode a barcode directly from raw `Uint8List` bytes
- 🏗 **QR code generator** — generate a QR code image from any string
- ✅ **No JitPack** — Android dependencies are on Maven Central; no extra Gradle config needed
- 🍎 **iOS 13+** with native AVFoundation & Vision — Swift Package Manager and CocoaPods supported

---

## 📋 Requirements

| | Minimum | Notes |
|---|---|---|
| Flutter | 3.38 (Dart 3.10) | Tested on Flutter 3.41 and 3.47 |
| Android | API 24 (Android 7.0) | Compiled against API 36 (Android 16); Java 17 |
| iOS | 13.0 | Tested with Xcode 26 / iOS 26 SDK |

---

## 📱 Platform Support

| Method | Android | iOS | Description |
|---|---|---|---|
| `scan()` | ✅ | ✅ | Scan via live camera |
| `scanPhoto()` | ✅ | ✅ | Scan from gallery image |
| `scanPath(path)` | ✅ | ✅ | Scan from a file path |
| `scanBytes(bytes)` | ✅ | ✅ | Scan from raw byte data |
| `generateBarCode(text)` | ✅ | ✅ | Generate a QR code image |

> **Note:** `generateBarCode` returns PNG bytes on both platforms, with QR error correction level M.

Live camera scanning on iOS supports QR, EAN-8, EAN-13 (including UPC-A), UPC-E,
Code 39, Code 39 Mod 43, Code 93, Code 128, PDF417, Aztec, Data Matrix,
Interleaved 2 of 5, and ITF-14, where available on the device. Android uses ZXing's
supported formats. Camera and image decoding format availability can differ by
platform; not every barcode format is supported on both.

Android image decoding and QR generation run on a background worker. Image file
paths may be absolute paths or `file://` URLs; `content://` URIs are not accepted
by `scanPath()`. Use `scanPhoto()` for native gallery selection.

---

## 🚀 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  qrscan_plus: ^2.0.0
```

Then run:

```bash
flutter pub get
```

---

## 🤖 Android Setup

No additional Gradle repository setup is needed. All dependencies are on Maven Central.

Make sure your app's `minSdk` is at least **24** (the Flutter default).

### Permissions

The plugin's manifest already declares the camera permission. The camera permission is requested at runtime when `scan()` opens the scanner.

> `scanPhoto()` uses the system photo picker on Android 13+ (and the gallery picker on older versions) — no storage or media permissions are required for this plugin. If your app directly accesses files or media, handle runtime permissions based on your Android version separately.

---

## 🍎 iOS Setup

Minimum deployment target: **iOS 13.0**

Add the following key to your `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to scan QR codes and barcodes.</string>
```

> `scanPhoto()` uses the system photo picker, which runs outside your app, so `NSPhotoLibraryUsageDescription` is **not** required.

---

## 📖 Usage

### Import

```dart
import 'package:qrscan_plus/qrscan_plus.dart' as scanner;
```

### Scan via Camera

```dart
final String? result = await scanner.scan();
if (result != null) {
  print('Scanned: $result');
}
```

### Scan from Gallery

```dart
final String? result = await scanner.scanPhoto();
if (result != null) {
  print('From gallery: $result');
}
```

### Scan from File Path

```dart
final String? result = await scanner.scanPath('/storage/emulated/0/Download/qr.png');
if (result != null) {
  print('From path: $result');
}
```

### Scan from Bytes

```dart
// e.g. bytes from image_picker or a network image
final Uint8List bytes = ...;
final String? result = await scanner.scanBytes(bytes);
if (result != null) {
  print('From bytes: $result');
}
```

### Generate a QR Code Image

```dart
final Uint8List? qrImage = await scanner.generateBarCode('https://github.com/itxmubi/qrscan_plus');

// Display it in your app:
if (qrImage != null) {
  Image.memory(qrImage);
}
```

---

## 🛡 Error Handling

The scan methods return `null` when the user cancels or no code is found. Wrap calls in a try-catch to handle permission and image errors gracefully:

```dart
import 'package:flutter/services.dart';

try {
  final String? result = await scanner.scan();
  if (result != null) {
    // handle result
  }
} on PlatformException catch (e) {
  print('Error code: ${e.code}');
  print('Error message: ${e.message}');
}
```

Common error codes:

| Code | Meaning |
|---|---|
| `PERMISSION_DENIED` | Camera permission was denied (Android or iOS); also available as `scanner.cameraAccessDenied` |
| `BUSY` | A `scan()` or `scanPhoto()` call is already in progress |
| `INVALID_ARGUMENT` | Empty image path, empty image bytes, or empty QR generation input |
| `INVALID_IMAGE` | The image could not be loaded or decoded |
| `SCAN_FAILED` / `DETECTION_ERROR` | Barcode detection failed |
| `GENERATE_FAILED` | Android QR generation failed |
| `NO_ACTIVITY` / `UNAVAILABLE` / `SETUP_FAILED` | The scanner UI or camera could not be opened |
| `ACTIVITY_DETACHED` / `ENGINE_DETACHED` | Android closed the activity or engine during a scan |

---

## ⬆️ Migrating from 1.x

- All scan methods now return `Future<String?>` and `generateBarCode()` returns `Future<Uint8List?>`. Handle `null` (cancelled / nothing found) instead of catching a `TypeError`.
- Raise your Android `minSdk` to 24 and your iOS deployment target to 13.0 if they are lower.
- You can remove `NSPhotoLibraryUsageDescription` from `Info.plist` if nothing else in your app needs it.

---

## 🆚 Why qrscan_plus?

- A small API for camera, gallery, file, and byte scanning, plus QR generation.
- Android dependencies from Maven Central, with no JitPack setup.
- Native AVFoundation and Vision on iOS, with no third-party iOS scanner dependency.
- Supports CocoaPods and Swift Package Manager.

---

## 🗂 Changelog

See [CHANGELOG.md](https://github.com/itxmubi/qrscan_plus/blob/master/CHANGELOG.md) for the full version history.

**Latest — v2.0.0:**
- Updated for the latest Flutter (3.47), Android 16 (API 36) and iOS 26
- Nullable return types — `null` when a scan is cancelled or no code is found
- Android 13+ system photo picker; iOS `PHPickerViewController` — no photo permissions needed
- Swift Package Manager support and privacy manifest on iOS

---

## 🤝 Contributing

Contributions are welcome! Please open an issue first to discuss what you'd like to change.

1. Fork the repository
2. Create your feature branch: `git checkout -b feature/my-feature`
3. Commit your changes: `git commit -m 'feat: add my feature'`
4. Push to the branch: `git push origin feature/my-feature`
5. Open a Pull Request

---

## 📬 Links

- 📦 [pub.dev package](https://pub.dev/packages/qrscan_plus)
- 🐛 [Issue tracker](https://github.com/itxmubi/qrscan_plus/issues)
- 📖 [API reference](https://pub.dev/documentation/qrscan_plus/latest/)
- 💻 [Repository](https://github.com/itxmubi/qrscan_plus)

---

## 📄 License

MIT © [itxmubi](https://github.com/itxmubi)

See [LICENSE](https://github.com/itxmubi/qrscan_plus/blob/master/LICENSE) for full details.

## Development and testing

```bash
flutter pub get
flutter analyze
flutter test
cd example
flutter pub get
flutter test
flutter test integration_test/qrscan_integration_test.dart -d <device-id>
```

Native integration tests require an Android emulator/device or iOS simulator/device.
They verify generated PNGs, Unicode payloads, byte and file decoding, and invalid
images, no-code images, concurrent decoding, and EAN-13/Code 128 fixtures. CI runs Dart checks, Android
integration tests, and an iOS simulator build with integration tests.
The iOS simulator uses Vision revision 1 with CPU-only processing because newer
revisions can fail to create an inference context or return no detections there.
Physical devices use Vision's default revision; supported formats and detection
accuracy can differ from simulator results.

Camera permission denial, cancellation, rotation, and background/resume behavior
should also be checked manually on physical devices before a release.

The legacy `CameraAccessDenied` constant is deprecated in favor of
`cameraAccessDenied`; its value now matches `PERMISSION_DENIED`. Invalid input
returns a `PlatformException` with `INVALID_ARGUMENT` in debug and release builds.

If your app matches legacy Android error codes, migrate `INVALID_PATH` and
`INVALID_CODE` to `INVALID_ARGUMENT`, and `INVALID_IMAGE_BYTES` and
`IMAGE_LOAD_FAILED` to `INVALID_IMAGE`.
