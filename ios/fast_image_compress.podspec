#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint fast_image_compress.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'fast_image_compress'
  s.version          = '0.0.1'
  s.summary          = 'A Flutter plugin for fast image compression.'
  s.description      = <<-DESC
 A fast image compression plugin which performs compression on large images in parallel.
                        DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Simform Solutions' => 'developer@simform.com'}
  s.source           = { :http => 'https://github.com/SimformSolutionsPvtLtd/fast_image_compress/tree/master' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'fast_image_compress_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
