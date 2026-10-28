import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:qrscan_example/main.dart';
import 'package:qrscan_plus/qrscan_plus.dart' as scanner;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('native QR generation decodes through bytes and file paths', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    for (final payload in ['https://example.com', 'Hello مرحبا 世界 👋']) {
      final png = await scanner.generateBarCode(payload);
      expect(png, isNotNull);
      expect(png!.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
      expect(await scanner.scanBytes(png), payload);
      final directory = await Directory.systemTemp.createTemp('qrscan_test_');
      try {
        final file = await File('${directory.path}/qr.png').writeAsBytes(png);
        expect(await scanner.scanPath(file.path), payload);
        expect(await scanner.scanPath(file.uri.toString()), payload);
      } finally {
        await directory.delete(recursive: true);
      }
    }
  });

  testWidgets('native decoders reject invalid images consistently', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    final invalidImage = isA<PlatformException>().having(
      (error) => error.code,
      'code',
      'INVALID_IMAGE',
    );
    await expectLater(
      scanner.scanBytes(Uint8List.fromList([1, 2, 3])),
      throwsA(invalidImage),
    );
    await expectLater(
      scanner.scanPath('${Directory.systemTemp.path}/missing-qrscan.png'),
      throwsA(invalidImage),
    );
  });
  testWidgets('valid image without a barcode returns null', (tester) async {
    await tester.pumpWidget(const MyApp());
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawColor(const ui.Color(0xFFFFFFFF), ui.BlendMode.src);
    final picture = recorder.endRecording();
    final image = await picture.toImage(100, 100);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      expect(await scanner.scanBytes(data!.buffer.asUint8List()), isNull);
    } finally {
      image.dispose();
      picture.dispose();
    }
  });

  testWidgets('concurrent non-UI operations keep their own results', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    final images = await Future.wait([
      scanner.generateBarCode('first'),
      scanner.generateBarCode('second'),
    ]);
    final results = await Future.wait(
      images.map((image) => scanner.scanBytes(image!)),
    );
    expect(results, ['first', 'second']);
  });
  testWidgets('native decoders recognize EAN-13 and Code 128 fixtures', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    for (final entry in {
      'ean13': '5901234123457',
      'code128': 'qrscan-plus-128',
    }.entries) {
      final fixture = await rootBundle.load(
        'integration_test/fixtures/${entry.key}.png',
      );
      expect(
        await scanner.scanBytes(
          fixture.buffer.asUint8List(
            fixture.offsetInBytes,
            fixture.lengthInBytes,
          ),
        ),
        entry.value,
      );
    }
  });
}
