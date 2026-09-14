import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qrscan_plus/qrscan_plus.dart' as scanner;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('qr_scan');
  final calls = <MethodCall>[];
  Object? response;

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return response;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('scan returns the scanned code', () async {
    response = 'hello';
    expect(await scanner.scan(), 'hello');
    expect(calls.single.method, 'scan');
  });

  test('scan and scanPhoto return null when cancelled', () async {
    response = null;
    expect(await scanner.scan(), isNull);
    expect(await scanner.scanPhoto(), isNull);
  });

  test('scanPath and scanBytes pass their arguments', () async {
    response = 'code';
    final bytes = Uint8List.fromList([1, 2, 3]);
    expect(await scanner.scanPath('/tmp/qr.png'), 'code');
    expect(await scanner.scanBytes(bytes), 'code');
    expect(calls[0].method, 'scan_path');
    expect(calls[0].arguments, {'path': '/tmp/qr.png'});
    expect(calls[1].method, 'scan_bytes');
    expect(calls[1].arguments['bytes'], bytes);
  });

  test('generateBarCode returns PNG bytes', () async {
    response = Uint8List.fromList([137, 80, 78, 71]);
    expect(await scanner.generateBarCode('hi'), response);
    expect(calls.single.method, 'generate_barcode');
    expect(calls.single.arguments, {'code': 'hi'});
  });
}
