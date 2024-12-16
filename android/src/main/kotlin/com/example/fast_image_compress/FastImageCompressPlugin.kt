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

package com.example.fast_image_compress

import Constants
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.media.ExifInterface
import android.os.Build
import androidx.annotation.RequiresApi
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream

/** FastImageCompressPlugin */

enum class ImageQuality(val sampleSize: Int) {
  HIGH(8), MEDIUM(4), LOW(2)
}

class FastImageCompressPlugin: FlutterPlugin, MethodCallHandler {

  // MethodChannel for communication between Flutter and native Android
  private lateinit var channel: MethodChannel
  private var inputImageSize: Int = 0

  // Flag to handle cancellation of image compression
  @Volatile
  private var isCancelled = false

  // Called when the plugin is attached to the Flutter engine
  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, Constants.METHOD_CHANNEL_NAME)
    channel.setMethodCallHandler(this)
  }

  // Handles incoming method calls from Flutter
  @RequiresApi(Build.VERSION_CODES.N)
  override fun onMethodCall(call: MethodCall, result: Result) {
    if (call.method == Constants.COMPRESSION_METHOD_NAME) {
      // Retrieve arguments from the method call
      val byteArray = call.argument<ByteArray>(Constants.IMAGE_DATA)
      val targetWidth = call.argument<Int?>(Constants.TARGET_WIDTH)
      val compressionQuality = call.argument<Int?>(Constants.COMPRESSION_QUALITY)
      val imageQualityInString = call.argument<String>(Constants.IMAGE_QUALITY)

      // Determine the image quality based on the input string
      val imageQuality =
        if (imageQualityInString == Constants.IMAGE_QUALITY_HIGH) ImageQuality.HIGH
        else if (imageQualityInString == Constants.IMAGE_QUALITY_LOW) ImageQuality.LOW
        else ImageQuality.MEDIUM

      if (byteArray != null) {
        try {
          val options = BitmapFactory.Options()
          // Only fetches the image dimensions, doesn't load the image into memory
          options.inJustDecodeBounds = true
          BitmapFactory.decodeByteArray(byteArray, 0, byteArray.size, options)
          inputImageSize = byteArray.size

          // Calculate the sampling size for image decoding
          options.inSampleSize =
            calculateInSampleSize(options, targetWidth, imageQuality, compressionQuality)
          // Decodes the image fully with the calculated sample size
          options.inJustDecodeBounds = false

          // Decode the image into a Bitmap
          var bitmap =
            BitmapFactory.decodeByteArray(byteArray, 0, byteArray.size, options)

          // Handle cancellation
          if (isCancelled) {
            bitmap.recycle()
            result.error("CANCELLED", "Compression cancelled by user", null)
            return
          }

          // Read the image's EXIF data to handle orientation
          val exif = ExifInterface(ByteArrayInputStream(byteArray))
          val orientation = exif.getAttributeInt(
            ExifInterface.TAG_ORIENTATION,
            ExifInterface.ORIENTATION_NORMAL
          )
          val correctedBitmap = applyExifOrientation(bitmap, orientation)

          // Handle cancellation after EXIF correction
          if (isCancelled) {
            bitmap.recycle()
            result.error("CANCELLED", "Compression cancelled by user", null)
            return
          }
          val resizedBitmap = resizeBitmap(correctedBitmap, targetWidth)

          // Compress the image and convert it to a byte array
          val compressedBytes = bitmapToByteArray(resizedBitmap, compressionQuality)
          if (compressedBytes == null) {
            // Return the original image if compression fails or when compressed image
            // is larger than original image
            result.success(byteArray)
          } else {
            // Return the compressed image
            result.success(compressedBytes)
          }

          // Clean up resources
          correctedBitmap.recycle()
          resizedBitmap.recycle()
          bitmap.recycle()

        } catch (e: Exception) {
          // Handle any errors during image processing
          result.error(
            "DECODE_ERROR",
            "Error during image processing: ${e.message}",
            null
          )
        }
      }
    } else if (call.method == Constants.CANCEL_COMPRESSION_METHOD_NAME) {
      // Handle cancellation request
      isCancelled = true
      result.success(null)
      isCancelled = false
    } else {
      // Handle unimplemented methods
      result.notImplemented()
    }
  }

  // Called when the plugin is detached from the Flutter engine
  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  // Calculate the sampling size for image decoding based on target width or quality
  private fun calculateInSampleSize(
    options: BitmapFactory.Options,
    reqWidth: Int?,
    imageQuality: ImageQuality = ImageQuality.MEDIUM,
    compressionQuality: Int?,
  ): Int {
    val (width: Int, height: Int) = options.run { outWidth to outHeight }
    var inSampleSize = 1
    if (reqWidth != null) {
      if (width > reqWidth) {
        val factor = imageQuality.sampleSize
        val adjustedWidth: Int = width / factor
        while (adjustedWidth / inSampleSize >= reqWidth) {
          inSampleSize *= 2
        }
      }
    } else {
      val quality = compressionQuality ?: 80
      val sampleSize = (100 - quality) / 100
      inSampleSize = if (sampleSize < 2) 2 else sampleSize
    }
    return inSampleSize
  }

  // Compress a Bitmap into a byte array
  private fun bitmapToByteArray(bitmap: Bitmap, compressionQuality: Int? = 80): ByteArray? {
    val quality = compressionQuality ?: 80
    val stream = ByteArrayOutputStream()
    bitmap.compress(Bitmap.CompressFormat.JPEG, quality, stream)
    var outputImageSize = stream.toByteArray().size

    //  To avoid increasing the size of an already compressed image, compare
    //  input and output sizes, and use lower compression quality if needed.
    if (outputImageSize > inputImageSize) {
        var updatedCompQuality = quality;
        while (outputImageSize > inputImageSize && updatedCompQuality >= 10) {
          bitmap.compress(Bitmap.CompressFormat.JPEG, updatedCompQuality, stream)
          updatedCompQuality = updatedCompQuality - 10;
          outputImageSize = stream.toByteArray().size;
        }
        if (updatedCompQuality >= 10) {
          return stream.toByteArray()
        } else {
          return null
        }
    }
    return stream.toByteArray()
  }

  // Apply EXIF orientation to a Bitmap
  private fun applyExifOrientation(bitmap: Bitmap, orientation: Int): Bitmap {
    val matrix = Matrix()
    when (orientation) {
      ExifInterface.ORIENTATION_ROTATE_90 -> matrix.postRotate(90f)
      ExifInterface.ORIENTATION_ROTATE_180 -> matrix.postRotate(180f)
      ExifInterface.ORIENTATION_ROTATE_270 -> matrix.postRotate(270f)
      ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> matrix.postScale(-1f, 1f)
      ExifInterface.ORIENTATION_FLIP_VERTICAL -> matrix.postScale(1f, -1f)
    }
    return Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
  }

  private fun resizeBitmap(bitmap: Bitmap, targetWidth: Int?): Bitmap {
    if (targetWidth == null || bitmap.width <= targetWidth) {
      return bitmap
    }
    val scale = targetWidth.toFloat() / bitmap.width
    val targetHeight = (bitmap.height * scale).toInt()
    return Bitmap.createScaledBitmap(bitmap, targetWidth, targetHeight, true)
  }
}
