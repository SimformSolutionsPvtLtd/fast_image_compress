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
import 'dart:typed_data';

import '../fast_image_compress.dart';

class FastImageCompress {
  final ImageCompressionService _compressionService = ImageCompressionService();

  /// Get the platform version (already implemented)
  Future<String?> getPlatformVersion() {
    return FastImageCompressPlatform.instance.getPlatformVersion();
  }

  final StreamController<int> _progressController =
      StreamController<int>.broadcast();
  final StreamController<Uint8List> _compressImageStreamController =
      StreamController<Uint8List>.broadcast();
  int _completedCount = 0;
  bool isCompressionCancelled = false;

  /// Get image compression progress stream
  Stream<int> get progressStream => _progressController.stream;

  Stream<Uint8List> get compressedImageStream =>
      _compressImageStreamController.stream;

  /// Compresses a single image.
  ///
  /// This function compresses a single image based on the specified quality,
  /// target width, and image quality level. It returns the compressed image
  /// data or `null` if the compression is cancelled.
  ///
  /// - [imageData]: The image data as a `Uint8List` to be compressed.
  /// - [quality]: The compression quality percentage (default is 80).
  ///   Must be a value between 0 and 100, where 100 represents the highest quality.
  /// - [targetWidth]: The desired width for the compressed image (default is 500).
  ///   The height will be scaled proportionally to maintain the aspect ratio.
  /// - [imageQuality]: The quality of the image to undergo compression. This can be
  ///   `ImageQuality.high`, `ImageQuality.medium`, or `ImageQuality.low` (default is `ImageQuality.medium`).
  ///
  /// ### Returns:
  /// A `Future<Uint8List?>` that resolves to the compressed image data as a `Uint8List`,
  /// or `null` if the compression is cancelled.
  ///
  /// ### Throws:
  /// - An `AssertionError` if:
  ///   - [quality] is not between 0 and 100.
  ///   - [targetWidth] is less than 1.
  ///
  /// ### Notes:
  /// - If `isCompressionCancelled` is set to `true` before or during execution,
  ///   the function will reset the flag and return `null`.
  Future<Uint8List?>? compressImage({
    required Uint8List imageData,
    int quality = 60,
    int? targetWidth = 500,
    ImageQuality imageQuality = ImageQuality.medium,
  }) {
    assert(
    quality > 0 || quality < 100,
    'quality value should be between 0 to 100',
    );
    if (targetWidth != null) {
      assert(targetWidth > 1, "targetWidth can't be less than 1");
    }

    if (isCompressionCancelled) {
      isCompressionCancelled = false;
      return null;
    }
    return _compressionService.compressImage(
      imageData,
      quality,
      targetWidth,
      imageQuality,
    );
  }

  /// Compresses a list of images in batches.
  ///
  /// This function processes a list of images, compressing them based on the
  /// specified quality, target width, and image quality level. Images are
  /// processed in parallel batches to optimize performance.
  ///
  /// - [images]: A list of `Uint8List` objects representing the images to be compressed.
  /// - [quality]: The compression quality percentage (default is 80).
  ///   Must be a value between 0 and 100, where 100 represents the highest quality.
  /// - [targetWidth]: The desired width for the compressed images (default is 500).
  ///   The height will be scaled proportionally to maintain the aspect ratio.
  /// - [batchSize]: The number of images to process simultaneously in a batch (default is 3).
  ///   Must be at least 1.
  /// - [imageQuality]: The quality of the image to undergo compression. This can be
  ///   `ImageQuality.high`, `ImageQuality.medium`, or `ImageQuality.low` (default is `ImageQuality.medium`).
  ///
  /// ### Returns:
  /// A `Future` that resolves to a `List<Uint8List>` containing the compressed images.
  ///
  /// ### Throws:
  /// - An `AssertionError` if:
  ///   - [quality] is not between 0 and 100.
  ///   - [targetWidth] is less than 1.
  ///   - [batchSize] is less than 1.
  ///
  /// ### Notes:
  /// - Compression can be cancelled during execution by setting `isCompressionCancelled`
  ///   to `true`. Cancelled images will not be included in the result.
  /// - Progress of the compression process is reported via the `_progressController`.
  Future<List<Uint8List>> compressImageList({
    required List<Uint8List> images,
    int quality = 60,
    int? targetWidth,
    int batchSize = 3,
    ImageQuality imageQuality = ImageQuality.medium,
  }) async {
    assert(
      quality > 0 || quality < 100,
      'quality value should be between 0 to 100',
    );
    if (targetWidth != null) {
      assert(targetWidth > 1, "targetWidth can't be less than 1");
    }
    assert(batchSize >= 1, "batchSize should be greater than or equal to 1");
    List<Uint8List> compressedImages = [];
    _completedCount = 0;

    for (var i = 0; i < images.length; i += batchSize) {
      final batch = images.skip(i).take(batchSize).toList();

      await Future.wait(batch.map((image) async {
        if (isCompressionCancelled) return;
        final compressedImage = await _compressionService.compressImage(
          image,
          quality,
          targetWidth,
          imageQuality,
        );
        if (compressedImage != null) {
          compressedImages.add(compressedImage);
          _completedCount++;
          _progressController.add(_completedCount);
          _compressImageStreamController.add(compressedImage);
        }
      }));
    }
    isCompressionCancelled = false;
    return compressedImages;
  }

  /// Cancels the ongoing image compression process.
  Future<void> cancelCompression() async {
    isCompressionCancelled = true;
    await _compressionService.cancelCompression();
  }

  /// Dispose resources
  void dispose() {
    _progressController.close();
    _compressImageStreamController.close();
    _compressionService.dispose();
  }
}
