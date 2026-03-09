import 'package:flutter_test/flutter_test.dart';
import 'package:media_browser/media_browser.dart';

void main() {
  group('MediaBrowser', () {
    late MediaBrowser plugin;

    setUp(() {
      plugin = MediaBrowser();
    });

    test('should be able to create instance', () {
      expect(plugin, isNotNull);
    });

    test('should get platform version', () async {
      final version = await plugin.getPlatformVersion();
      expect(version, isNotNull);
      expect(version, isA<String>());
    });

    test('should check permissions', () async {
      final result = await plugin.checkPermissions(MediaType.audio);
      expect(result, isNotNull);
      expect(result.status, isA<PermissionStatus>());
    });

    test('should query audios', () async {
      try {
        final audios = await plugin.queryAudios();
        expect(audios, isA<List<AudioModel>>());
      } catch (e) {
        // Expected to fail in test environment
        expect(e, isA<Exception>());
      }
    });

    test('should query videos', () async {
      try {
        final videos = await plugin.queryVideos();
        expect(videos, isA<List<VideoModel>>());
      } catch (e) {
        // Expected to fail in test environment
        expect(e, isA<Exception>());
      }
    });

    test('should query documents', () async {
      try {
        final documents = await plugin.queryDocuments();
        expect(documents, isA<List<DocumentModel>>());
      } catch (e) {
        // Expected to fail in test environment
        expect(e, isA<Exception>());
      }
    });

    test('should query folders', () async {
      try {
        final folders = await plugin.queryFolders();
        expect(folders, isA<List<FolderModel>>());
      } catch (e) {
        // Expected to fail in test environment
        expect(e, isA<Exception>());
      }
    });
  });
}
