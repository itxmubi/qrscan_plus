#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'qrscan_plus'
  s.version          = '2.0.0'
  s.summary          = 'QR/barcode scan and QR generation plugin for Flutter.'
  s.description      = <<-DESC
Scan QR/barcode from camera or gallery and generate QR code images in Flutter.
                       DESC
  s.homepage         = 'https://github.com/itxmubi/qrscan_plus'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Mubashir Nawaz' => 'mubashir.nawaz40@gmail.com' }
  s.source           = { :path => '.' }
  # Sources live in the Swift Package Manager layout so the plugin supports both SwiftPM and CocoaPods.
  s.source_files = 'qrscan_plus/Sources/qrscan_plus/**/*.swift'
  s.resource_bundles = { 'qrscan_plus_privacy' => ['qrscan_plus/Sources/qrscan_plus/PrivacyInfo.xcprivacy'] }
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
