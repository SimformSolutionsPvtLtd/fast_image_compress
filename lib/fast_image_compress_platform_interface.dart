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
}
