
import 'fast_image_compress_platform_interface.dart';

class FastImageCompress {
  Future<String?> getPlatformVersion() {
    return FastImageCompressPlatform.instance.getPlatformVersion();
  }
}
