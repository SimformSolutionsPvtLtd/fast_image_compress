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

import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'fast_image_compress_method_channel.dart';

abstract class FastImageCompressPlatform extends PlatformInterface {
  /// Constructs a FastImageCompressPlatform.
  FastImageCompressPlatform() : super(token: _token);

  static final Object _token = Object();

  static FastImageCompressPlatform _instance = MethodChannelFastImageCompress();

  /// The default instance of [FastImageCompressPlatform] to use.
  ///
  /// Defaults to [MethodChannelFastImageCompress].
  static FastImageCompressPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FastImageCompressPlatform] when
  /// they register themselves.
  static set instance(FastImageCompressPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// Compress an image given its byte data and target width.
  Future<Uint8List?> compressImage(
    Uint8List imageData,
    int? targetWidth,
    int compressionQuality,
    String imageQuality,
  ) {
    throw UnimplementedError('compressImage() has not been implemented.');
  }
}
