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

import Flutter
import UIKit

// Define constants used throughout the plugin
enum Constants{
    static let methodChannelName = "com.simform.fast_image_compress/compression"
    static let compressionMethodName = "compressImage"
    static let cancelCompressionMethodName = "cancelCompression"
    static let imageData = "imageData"
    static let targetWidth = "targetWidth"
    static let compressionQuality = "compressionQuality"
    static let imageQuality = "imageQuality"
    static let high = "high"
    static let low = "low"
    static let medium = "medium"
}

// Enum to represent image quality levels and their associated downscaling factors
enum ImageQuality {
    case low, medium, high

    var sampleFactor: CGFloat {
        switch self {
        case .low: return 4.0
        case .medium: return 2.0
        case .high: return 1.0
        }
    }
}

// Main plugin class that implements the FlutterPlugin protocol
public class FastImageCompressPlugin: NSObject, FlutterPlugin {
    private var isCancelled = false // Flag to track cancellation of ongoing compression

    // Registers the plugin with the Flutter framework
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: Constants.methodChannelName, binaryMessenger: registrar.messenger())
        let instance = FastImageCompressPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    // Handles method calls from Flutter
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case Constants.compressionMethodName:
            handleCompression(call: call, result: result) // Handle image compression
        case Constants.cancelCompressionMethodName:
            handleCancellation(result: result) // Handle cancellation of compression
        default:
            result(FlutterMethodNotImplemented) // Return not implemented for unknown methods
        }
    }

    // MARK: - Handlers

    // Handles the image compression logic
    private func handleCompression(call: FlutterMethodCall, result: @escaping FlutterResult) {
        // Validate and extract arguments from the method call
        guard let args = call.arguments as? [String: Any],
              let imageData = args[Constants.imageData] as? FlutterStandardTypedData,
              let imageQualityInString = args[Constants.imageQuality] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments provided", details: nil))
            return
        }

        // Optional arguments for compression quality and target width
        let compressionQuality = args[Constants.compressionQuality] as? Int
        let targetWidth = args[Constants.targetWidth] as? Int

        // Determine the image quality based on the provided string
        let imageQuality: ImageQuality = {
            switch imageQualityInString {
            case Constants.high: return .high
            case Constants.low: return .low
            default: return .medium
            }
        }()

        isCancelled = false // Reset cancellation flag
        // Start resizing and compressing the image
        resizeImage(imageData: imageData.data, targetWidth: targetWidth, compressionQuality: compressionQuality, imageQuality: imageQuality, result: result)
    }

    // Handles the cancellation of image compression
    private func handleCancellation(result: @escaping FlutterResult) {
        isCancelled = true // Set the cancellation flag
        result(nil) // Acknowledge the cancellation to Flutter
    }

    // MARK: - Image Processing

    // Resizes the image and compresses it based on the provided parameters
    private func resizeImage(imageData: Data, targetWidth: Int?, compressionQuality: Int? = 80, imageQuality: ImageQuality, result: FlutterResult) {
        // Decode the image data into a UIImage
        guard let image = UIImage(data: imageData) else {
            result(FlutterError(code: "INVALID_IMAGE", message: "Unable to decode image data", details: nil))
            return
        }

        // Resize the image
        let resizedImage = createResizedImage(image: image, targetWidth: targetWidth, imageQuality: imageQuality)
        guard let finalImage = resizedImage else {
            result(FlutterError(code: "IMAGE_PROCESSING_FAILED", message: "Unable to resize image", details: nil))
            return
        }

        // Compress the resized image
        compressImage(finalImage: finalImage, imageData: imageData, compressionQuality: compressionQuality, result: result)
    }

    // Resizes the image to the target width and quality
    private func createResizedImage(image: UIImage, targetWidth: Int?, imageQuality: ImageQuality) -> UIImage? {
        let factor = imageQuality.sampleFactor // Get the downscaling factor based on quality
        var adjustedWidth = image.size.width / factor

        // Adjust the width if a specific target width is provided
        if let targetWidth = targetWidth, targetWidth < Int(image.size.width) {
            adjustedWidth = CGFloat(targetWidth)
        }

        // Calculate the scale and adjusted height
        let scale = adjustedWidth / image.size.width
        let adjustedHeight = image.size.height * scale

        // Perform the resizing operation
        UIGraphicsBeginImageContext(CGSize(width: adjustedWidth, height: adjustedHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: adjustedWidth, height: adjustedHeight))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage
    }

    // Compresses the resized image and returns the compressed data
    private func compressImage(finalImage: UIImage, imageData: Data, compressionQuality: Int?, result: FlutterResult) {
        var quality = Double(compressionQuality ?? 80) / 100.0 // Default quality is 80%
        var compressedData = finalImage.jpegData(compressionQuality: quality)

        let inputImageSize = imageData.count
        var outputImageSize = compressedData?.count ?? Int.max

        //  To avoid increasing the size of an already compressed image, compare
        //  input and output sizes, and use lower compression quality if needed.
        if outputImageSize > inputImageSize {
            compressedData = performIterativeCompression(finalImage: finalImage, inputImageSize: inputImageSize, initialQuality: quality)
        }

        // Return the compressed data or an error if compression failed
        if let compressedData = compressedData {
            result(FlutterStandardTypedData(bytes: compressedData))
        } else {
            result(FlutterError(code: "COMPRESSION_FAILED", message: "Failed to compress image", details: nil))
        }
    }

    // Performs iterative compression to reduce the image size
    private func performIterativeCompression(finalImage: UIImage, inputImageSize: Int, initialQuality: Double) -> Data? {
        var quality = initialQuality
        var updatedCompQuality = Int(quality * 100)
        var compressedData: Data?

        // Reduce quality in steps of 10 until the size is acceptable or the minimum quality is reached
        repeat {
            if isCancelled { return nil } // Exit if the operation is cancelled

            updatedCompQuality -= 10
            quality = Double(updatedCompQuality) / 100.0
            compressedData = finalImage.jpegData(compressionQuality: quality)
        } while (compressedData?.count ?? Int.max) > inputImageSize && updatedCompQuality >= 10

        return updatedCompQuality < 10 ? nil : compressedData
    }
}
