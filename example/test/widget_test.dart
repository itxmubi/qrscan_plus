import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qrscan_example/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('qr_scan');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('empty generation shows validation without a platform call', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Generate QR code'));
    await tester.pumpAndSettle();
    expect(find.text('Please enter some text.'), findsOneWidget);
  });

  testWidgets('scanner displays permission failures', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async {
          throw PlatformException(code: 'PERMISSION_DENIED');
        });
    await tester.pumpWidget(const MyApp());
    await tester.ensureVisible(find.text('Scan with camera'));
    await tester.tap(find.text('Scan with camera'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Camera permission denied.'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Scan with camera'),
          )
          .onPressed,
      isNotNull,
    );
  });
  testWidgets('pending scan disables actions and survives widget disposal', (
    tester,
  ) async {
    final reply = Completer<String?>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) => reply.future);
    await tester.pumpWidget(const MyApp());
    await tester.ensureVisible(find.text('Scan with camera'));
    await tester.tap(find.text('Scan with camera'));
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Scan with camera'),
          )
          .onPressed,
      isNull,
    );
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    reply.complete('late result');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
