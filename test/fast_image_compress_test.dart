import 'package:flutter_test/flutter_test.dart';
import 'package:fast_image_compress/fast_image_compress.dart';
import 'package:fast_image_compress/fast_image_compress_platform_interface.dart';
import 'package:fast_image_compress/fast_image_compress_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFastImageCompressPlatform
    with MockPlatformInterfaceMixin
    implements FastImageCompressPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FastImageCompressPlatform initialPlatform = FastImageCompressPlatform.instance;

  test('$MethodChannelFastImageCompress is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFastImageCompress>());
  });

  test('getPlatformVersion', () async {
    FastImageCompress fastImageCompressPlugin = FastImageCompress();
    MockFastImageCompressPlatform fakePlatform = MockFastImageCompressPlatform();
    FastImageCompressPlatform.instance = fakePlatform;

    expect(await fastImageCompressPlugin.getPlatformVersion(), '42');
  });
}
