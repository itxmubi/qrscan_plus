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
- 🖼 **Gallery scan** — pick an image from the photo library and decode it
- 📁 **Path scan** — decode a barcode from a local file path
- 🔢 **Bytes scan** — decode a barcode directly from raw `Uint8List` bytes
- 🏗 **QR code generator** — generate a QR code image from any string
- ✅ **No JitPack** — Android dependencies are on Maven Central; no extra Gradle config needed
- 🍎 **iOS 12+** supported with native AVFoundation

---

## 📱 Platform Support

| Method | Android | iOS | Description |
|---|---|---|---|
| `scan()` | ✅ | ✅ | Scan via live camera |
| `scanPhoto()` | ✅ | ✅ | Scan from gallery image |
| `scanPath(path)` | ✅ | ✅ | Scan from a file path |
| `scanBytes(bytes)` | ✅ | ✅ | Scan from raw byte data |
| `generateBarCode(text)` | ✅ | ✅ | Generate a QR code image |

> **Note:** `generateBarCode` returns PNG bytes on iOS and image bytes on Android.

---

## 🚀 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  qrscan_plus: ^1.0.8
```

Then run:

```bash
flutter pub get
```

---

## 🤖 Android Setup

No additional Gradle repository setup is needed. All dependencies are on Maven Central.

### Permissions

Add camera permission to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

> `scanPhoto()` uses the system image picker — no JitPack or legacy storage permissions required for this plugin. If your app directly accesses files or media, handle runtime permissions based on your Android version separately.

---

## 🍎 iOS Setup

Minimum deployment target: **iOS 12.0**

Add the following keys to your `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to scan QR codes and barcodes.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to scan QR codes from images.</string>
```

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

Always wrap scan and generate calls in a try-catch to handle user cancellation or permission errors gracefully:

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
| `PERMISSION_DENIED` | Camera or photo library permission was denied |
| `INVALID_ARGUMENT` | Null or empty input passed to scanBytes / scanPath |
| `SCAN_FAILED` | No barcode detected in the provided image |

---

## 🆚 Why qrscan_plus?

| Feature | qrscan_plus | qr_code_scanner_plus | mobile_scanner |
|---|---|---|---|
| No JitPack required | ✅ | ❌ | ✅ |
| `scanBytes()` support | ✅ | ❌ | ❌ |
| `scanPath()` support | ✅ | ❌ | ❌ |
| QR code generation | ✅ | ❌ | ❌ |
| iOS 12+ support | ✅ | ✅ | ✅ |
| Zero native iOS dependencies | ✅ | ❌ | ❌ |
| Maven Central only (Android) | ✅ | ❌ | ✅ |

---

## 🗂 Changelog

See [CHANGELOG.md](https://github.com/itxmubi/qrscan_plus/blob/master/CHANGELOG.md) for the full version history.

**Latest — v1.0.7+1:**
- Added iOS implementations for `scanBytes` and `scanPath` — prevents `MissingPluginException`
- Improved iOS barcode detection with shared detection path and better error propagation

**v1.0.7:**
- Removed JitPack dependency — migrated Android to Maven Central (`com.journeyapps:zxing-android-embedded`)
- Consumers no longer need to add `https://jitpack.io` to their Gradle repos

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