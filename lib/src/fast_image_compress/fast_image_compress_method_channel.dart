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

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'fast_image_compress_platform_interface.dart';

/// An implementation of [FastImageCompressPlatform] that uses method channels.
class MethodChannelFastImageCompress extends FastImageCompressPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('fast_image_compress');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<Uint8List?> compressImage(
    Uint8List imageData,
    int? targetWidth,
    int compressionQuality,
    String imageQuality,
  ) async {
    try {
      final result = await methodChannel.invokeMethod<Uint8List>(
        'compressImage',
        {
          'imageData': imageData,
          'targetWidth': targetWidth,
          'compressionQuality': compressionQuality,
          'imageQuality': imageQuality,
        },
      );
      return result;
    } catch (e) {
      // Handle any exceptions that might occur
      throw PlatformException(
        code: 'COMPRESS_IMAGE_FAILED',
        message: 'Failed to compress the image: $e',
      );
    }
  }
}
