import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_browser/media_browser.dart';

void main() {
  const MethodChannel channel = MethodChannel('media_browser');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'getPlatformVersion':
            return '42';
          case 'checkPermissions':
            return {
              'status': 'granted',
              'message': 'All permissions granted',
              'missingPermissions': <Map<String, dynamic>>[],
            };
          case 'queryAudios':
            return <Map<String, dynamic>>[];
          case 'queryVideos':
            return <Map<String, dynamic>>[];
          case 'queryDocuments':
            return <Map<String, dynamic>>[];
          case 'queryFolders':
            return <Map<String, dynamic>>[];
          case 'queryAlbums':
            return <Map<String, dynamic>>[];
          case 'queryArtists':
            return <Map<String, dynamic>>[];
          case 'queryGenres':
            return <Map<String, dynamic>>[];
          case 'queryArtwork':
            return {
              'id': 0,
              'data': null,
              'format': 'jpeg',
              'size': 'medium',
              'is_available': false,
              'error': 'Artwork not available',
            };
          case 'clearCachedArtworks':
            return null;
          case 'scanMedia':
            return null;
          case 'getDeviceInfo':
            return {
              'platform': 'test',
              'version': '1.0.0',
              'model': 'Test Device',
              'manufacturer': 'Test',
              'brand': 'Test',
            };
          default:
            throw PlatformException(
              code: 'Unimplemented',
              details:
                  'media_browser for test doesn\'t implement \'${methodCall.method}\'',
            );
        }
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('MediaBrowser Method Channel', () {
    late MediaBrowser plugin;

    setUp(() {
      plugin = MediaBrowser();
    });

    test('should get platform version', () async {
      final version = await plugin.getPlatformVersion();
      expect(version, equals('42'));
    });

    test('should check permissions', () async {
      final result = await plugin.checkPermissions(MediaType.audio);
      expect(result.status, equals(PermissionStatus.granted));
      expect(result.message, equals('All permissions granted'));
      expect(result.missingPermissions, isEmpty);
    });

    test('should query audios', () async {
      final audios = await plugin.queryAudios();
      expect(audios, isEmpty);
    });

    test('should query videos', () async {
      final videos = await plugin.queryVideos();
      expect(videos, isEmpty);
    });

    test('should query documents', () async {
      final documents = await plugin.queryDocuments();
      expect(documents, isEmpty);
    });

    test('should query folders', () async {
      final folders = await plugin.queryFolders();
      expect(folders, isEmpty);
    });

    test('should query albums', () async {
      final albums = await plugin.queryAlbums();
      expect(albums, isEmpty);
    });

    test('should query artists', () async {
      final artists = await plugin.queryArtists();
      expect(artists, isEmpty);
    });

    test('should query genres', () async {
      final genres = await plugin.queryGenres();
      expect(genres, isEmpty);
    });

    test('should query artwork', () async {
      final artwork = await plugin.queryArtwork(1, ArtworkType.audio);
      expect(artwork.id, equals(0));
      expect(artwork.isAvailable, equals(false));
      expect(artwork.error, equals('Artwork not available'));
    });

    test('should clear cached artworks', () async {
      await plugin.clearCachedArtworks();
      // Should not throw
    });

    test('should scan media', () async {
      await plugin.scanMedia('/test/path');
      // Should not throw
    });

    test('should get device info', () async {
      final deviceInfo = await plugin.getDeviceInfo();
      expect(deviceInfo['platform'], equals('test'));
      expect(deviceInfo['version'], equals('1.0.0'));
      expect(deviceInfo['model'], equals('Test Device'));
    });
  });
}
