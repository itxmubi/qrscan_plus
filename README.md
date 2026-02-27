# qrscan_plus

A Flutter plugin for scanning QR/barcodes and generating QR code images.

## Platform Support

| Feature | Android | iOS |
|---|---|---|
| `scan()` (camera) | ✅ | ✅ |
| `scanPhoto()` (gallery image) | ✅ | ✅ |
| `generateBarCode()` | ✅ | ✅ |
| `scanPath(path)` | ✅ | ✅ |
| `scanBytes(uint8list)` | ✅ | ✅ |

Notes:
- `generateBarCode` generates a QR image (PNG bytes on iOS, image bytes on Android).

## Installation

```yaml
dependencies:
  qrscan_plus: ^1.0.7
```

## Android Setup

No additional Gradle repository setup is required for this plugin.

### Permissions
Add camera permission in your app manifest (`android/app/src/main/AndroidManifest.xml`):

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

Notes:
- `scanPhoto()` uses the system image picker and does not require adding JitPack or legacy storage permissions for this plugin flow.
- If your app has its own direct file/media access flows, handle runtime media/storage permissions separately based on Android version.

## iOS Setup

Minimum iOS deployment target: `12.0`.

Add usage descriptions in your app `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to scan QR/barcodes.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to scan QR/barcodes from images.</string>
```

## Usage

```dart
import 'package:qrscan_plus/qrscan_plus.dart' as scanner;

Future<void> runQrscan() async {
  final cameraResult = await scanner.scan();
  final photoResult = await scanner.scanPhoto();
  final qrBytes = await scanner.generateBarCode('https://github.com/itxmubi/qrscan_plus');
}
```

Extra methods:

```dart
final byPath = await scanner.scanPath('/storage/emulated/0/Download/test.png');
final byBytes = await scanner.scanBytes(uint8list);
```

## Error Handling Recommendation

Handle platform exceptions around scan/generate calls:

```dart
try {
  final result = await scanner.scanPhoto();
  // use result
} on PlatformException catch (e) {
  // handle e.code / e.message
}
```

## Repository and Issue Tracker

- Repository: https://github.com/itxmubi/qrscan_plus
- Issues: https://github.com/itxmubi/qrscan_plus/issues

## License

MIT. See [LICENSE](LICENSE).
