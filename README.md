Language: [English](README.md)

# QR Code Scanner

[![License][license-image]][license-url]
[![Pub](https://img.shields.io/pub/v/qrscan.svg?style=flat-square)](https://pub.dartlang.org/packages/qrscan)

A Flutter plugin 🛠 to scanning. Ready for Android & IOS🚀

This project is a **fork** of the original [qrscan](https://github.com/itxmubi/qrscan_plus) plugin, which I have **updated to be compatible with the latest Flutter and Android versions**. Thanks to the original author for their amazing work!

## Reporting Issues

If you encounter any issues or have suggestions for improvements, please report them by opening a new issue on GitHub:

🔗 https://github.com/itxmubi/qrscan_plus/issues

Your feedback helps make this project better!

## 📢 Note for Android Developers

To use this plugin, you **must** add the following Maven repository in your project’s `android/build.gradle` (or `build.gradle.kts`):

```gradle
allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url 'https://jitpack.io' } // 👈 Add this line
    }
}
```

[Qrscan Plus](https://github.com/itxmubi/qrscan_plus)

## Permission：

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
```

## 📢 Note for iOS Developers

> **Important:** You must add camera and photo library permissions to your iOS project to use this package.

In your `Info.plist`, add the following entries:

```xml
<key>NSCameraUsageDescription</key>
<string>This app requires camera access to scan QR codes.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>This app requires photo library access to select images for scanning.</string>
```

## Installation

Add this to your package's pubspec.yaml file:

```yaml
dependencies:
  qrscan_plus: any
```

## Scan Usage example

```dart
import 'package:qrscan_plus/qrscan_plus.dart' as scanner;

String cameraScanResult = await scanner.scan();
```

## Supported

- [x] Scan BR-CODE
- [x] Scan QR-CODE
- [x] Control the flash while scanning
- [x] Apply for camera privileges
- [x] Scanning BR-CODE or QR-CODE in albums
- [x] Parse to code string with uint8list
- [x] Scanning the image of the specified path
- [x] Display the switch button of the flashlight according to the light intensity
- [x] Generate QR-CODE

## Features

- Generate BR-CODE

## Demo App

![qrscan.gif](https://github.com/wechat-program/album/blob/master/pic/cons/qr_scan_demo.gif)

## Select Bar-Code or QR-Code photos for analysis and Generating QR-Code

```dart
import 'package:qrscan_plus/qrscan_plus.dart' as scanner;

// Select Bar-Code or QR-Code photos for analysis
String photoScanResult = await scanner.scanPhoto();

// Generating QR-Code
Uint8List result = await scanner.generateBarCode('https://github.com/itxmubi/qrscan_plus');

// Scanning the image of the specified path
String barcode = await scanner.scanPath(path);

// Parse to code string with uint8list
File file = await ImagePicker.pickImage(source: ImageSource.camera);
Uint8List bytes = file.readAsBytesSync();
String barcode = await scanner.scanBytes(uint8list);
```

## Contribute

We would ❤️ to see your contribution!

## License

Distributed under the MIT license. See `LICENSE` for more information.

## About

Real Thanks to Shusheng.

Updated and Maintained By [Mubashir Nawaz](https://github.com/itxmubi)

[license-image]: https://img.shields.io/badge/License-MIT-blue.svg
[license-url]: LICENSE

## Thanks
