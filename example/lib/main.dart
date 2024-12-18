import 'dart:async';
import 'dart:typed_data';

import 'package:fast_image_compress/fast_image_compress.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fast Image Compress Example',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: const CompressionExamplePage(),
    );
  }
}

class CompressionExamplePage extends StatefulWidget {
  const CompressionExamplePage({super.key});

  @override
  CompressionExamplePageState createState() => CompressionExamplePageState();
}

class CompressionExamplePageState extends State<CompressionExamplePage> {
  final FastImageCompress fastImageCompress = FastImageCompress();
  final ImagePicker _imagePicker = ImagePicker();
  List<Uint8List>? _originalImageList;
  List<Uint8List>? _compressedImageList;
  bool _isCompressing = false;
  double _progress = 0.0;
  int _completedCount = 0;
  bool _isCancelled = false;

  Future<void> _pickImage() async {
    setState(() {
      _originalImageList = [];
      _compressedImageList = null;
    });

    final pickedFiles = await _imagePicker.pickMultiImage(limit: 30);
    if (pickedFiles.isNotEmpty) {
      final res = await Future.wait(
        pickedFiles.map((file) async => await file.readAsBytes()),
      );
      setState(() {
        _originalImageList = res;
        _compressedImageList = null; // Reset compressed image
      });
    }
  }

  Future<void> _compressImage() async {
    if (_originalImageList == null || _originalImageList!.isEmpty) return;

    setState(() {
      _isCancelled = false;
      _isCompressing = true;
      _progress = 0.0;
    });

    final totalImages = _originalImageList!.length;
    fastImageCompress.progressStream.listen((completedCount) {
      if (_isCancelled == false) {
        setState(() {
          _progress = (completedCount / totalImages);
          _completedCount = completedCount;
        });
      }
    });

    final compressedImageList = await fastImageCompress.compressImageList(
      images: _originalImageList!,
      quality: 90,
      batchSize: 2,
      imageQuality: ImageQuality.high,
      targetWidth: 300,
    );

    if (_isCancelled == false) {
      setState(() {
        _compressedImageList = compressedImageList;
        _isCompressing = false;
      });
    }
  }

  Future<void> _cancelCompression() async {
    await fastImageCompress.cancelCompression();
    setState(() {
      _isCancelled = true;
      _compressedImageList = null;
      _isCompressing = false;
      _progress = 0;
      _completedCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalSelectedImages = _originalImageList?.length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Compression Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Pick Image'),
            ),
            if (_originalImageList != null) ...[
              const SizedBox(height: 20),
              Text(
                'Selected image count: ${_originalImageList?.length ?? 0}',
              ),
            ],
            const SizedBox(height: 20),
            if (!_isCompressing) ...[
              ElevatedButton(
                onPressed: _compressImage,
                child: const Text('Compress Image'),
              ),
              const SizedBox(height: 20),
            ] else ...[
              ElevatedButton(
                onPressed: _cancelCompression,
                child: const Text('Cancel Compression'),
              ),
              const SizedBox(height: 20),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: LinearProgressIndicator(value: _progress),
            ),
            const SizedBox(height: 10),
            if (totalSelectedImages != null && totalSelectedImages > 0)
              Text(
                '$_completedCount/$totalSelectedImages Compressed',
                style: const TextStyle(fontSize: 16.0),
              ),
            if (_compressedImageList != null &&
                _compressedImageList!.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('Compressed Images:'),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemBuilder: (BuildContext context, int index) {
                    if (index < _compressedImageList!.length) {
                      final actualImageSize =
                          (_originalImageList![index].lengthInBytes / 1024)
                              .toStringAsFixed(2);
                      final compressedImageSize =
                          (_compressedImageList![index].lengthInBytes / 1024)
                              .toStringAsFixed(2);
                      return Column(
                        children: [
                          Image.memory(_compressedImageList![index]),
                          Text(
                            'Actual Image Size: $actualImageSize Kb \nCompressed Image Size: $compressedImageSize Kb',
                          ),
                        ],
                      );
                    }
                    return null;
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    fastImageCompress.dispose();
    super.dispose();
  }
}
