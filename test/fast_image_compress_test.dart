import 'dart:typed_data';

import 'package:fast_image_compress/fast_image_compress.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFastImageCompressPlatform
    with MockPlatformInterfaceMixin
    implements FastImageCompressPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<Uint8List?> compressImage(
    Uint8List imageData,
    int targetWidth,
    int compressionQuality,
    String imageQuality,
  ) {
    // Simulate resizing by returning a mocked Uint8List (could be the same or modified data).
    return Future.value(Uint8List.fromList([1, 2, 3])); // Example mock data
  }
}

void main() {
  final FastImageCompressPlatform initialPlatform =
      FastImageCompressPlatform.instance;

  test('$MethodChannelFastImageCompress is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFastImageCompress>());
  });

  test('getPlatformVersion', () async {
    FastImageCompress fastImageCompressPlugin = FastImageCompress();
    MockFastImageCompressPlatform fakePlatform =
        MockFastImageCompressPlatform();
    FastImageCompressPlatform.instance = fakePlatform;

    expect(await fastImageCompressPlugin.getPlatformVersion(), '42');
  });
}
