#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint media_browser.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'media_browser'
  s.version          = '1.0.0'
  s.summary          = 'A Flutter plugin to browse and query local media files including audio, video, documents, and folders from device storage with filtering and sorting capabilities.'
  s.description      = <<-DESC
A Flutter plugin to browse and query local media files including audio, video, documents, and folders from device storage with filtering and sorting capabilities.
                       DESC
  s.homepage         = 'https://github.com/librewirelesstechnology/media_browser'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Libre Wireless Technology' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
