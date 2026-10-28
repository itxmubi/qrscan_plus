import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qrscan_plus/qrscan_plus.dart' as scanner;

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
    home: const ScannerExample(),
  );
}

class ScannerExample extends StatefulWidget {
  const ScannerExample({super.key});

  @override
  State<ScannerExample> createState() => _ScannerExampleState();
}

class _ScannerExampleState extends State<ScannerExample> {
  final _inputController = TextEditingController();
  Uint8List? _qrImage;
  String _status = 'Choose a scan method or generate a QR code.';
  bool _busy = false;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<String> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final status = await action();
      if (mounted) setState(() => _status = status);
    } on PlatformException catch (error) {
      if (mounted) {
        setState(
          () => _status = error.code == scanner.cameraAccessDenied
              ? 'Camera permission denied. Enable camera access in Settings.'
              : '${error.code}: ${error.message ?? 'Operation failed.'}',
        );
      }
    } catch (error) {
      if (mounted) setState(() => _status = 'Operation failed: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String> _generate() async {
    if (_inputController.text.trim().isEmpty) return 'Please enter some text.';
    final image = await scanner.generateBarCode(_inputController.text);
    if (image == null) return 'Could not generate a QR code.';
    if (mounted) setState(() => _qrImage = image);
    return 'QR code generated.';
  }

  Future<String> _scanImage({required bool useBytes}) async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image == null) return 'Image selection cancelled.';
    final result = useBytes
        ? await scanner.scanBytes(await image.readAsBytes())
        : await scanner.scanPath(image.path);
    return result ?? 'No barcode or QR code found in this image.';
  }

  Future<String> _save() async {
    final image = _qrImage;
    if (image == null) return 'Generate a QR code first.';
    final result = await ImageGallerySaverPlus.saveImage(image);
    return result['isSuccess'] == true
        ? 'Image saved.'
        : 'Could not save image.';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('qrscan_plus example')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _inputController,
            enabled: !_busy,
            decoration: const InputDecoration(
              labelText: 'Text or URL',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _run(_generate),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : () => _run(_generate),
            icon: const Icon(Icons.qr_code),
            label: const Text('Generate QR code'),
          ),
          if (_qrImage != null) ...[
            const SizedBox(height: 16),
            Image.memory(
              _qrImage!,
              height: 220,
              filterQuality: FilterQuality.none,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: _busy ? null : () => _run(_save),
                  child: const Text('Save image'),
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() => _qrImage = null),
                  child: const Text('Clear image'),
                ),
              ],
            ),
          ],
          const Divider(height: 32),
          FilledButton.icon(
            onPressed: _busy
                ? null
                : () => _run(
                    () async =>
                        await scanner.scan() ??
                        'Scanner closed without a result.',
                  ),
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan with camera'),
          ),
          OutlinedButton(
            onPressed: _busy
                ? null
                : () => _run(
                    () async =>
                        await scanner.scanPhoto() ??
                        'No result: selection cancelled or no code found.',
                  ),
            child: const Text('Scan photo with native picker'),
          ),
          OutlinedButton(
            onPressed: _busy
                ? null
                : () => _run(() => _scanImage(useBytes: false)),
            child: const Text('Scan image by file path'),
          ),
          OutlinedButton(
            onPressed: _busy
                ? null
                : () => _run(() => _scanImage(useBytes: true)),
            child: const Text('Scan image by bytes'),
          ),
          const SizedBox(height: 20),
          if (_busy) const LinearProgressIndicator(),
          const SizedBox(height: 16),
          Semantics(liveRegion: true, child: SelectableText(_status)),
        ],
      ),
    ),
  );
}
