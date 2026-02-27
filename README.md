# qrscan_plus

A Flutter plugin for scanning QR/barcodes and generating QR code images.

## Platform Support

| Feature | Android | iOS |
|---|---|---|
| `scan()` (camera) | ✅ | ✅ |
| `scanPhoto()` (gallery image) | ✅ | ✅ |
| `generateBarCode()` | ✅ | ✅ |
| `scanPath(path)` | ✅ | ❌ |
| `scanBytes(uint8list)` | ✅ | ❌ |

Notes:
- On iOS, `scanPath` and `scanBytes` are not implemented.
- `generateBarCode` generates a QR image (PNG bytes on iOS, image bytes on Android).

## Installation

```yaml
dependencies:
  qrscan_plus: ^1.0.6
```

## Android Setup

### 1) Add JitPack repository
This plugin depends on `android-zxingLibrary` from JitPack. Add JitPack in your Android repositories.

If you use `settings.gradle(.kts)` with `dependencyResolutionManagement`:

```kotlin
dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
        maven("https://jitpack.io")
    }
}
```

If your project still uses legacy `allprojects` repositories:

```gradle
allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url 'https://jitpack.io' }
    }
}
```

### 2) Permissions
Add required permissions in your app manifest (`android/app/src/main/AndroidManifest.xml`):

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

Notes:
- Gallery picking with `scanPhoto()` may work without manually requesting storage permission on modern Android.
- If your app explicitly requests media/storage permissions at runtime, use Android-version-aware logic (Android 13+ media permissions differ from legacy storage permissions).

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

Android-only methods:

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
