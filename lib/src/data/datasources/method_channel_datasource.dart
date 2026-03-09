import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:media_browser/media_browser.dart';
import 'media_datasource.dart';

/// Method channel data source implementation with comprehensive timeout handling
class MethodChannelDataSource implements MediaDataSource {
  static const MethodChannel _channel = MethodChannel('media_browser');
  static const EventChannel _eventChannel =
      EventChannel('media_browser/permission_changes');

  /// Helper method to execute method channel calls with timeout
  Future<T> _executeWithTimeout<T>(
    String method, {
    dynamic arguments,
    required String operationType,
    required String operationName,
    T Function(dynamic result)? resultParser,
  }) async {
    return await TimeoutUtils.executeWithTimeout(
      () async {
        try {
          final result = await _channel.invokeMethod(method, arguments);

          // Debug logging for permission methods
          if (method == 'checkPermissions' || method == 'requestPermissions') {
            if (kDebugMode) {
              print(
                  '🔍 MethodChannel: $method result type: ${result.runtimeType}');
              print('🔍 MethodChannel: $method result: $result');
            }
          }

          if (resultParser != null) {
            return resultParser(result);
          }

          if (result == null) {
            throw MediaErrorFactory.platformError(
              platform: Platform.operatingSystem,
              message: 'Platform method $method returned null result',
              code: 'NULL_RESULT',
            );
          }

          return result as T;
        } on PlatformException catch (e) {
          throw MediaErrorFactory.platformError(
            platform: Platform.operatingSystem,
            message: 'Platform exception during $operationName: ${e.message}',
            nativeError: e.details?.toString(),
            code: e.code,
          );
        } catch (e) {
          if (e is MediaError) {
            rethrow;
          }
          throw MediaErrorFactory.platformError(
            platform: Platform.operatingSystem,
            message: 'Failed to execute $operationName: ${e.toString()}',
            code: '${operationType.toUpperCase()}_FAILED',
          );
        }
      },
      timeout: TimeoutUtils.getTimeoutForOperation(operationType),
      operationName: operationName,
    );
  }

  @override
  Future<PermissionResult> checkPermissions(MediaType mediaType) async {
    return await _executeWithTimeout<PermissionResult>(
      'checkPermissions',
      arguments: {'mediaType': mediaType.toString()},
      operationType: 'permission_check',
      operationName: 'checkPermissions',
      resultParser: (result) {
        if (result == null) {
          throw MediaErrorFactory.platformError(
            platform: Platform.operatingSystem,
            message: 'Permission check returned null result',
            code: 'PERMISSION_CHECK_NULL',
          );
        }
        return _parsePermissionResult(Map<String, dynamic>.from(result));
      },
    );
  }

  @override
  Future<PermissionResult> requestPermissions(MediaType mediaType) async {
    return await _executeWithTimeout<PermissionResult>(
      'requestPermissions',
      arguments: {'mediaType': mediaType.toString()},
      operationType: 'permission_request',
      operationName: 'requestPermissions',
      resultParser: (result) {
        if (result == null) {
          throw MediaErrorFactory.platformError(
            platform: Platform.operatingSystem,
            message: 'Permission request returned null result',
            code: 'PERMISSION_REQUEST_NULL',
          );
        }
        return _parsePermissionResult(Map<String, dynamic>.from(result));
      },
    );
  }

  @override
  Future<List<AudioModel>> queryAudios({AudioQueryOptions? options}) async {
    return await _executeWithTimeout<List<AudioModel>>(
      'queryAudios',
      arguments: options?.toMap(),
      operationType: 'query_audios',
      operationName: 'queryAudios',
      resultParser: (result) {
        final List<dynamic> audioList =
            result != null ? List<dynamic>.from(result) : [];
        return audioList
            .map((item) => AudioModel.fromMap(Map<String, dynamic>.from(item)))
            .toList();
      },
    );
  }

  @override
  Future<List<AudioModel>> queryAudiosFromAlbum(int albumId,
      {AudioQueryOptions? options}) async {
    return await _executeWithTimeout<List<AudioModel>>(
      'queryAudiosFromAlbum',
      arguments: {
        'albumId': albumId,
        'options': options?.toMap(),
      },
      operationType: 'query_audios',
      operationName: 'queryAudiosFromAlbum',
      resultParser: (result) {
        final List<dynamic> audioList =
            result != null ? List<dynamic>.from(result) : [];
        return audioList
            .map((item) => AudioModel.fromMap(Map<String, dynamic>.from(item)))
            .toList();
      },
    );
  }

  @override
  Future<List<AudioModel>> queryAudiosFromArtist(int artistId,
      {AudioQueryOptions? options}) async {
    return await _executeWithTimeout<List<AudioModel>>(
      'queryAudiosFromArtist',
      arguments: {
        'artistId': artistId,
        'options': options?.toMap(),
      },
      operationType: 'query_audios',
      operationName: 'queryAudiosFromArtist',
      resultParser: (result) {
        final List<dynamic> audioList =
            result != null ? List<dynamic>.from(result) : [];
        return audioList
            .map((item) => AudioModel.fromMap(Map<String, dynamic>.from(item)))
            .toList();
      },
    );
  }

  @override
  Future<List<AudioModel>> queryAudiosFromGenre(int genreId,
      {AudioQueryOptions? options}) async {
    return await _executeWithTimeout<List<AudioModel>>(
      'queryAudiosFromGenre',
      arguments: {
        'genreId': genreId,
        'options': options?.toMap(),
      },
      operationType: 'query_audios',
      operationName: 'queryAudiosFromGenre',
      resultParser: (result) {
        final List<dynamic> audioList =
            result != null ? List<dynamic>.from(result) : [];
        return audioList
            .map((item) => AudioModel.fromMap(Map<String, dynamic>.from(item)))
            .toList();
      },
    );
  }

  @override
  Future<List<AudioModel>> queryAudiosFromPath(String path,
      {AudioQueryOptions? options}) async {
    return await _executeWithTimeout<List<AudioModel>>(
      'queryAudiosFromPath',
      arguments: {
        'path': path,
        'options': options?.toMap(),
      },
      operationType: 'query_audios',
      operationName: 'queryAudiosFromPath',
      resultParser: (result) {
        final List<dynamic> audioList =
            result != null ? List<dynamic>.from(result) : [];
        return audioList
            .map((item) => AudioModel.fromMap(Map<String, dynamic>.from(item)))
            .toList();
      },
    );
  }

  @override
  Future<List<VideoModel>> queryVideos({VideoQueryOptions? options}) async {
    return await _executeWithTimeout<List<VideoModel>>(
      'queryVideos',
      arguments: options?.toMap(),
      operationType: 'query_videos',
      operationName: 'queryVideos',
      resultParser: (result) {
        final List<dynamic> videoList =
            result != null ? List<dynamic>.from(result) : [];
        return videoList
            .map((item) => VideoModel.fromMap(Map<String, dynamic>.from(item)))
            .toList();
      },
    );
  }

  @override
  Future<List<VideoModel>> queryVideosFromPath(String path,
      {VideoQueryOptions? options}) async {
    return await _executeWithTimeout<List<VideoModel>>(
      'queryVideosFromPath',
      arguments: {
        'path': path,
        'options': options?.toMap(),
      },
      operationType: 'query_videos',
      operationName: 'queryVideosFromPath',
      resultParser: (result) {
        final List<dynamic> videoList =
            result != null ? List<dynamic>.from(result) : [];
        return videoList
            .map((item) => VideoModel.fromMap(Map<String, dynamic>.from(item)))
            .toList();
      },
    );
  }

  @override
  Future<List<DocumentModel>> queryDocuments({QueryOptions? options}) async {
    return await _executeWithTimeout<List<DocumentModel>>(
      'queryDocuments',
      arguments: options?.toMap(),
      operationType: 'query_documents',
      operationName: 'queryDocuments',
      resultParser: (result) {
        final List<dynamic> documentList =
            result != null ? List<dynamic>.from(result) : [];
        return documentList
            .map((item) =>
                DocumentModel.fromMap(Map<String, dynamic>.from(item)))
            .toList();
      },
    );
  }

  @override
  Future<List<DocumentModel>> queryDocumentsFromPath(String path,
      {QueryOptions? options}) async {
    return await _executeWithTimeout<List<DocumentModel>>(
      'queryDocumentsFromPath',
      arguments: {
        'path': path,
        'options': options?.toMap(),
      },
      operationType: 'query_documents',
      operationName: 'queryDocumentsFromPath',
      resultParser: (result) {
        final List<dynamic> documentList =
            result != null ? List<dynamic>.from(result) : [];
        return documentList
            .map((item) =>
                DocumentModel.fromMap(Map<String, dynamic>.from(item)))
            .toList();
      },
    );
  }

  @override
  Future<List<FolderModel>> queryFolders({QueryOptions? options}) async {
    return await _executeWithTimeout<List<FolderModel>>(
      'queryFolders',
      arguments: options?.toMap(),
      operationType: 'query_folders',
      operationName: 'queryFolders',
      resultParser: (result) {
        final List<dynamic> folderList =
            result != null ? List<dynamic>.from(result) : [];
        return folderList
            .map((item) => FolderModel.fromMap(Map<String, dynamic>.from(item)))
            .toList();
      },
    );
  }

  @override
  Future<List<FolderModel>> queryFoldersFromPath(String path,
      {QueryOptions? options,
      FolderBrowsingMode browsingMode = FolderBrowsingMode.all}) async {
    return await _executeWithTimeout<List<FolderModel>>(
      'queryFoldersFromPath',
      arguments: {
        'path': path,
        'options': options?.toMap(),
      },
      operationType: 'query_folders',
      operationName: 'queryFoldersFromPath',
      resultParser: (result) {
        final List<dynamic> folderList =
            result != null ? List<dynamic>.from(result) : [];
        return folderList
            .map((item) => FolderModel.fromMap(Map<String, dynamic>.from(item)))
            .toList();
      },
    );
  }

  @override
  Future<List<Map<String, dynamic>>> queryAlbums(
      {QueryOptions? options}) async {
    return await _executeWithTimeout<List<Map<String, dynamic>>>(
      'queryAlbums',
      arguments: options?.toMap(),
      operationType: 'query_albums',
      operationName: 'queryAlbums',
      resultParser: (result) {
        final List<dynamic> albumList =
            result != null ? List<dynamic>.from(result) : [];
        return albumList
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      },
    );
  }

  @override
  Future<List<Map<String, dynamic>>> queryArtists(
      {QueryOptions? options}) async {
    return await _executeWithTimeout<List<Map<String, dynamic>>>(
      'queryArtists',
      arguments: options?.toMap(),
      operationType: 'query_artists',
      operationName: 'queryArtists',
      resultParser: (result) {
        final List<dynamic> artistList =
            result != null ? List<dynamic>.from(result) : [];
        return artistList
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      },
    );
  }

  @override
  Future<List<Map<String, dynamic>>> queryGenres(
      {QueryOptions? options}) async {
    return await _executeWithTimeout<List<Map<String, dynamic>>>(
      'queryGenres',
      arguments: options?.toMap(),
      operationType: 'query_genres',
      operationName: 'queryGenres',
      resultParser: (result) {
        final List<dynamic> genreList =
            result != null ? List<dynamic>.from(result) : [];
        return genreList
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      },
    );
  }

  @override
  Future<ArtworkModel> queryArtwork(int id, ArtworkType type,
      {ArtworkSize size = ArtworkSize.medium}) async {
    return await _executeWithTimeout<ArtworkModel>(
      'queryArtwork',
      arguments: {
        'id': id,
        'type': type.toString(),
        'size': size.toString(),
      },
      operationType: 'query_artwork',
      operationName: 'queryArtwork',
      resultParser: (result) {
        if (result == null) {
          throw MediaErrorFactory.artworkError(
            mediaId: id,
            artworkType: type,
            message: 'Artwork query returned null result',
          );
        }
        // Convert Map<Object?, Object?> to Map<String, dynamic>
        final Map<String, dynamic> artworkMap =
            Map<String, dynamic>.from(result);
        return ArtworkModel.fromMap(artworkMap);
      },
    );
  }

  @override
  Future<void> clearCachedArtworks() async {
    await _executeWithTimeout<void>(
      'clearCachedArtworks',
      operationType: 'clear_cache',
      operationName: 'clearCachedArtworks',
    );
  }

  @override
  Future<void> clearScanCache() async {
    await _executeWithTimeout<void>(
      'clearScanCache',
      operationType: 'clear_cache',
      operationName: 'clearScanCache',
    );
  }

  @override
  Future<void> scanMedia(String path) async {
    await _executeWithTimeout<void>(
      'scanMedia',
      arguments: {'path': path},
      operationType: 'scan_media',
      operationName: 'scanMedia',
    );
  }

  @override
  Future<Map<String, dynamic>> getDeviceInfo() async {
    return await _executeWithTimeout<Map<String, dynamic>>(
      'getDeviceInfo',
      operationType: 'device_info',
      operationName: 'getDeviceInfo',
      resultParser: (result) {
        return result != null ? Map<String, dynamic>.from(result) : {};
      },
    );
  }

  @override
  Future<String> getPlatformVersion() async {
    return await _executeWithTimeout<String>(
      'getPlatformVersion',
      operationType: 'platform_version',
      operationName: 'getPlatformVersion',
      resultParser: (result) {
        return result as String? ?? 'Unknown';
      },
    );
  }

  /// Parse permission result from platform response
  PermissionResult _parsePermissionResult(Map<String, dynamic> result) {
    if (kDebugMode) {
      print('🔍 _parsePermissionResult: Input type: ${result.runtimeType}');
      print('🔍 _parsePermissionResult: Input data: $result');
    }

    final statusString = result['status'] as String? ?? 'denied';
    final status = _parsePermissionStatus(statusString);
    final message = result['message'] as String?;
    final missingPermissionsList = result['missingPermissions'] != null
        ? List<dynamic>.from(result['missingPermissions'])
        : [];

    final missingPermissions = missingPermissionsList
        .map((permission) =>
            _parseMediaPermission(Map<String, dynamic>.from(permission)))
        .toList();

    return PermissionResult(
      status: status,
      message: message,
      missingPermissions: missingPermissions,
    );
  }

  /// Parse permission status from string
  PermissionStatus _parsePermissionStatus(String status) {
    switch (status.toLowerCase()) {
      case 'granted':
        return PermissionStatus.granted;
      case 'denied':
        return PermissionStatus.denied;
      case 'permanently_denied':
        return PermissionStatus.permanentlyDenied;
      case 'restricted':
        return PermissionStatus.restricted;
      case 'limited':
        return PermissionStatus.limited;
      case 'provisional':
        return PermissionStatus.provisional;
      case 'notdetermined':
        return PermissionStatus.notDetermined;
      default:
        return PermissionStatus.denied;
    }
  }

  /// Parse media permission from map
  MediaPermission _parseMediaPermission(Map<String, dynamic> permission) {
    return MediaPermission(
      name: permission['name'] as String? ?? '',
      description: permission['description'] as String? ?? '',
      isRequired: permission['isRequired'] as bool? ?? false,
      type: _parsePermissionType(permission['type'] as String? ?? ''),
      status:
          _parsePermissionStatus(permission['status'] as String? ?? 'denied'),
      canRequest: permission['canRequest'] as bool? ?? true,
      shouldShowRationale: permission['shouldShowRationale'] as bool? ?? false,
    );
  }

  /// Parse permission type from string
  PermissionType _parsePermissionType(String type) {
    switch (type.toLowerCase()) {
      case 'storage':
        return PermissionType.storage;
      case 'audio':
        return PermissionType.audio;
      case 'video':
        return PermissionType.video;
      case 'document':
        return PermissionType.document;
      case 'folder':
        return PermissionType.folder;
      case 'media_library':
        return PermissionType.mediaLibrary;
      case 'photo_library':
        return PermissionType.photoLibrary;
      default:
        return PermissionType.storage;
    }
  }

  // Enhanced file system scanning methods

  @override
  Future<List<dynamic>> scanDirectoryRecursively(String path,
      {String fileType = 'all'}) async {
    return await _executeWithTimeout<List<dynamic>>(
      'scanDirectoryRecursively',
      arguments: {
        'path': path,
        'fileType': fileType,
      },
      operationType: 'scan_directory',
      operationName: 'scanDirectoryRecursively',
      resultParser: (result) {
        // Return the raw result as a list of dynamic items
        return result != null ? List<dynamic>.from(result) : [];
      },
    );
  }

  @override
  Future<List<dynamic>> scanCommonDirectories({String fileType = 'all'}) async {
    return await _executeWithTimeout<List<dynamic>>(
      'scanCommonDirectories',
      arguments: {
        'fileType': fileType,
      },
      operationType: 'scan_common_directories',
      operationName: 'scanCommonDirectories',
      resultParser: (result) {
        // Return the raw result as a list of dynamic items
        return result != null ? List<dynamic>.from(result) : [];
      },
    );
  }

  @override
  Future<List<String>> getCommonDirectories() async {
    return await _executeWithTimeout<List<String>>(
      'getCommonDirectories',
      arguments: {},
      operationType: 'get_common_directories',
      operationName: 'getCommonDirectories',
      resultParser: (result) {
        final List<dynamic> dirList =
            result != null ? List<dynamic>.from(result) : [];
        return dirList.map((dir) => dir.toString()).toList();
      },
    );
  }

  @override
  Stream<PermissionChangeEvent> listenToPermissionChanges() {
    return _eventChannel.receiveBroadcastStream().map((event) {
      try {
        if (event is Map<String, dynamic>) {
          return PermissionChangeEvent.fromMap(event);
        } else {
          throw MediaErrorFactory.platformError(
            platform: Platform.operatingSystem,
            message:
                'Invalid permission change event format: ${event.runtimeType}',
            code: 'INVALID_PERMISSION_EVENT',
          );
        }
      } catch (e) {
        if (e is MediaError) {
          rethrow;
        }
        throw MediaErrorFactory.platformError(
          platform: Platform.operatingSystem,
          message: 'Failed to parse permission change event: ${e.toString()}',
          code: 'PERMISSION_EVENT_PARSE_FAILED',
        );
      }
    }).handleError((error) {
      if (error is PlatformException) {
        throw MediaErrorFactory.platformError(
          platform: Platform.operatingSystem,
          message:
              'Platform exception during permission change listening: ${error.message}',
          nativeError: error.details?.toString(),
          code: error.code,
        );
      } else if (error is MediaError) {
        throw error;
      } else {
        throw MediaErrorFactory.platformError(
          platform: Platform.operatingSystem,
          message:
              'Failed to listen to permission changes: ${error.toString()}',
          code: 'PERMISSION_LISTEN_FAILED',
        );
      }
    });
  }

  @override
  Future<Map<String, dynamic>> debugArtworkAvailability() async {
    return await _executeWithTimeout<Map<String, dynamic>>(
      'debugArtworkAvailability',
      operationType: 'debug_artwork',
      operationName: 'debugArtworkAvailability',
      resultParser: (result) {
        return result != null ? Map<String, dynamic>.from(result) : {};
      },
    );
  }

  // MARK: - Media Extraction Methods (iOS & macOS)

  @override
  Future<Map<String, dynamic>> exportTrack(String trackId) async {
    return await _executeWithTimeout<Map<String, dynamic>>(
      'exportTrack',
      arguments: {'trackId': trackId},
      operationType: 'export_track',
      operationName: 'exportTrack',
      resultParser: (result) {
        return result != null ? Map<String, dynamic>.from(result) : {};
      },
    );
  }

  @override
  Future<Map<String, dynamic>> exportTrackWithArtwork(String trackId) async {
    return await _executeWithTimeout<Map<String, dynamic>>(
      'exportTrackWithArtwork',
      arguments: {'trackId': trackId},
      operationType: 'export_track_with_artwork',
      operationName: 'exportTrackWithArtwork',
      resultParser: (result) {
        return result != null ? Map<String, dynamic>.from(result) : {};
      },
    );
  }

  @override
  Future<Map<String, dynamic>> extractArtwork(String trackId) async {
    return await _executeWithTimeout<Map<String, dynamic>>(
      'extractArtwork',
      arguments: {'trackId': trackId},
      operationType: 'extract_artwork',
      operationName: 'extractArtwork',
      resultParser: (result) {
        return result != null ? Map<String, dynamic>.from(result) : {};
      },
    );
  }

  @override
  Future<bool> canExportTrack() async {
    return await _executeWithTimeout<bool>(
      'canExportTrack',
      operationType: 'can_export_track',
      operationName: 'canExportTrack',
      resultParser: (result) {
        return result as bool? ?? false;
      },
    );
  }

  @override
  Future<Map<String, dynamic>> getTrackExtension(String trackPath) async {
    return await _executeWithTimeout<Map<String, dynamic>>(
      'getTrackExtension',
      arguments: {'trackPath': trackPath},
      operationType: 'get_track_extension',
      operationName: 'getTrackExtension',
      resultParser: (result) {
        return result != null ? Map<String, dynamic>.from(result) : {};
      },
    );
  }
}
