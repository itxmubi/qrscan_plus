import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qrscan_plus/qrscan_plus.dart' as scanner;

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Uint8List bytes = Uint8List(0);
  TextEditingController? _inputController;
  TextEditingController? _outputController;

  @override
  initState() {
    super.initState();
    _inputController = TextEditingController();
    _outputController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.grey[300],
        body: Builder(
          builder: (BuildContext context) {
            return ListView(
              children: <Widget>[
                _qrCodeWidget(bytes, context),
                Container(
                  color: Colors.white,
                  child: Column(
                    children: <Widget>[
                      TextField(
                        controller: _inputController,
                        keyboardType: TextInputType.url,
                        textInputAction: TextInputAction.go,
                        onSubmitted: (value) => _generateBarCode(value),
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.text_fields),
                          helperText:
                              'Please input your code to generage qrcode image.',
                          hintText: 'Please Input Your Code',
                          hintStyle: TextStyle(fontSize: 15),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 7, vertical: 15),
                        ),
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: _outputController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.wrap_text),
                          helperText:
                              'The barcode or qrcode you scan will be displayed in this area.',
                          hintText:
                              'The barcode or qrcode you scan will be displayed in this area.',
                          hintStyle: TextStyle(fontSize: 15),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 7, vertical: 15),
                        ),
                      ),
                      SizedBox(height: 20),
                      _buttonGroup(),
                      SizedBox(height: 70),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _scanBytes(),
          tooltip: 'Take a Photo',
          child: const Icon(Icons.camera_alt),
        ),
      ),
    );
  }

  Widget _qrCodeWidget(Uint8List bytes, BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Card(
        elevation: 6,
        child: Column(
          children: <Widget>[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(4), topRight: Radius.circular(4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Icon(Icons.verified_user, size: 18, color: Colors.green),
                  Text('  Generate Qrcode', style: TextStyle(fontSize: 15)),
                  Spacer(),
                  Icon(Icons.more_vert, size: 18, color: Colors.black54),
                ],
              ),
            ),
            Padding(
              padding:
                  EdgeInsets.only(left: 40, right: 40, top: 30, bottom: 10),
              child: Column(
                children: <Widget>[
                  SizedBox(
                    height: 190,
                    child: bytes.isEmpty
                        ? Center(
                            child: Text('Empty code ... ',
                                style: TextStyle(color: Colors.black38)),
                          )
                        : Image.memory(bytes),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 7, left: 25, right: 25),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        Expanded(
                          flex: 5,
                          child: GestureDetector(
                            child: Text(
                              'remove',
                              style:
                                  TextStyle(fontSize: 15, color: Colors.blue),
                              textAlign: TextAlign.left,
                            ),
                            onTap: () =>
                                setState(() => this.bytes = Uint8List(0)),
                          ),
                        ),
                        Text('|',
                            style:
                                TextStyle(fontSize: 15, color: Colors.black26)),
                        Expanded(
                          flex: 5,
                          child: GestureDetector(
                            onTap: () async {
                              final success =
                                  await ImageGallerySaverPlus.saveImage(
                                      this.bytes);
                              SnackBar snackBar;
                              if (success['isSuccess']) {
                                snackBar = SnackBar(
                                    content: Text('Successful Preservation!'));
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(snackBar);
                              } else {
                                snackBar =
                                    SnackBar(content: Text('Save failed!'));
                              }
                            },
                            child: Text(
                              'save',
                              style:
                                  TextStyle(fontSize: 15, color: Colors.blue),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            Divider(height: 2, color: Colors.black26),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              child: Row(
                children: <Widget>[
                  Icon(Icons.history, size: 16, color: Colors.black38),
                  Text('  Generate History',
                      style: TextStyle(fontSize: 14, color: Colors.black38)),
                  Spacer(),
                  Icon(Icons.chevron_right, size: 16, color: Colors.black38),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buttonGroup() {
    return Row(
      children: <Widget>[
        Expanded(
          flex: 1,
          child: SizedBox(
            height: 120,
            child: InkWell(
              onTap: () => _generateBarCode(_inputController!.text),
              child: Card(
                child: Column(
                  children: <Widget>[
                    Expanded(
                      flex: 2,
                      child: Image.asset('images/generate_qrcode.png'),
                    ),
                    Divider(height: 20),
                    Expanded(flex: 1, child: Text("Generate")),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: SizedBox(
            height: 120,
            child: InkWell(
              onTap: _scan,
              child: Card(
                child: Column(
                  children: <Widget>[
                    Expanded(
                      flex: 2,
                      child: Image.asset('images/scanner.png'),
                    ),
                    Divider(height: 20),
                    Expanded(flex: 1, child: Text("Scan")),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: SizedBox(
            height: 120,
            child: InkWell(
              onTap: _scanPhoto,
              child: Card(
                child: Column(
                  children: <Widget>[
                    Expanded(
                      flex: 2,
                      child: Image.asset('images/albums.png'),
                    ),
                    Divider(height: 20),
                    Expanded(flex: 1, child: Text("Scan Photo")),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future _scan() async {
    try {
      String barcode = await scanner.scan();

      log(barcode);
      _outputController!.text = barcode;
      // }
    } catch (e) {
      log(e.toString());
    }
  }

  Future<void> _scanPhoto() async {
    try {
      final barcode = await scanner.scanPhoto();
      _outputController!.text =
          barcode.isNotEmpty ? barcode : 'No barcode/QR code found.';
    } on PlatformException catch (e) {
      log('scanPhoto platform error: ${e.code} ${e.message}');
      _outputController!.text =
          e.message ?? 'Failed to scan photo (${e.code}).';
    } catch (e) {
      log('scanPhoto error: $e');
      _outputController!.text = 'Failed to scan photo.';
    }
  }

  // Future _scanPath(String path) async {
  //   await Permission.storage.request();
  //   String barcode = await scanner.scanPath(path);
  //   this._outputController!.text = barcode;
  // }

  Future _scanBytes() async {
    File file = await ImagePicker()
        .pickImage(source: ImageSource.camera)
        .then((picked) {
      if (picked != null) return File(picked.path);
      return File(picked!.path);
    });
    Uint8List bytes = file.readAsBytesSync();
    String barcode = await scanner.scanBytes(bytes);
    _outputController!.text = barcode;
  }

  Future<void> _generateBarCode(String inputCode) async {
    final code = inputCode.trim();
    if (code.isEmpty) {
      _outputController!.text = 'Please enter text to generate a barcode.';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Input cannot be empty.')),
        );
      }
      return;
    }

    try {
      final result = await scanner.generateBarCode(code);
      setState(() => bytes = result);
    } on PlatformException catch (e) {
      log('generateBarCode platform error: ${e.code} ${e.message}');
      _outputController!.text =
          e.message ?? 'Failed to generate barcode (${e.code}).';
    } catch (e) {
      log('generateBarCode error: $e');
      _outputController!.text = 'Failed to generate barcode.';
    }
  }
}
