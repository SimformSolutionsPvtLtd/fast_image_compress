/*
 * Copyright (c) 2021 Simform Solutions
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import 'dart:async';
import 'dart:isolate';

import 'package:fast_image_compress/values/constants.dart';
import 'package:flutter/services.dart';

class ImageCompressionService {
  SendPort? _isolateSendPort;
  Isolate? _isolate;
  bool isInitialized = false;
  static const platform = MethodChannel(Constants.methodChannelName);

  Future<void> initializeIsolate() async {
    if (_isolate != null) return;
    final receivePort = ReceivePort();
    final initData = (RootIsolateToken.instance!, receivePort.sendPort);
    _isolate = await Isolate.spawn(_isolateMain, initData);
    _isolateSendPort = await receivePort.first as SendPort;
    isInitialized = true;
  }

  Future<Uint8List?> compressImage(
    Uint8List imageData,
    int quality,
    int? targetWidth,
    ImageQuality imageQuality,
  ) async {
    if (!isInitialized) await initializeIsolate();
    final responsePort = ReceivePort();
    _isolateSendPort!.send({
      Constants.imageData: imageData,
      Constants.quality: quality,
      Constants.targetWidth: targetWidth,
      Constants.port: responsePort.sendPort,
      Constants.imageQuality: imageQuality
    });
    return await responsePort.first as Uint8List?;
  }

  static void _isolateMain(
    (RootIsolateToken rootToken, SendPort sendPort) params,
  ) {
    final receivePort = ReceivePort();
    params.$2.send(receivePort.sendPort);

    BackgroundIsolateBinaryMessenger.ensureInitialized(params.$1);

    receivePort.listen((message) async {
      if (message is Map<String, dynamic>) {
        try {
          final imageData = message[Constants.imageData] as Uint8List;
          final quality = message[Constants.quality] as int;
          final targetWidth = message[Constants.targetWidth] as int?;
          final responsePort = message[Constants.port] as SendPort;
          final imageQuality = message[Constants.imageQuality] as ImageQuality;

          Uint8List? processedImage;
          processedImage = await imageCompress(
            imageData,
            targetWidth,
            quality,
            imageQuality.name,
          );

          responsePort.send(processedImage);
        } catch (_) {
          message[Constants.port].send(null);
        }
      }
    });
  }

  static Future<Uint8List?> imageCompress(
    Uint8List imageData,
    int? targetWidth,
    int compressionQuality,
    String imageQuality,
  ) async {
    try {
      final message = {
        Constants.imageData: imageData,
        Constants.targetWidth: targetWidth,
        Constants.compressionQuality: compressionQuality,
        Constants.imageQuality: imageQuality,
      };
      final resizedImage = await platform.invokeMethod<Uint8List?>(
        Constants.compressImageMethodName,
        message,
      );
      return resizedImage;
    } on PlatformException catch (_) {
      return null;
    }
  }

  Future<void> cancelCompression() async {
    await platform.invokeMethod(Constants.cancelCompressionMethodName);
  }

  void dispose() {
    _isolate?.kill();
    _isolate = null;
  }
}

enum ImageQuality {
  low,
  medium,
  high;
}
