#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'qrscan_plus'
  s.version          = '1.0.6'
  s.summary          = 'QR/barcode scan and QR generation plugin for Flutter.'
  s.description      = <<-DESC
Scan QR/barcode from camera or gallery and generate QR code images in Flutter.
                       DESC
  s.homepage         = 'https://github.com/itxmubi/qrscan_plus'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Mubashir Nawaz' => 'mubashir.nawaz40@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'

  s.ios.deployment_target = '12.0'
end
