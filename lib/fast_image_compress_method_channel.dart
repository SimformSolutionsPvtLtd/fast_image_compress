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
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
