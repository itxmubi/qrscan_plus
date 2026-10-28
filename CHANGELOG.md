## Unreleased
**Error-code compatibility changes:** Android `INVALID_PATH` and `INVALID_CODE` become `INVALID_ARGUMENT`; `INVALID_IMAGE_BYTES` and `IMAGE_LOAD_FAILED` become `INVALID_IMAGE`. Update handlers that match these strings.

- Enable supported 1D and 2D barcode formats in the iOS camera scanner.
- Move Android photo/file/byte decoding and QR generation off the main thread, recycle temporary bitmaps, and allow non-UI methods without an attached activity.
- Normalize Android and iOS invalid input/image errors; add release-mode Dart validation and a `cameraAccessDenied` constant. Deprecate `CameraAccessDenied` and update its value to `PERMISSION_DENIED`.
- Report Android camera permission denial separately from cancellation; align QR generation at error correction level M.
- Support `file://` image paths on Android as well as iOS.
- Update the example with loading states, controller disposal, error handling, and all scan methods.
- Replace obsolete Travis CI with GitHub Actions and add native round-trip and barcode-fixture integration tests.
- Repair the example's missing Kotlin plugin and debug-only Espresso dependency for AGP 9 integration-test compatibility.
- Use Vision revision 1 with CPU-only processing on iOS simulators so image decoding works there; physical devices retain the default Vision revision.

## [2.0.0]
**Breaking changes**
- `scan()`, `scanPhoto()`, `scanPath()` and `scanBytes()` now return `Future<String?>`, and `generateBarCode()` returns `Future<Uint8List?>`. `null` means the scan was cancelled or no code was found. Previously a cancelled scan threw a `TypeError`.
- Requires Flutter 3.38+ / Dart 3.10+ (tested on Flutter 3.41 and 3.47).
- Android `minSdk` raised to 24 (the Flutter default); iOS deployment target raised to 13.0.

**Android**
- `compileSdk` 36 (Android 16), Java 17, Kotlin DSL build script (AGP 9.1). Removed the unused Kotlin plugin, Jetifier and appcompat dependency; `zxing:core` 3.5.4.
- `scanPhoto()` uses the Android 13+ system photo picker (no media permissions), falling back to `ACTION_PICK` on older devices.
- Large photos are downsampled before decoding to avoid out-of-memory crashes with 50-200 MP cameras.
- The camera scanner follows the device orientation instead of being locked to landscape.
- The activity result listener is removed on detach, and an in-flight scan survives configuration changes.
- Removed unused legacy classes and resources.

**iOS**
- Added Swift Package Manager support (CocoaPods still supported) and a privacy manifest.
- `scanPhoto()` uses `PHPickerViewController` on iOS 14+, so `NSPhotoLibraryUsageDescription` is no longer required.
- `generateBarCode()` renders through `CIContext` with nearest-neighbour scaling for crisp PNG output.
- Each call completes its own result, so concurrent calls no longer overwrite each other and a camera scan reports only once.
- Barcode detection runs off the main thread; the scanner's close button respects the safe area; a denied camera permission always reports `PERMISSION_DENIED`.
- Removed the unused Objective-C registration shim.

**Example**
- Updated to the Flutter 3.47 templates (AGP 9.1, Gradle 9.3.1, Kotlin 2.4, iOS 15).

## [1.0.8]
- Update Readme


## [1.0.7+1]
- Added iOS implementations for `scan_bytes` and `scan_path` to match method-channel API coverage and prevent `MissingPluginException`.
- Updated iOS barcode detection flow to share a common detection path with improved error propagation.
- Updated README feature matrix to reflect iOS support for `scanBytes` and `scanPath`.

## [1.0.7]
- Removed JitPack-only dependency path from Android implementation.
- Migrated Android scanner implementation to Maven Central ZXing dependencies (`com.journeyapps:zxing-android-embedded` + `com.google.zxing:core`).
- Consumers no longer need to manually add `https://jitpack.io` to their app Gradle repositories.
- Refactored Android scan flows (`scan`, `scanPhoto`, `scanPath`, `scanBytes`, `generateBarCode`) to work without `android-zxingLibrary`.

## [1.0.6]
- Updated Android Gradle Plugin compatibility for modern AndroidX dependencies (AGP 8.9.1 support in plugin/example).
- Fixed Android compile issue by removing obsolete Flutter v1 `Registrar` registration path.
- Improved Android scan/photo robustness:
  - Added safer result handling for cancel/error paths.
  - Added URI fallback decoding when absolute file paths are unavailable on scoped storage devices.
  - Added stronger argument validation and explicit error codes for invalid input/image data.
- Updated `SecondActivity` to modern activity/back APIs and cleaned result intent payload handling.
- Improved example app error handling:
  - Better `_scanPhoto()` platform error handling.
  - Input validation and exception handling for barcode generation with empty input.

## [1.0.4+2] 

## [1.0.4+1] 

## [1.0.4] 
Added IOS Support
## [1.0.3]
## [1.0.2]
- Update Gradle Files
## [1.0.1]
- Update Documentation
## [1.0.0]
- Initial release.
