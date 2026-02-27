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
