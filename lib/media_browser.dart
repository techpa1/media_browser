/// A Flutter plugin to browse and query local media files including audio, video, documents, and folders from device storage with filtering and sorting capabilities.
library media_browser;

// Export all public APIs
export 'src/domain/entities/media_permission.dart';
export 'src/domain/entities/media_error.dart';
export 'src/domain/entities/permission_change_event.dart';
export 'src/models/audio_model.dart';
export 'src/models/video_model.dart';
export 'src/models/document_model.dart';
export 'src/models/folder_model.dart';
export 'src/models/artwork_model.dart';
export 'src/models/query_options.dart';
export 'src/enums/media_filter.dart' hide MediaType;
export 'src/enums/sort_type.dart';
export 'src/enums/folder_browsing_mode.dart';
export 'src/utils/timeout_utils.dart';
export 'src/utils/permission_data_manager.dart';

import 'package:media_browser/media_browser.dart';
import 'dart:async';

import 'src/domain/repositories/media_repository.dart';
import 'src/domain/usecases/check_permissions_usecase.dart';
import 'src/domain/usecases/query_media_usecase.dart';
import 'src/data/repositories/media_repository_impl.dart';
import 'src/data/datasources/method_channel_datasource.dart';

/// The main class for browsing and querying media files from device storage
/// Uses clean architecture with proper error handling and permission management
class MediaBrowser {
  late final MediaRepository _repository;
  late final CheckPermissionsUseCase _checkPermissionsUseCase;
  late final QueryMediaUseCase _queryMediaUseCase;

  /// Initialize the plugin with clean architecture
  MediaBrowser() {
    final dataSource = MethodChannelDataSource();
    _repository = MediaRepositoryImpl(dataSource);
    _checkPermissionsUseCase = CheckPermissionsUseCase(_repository);
    _queryMediaUseCase =
        QueryMediaUseCase(_repository, _checkPermissionsUseCase);
  }

  /// Get the platform version
  Future<String> getPlatformVersion() async {
    try {
      return await _repository.getPlatformVersion();
    } catch (e) {
      if (e is MediaError) {
        rethrow;
      }
      throw MediaErrorFactory.platformError(
        platform: 'unknown',
        message: 'Failed to get platform version: ${e.toString()}',
        code: 'PLATFORM_VERSION_FAILED',
      );
    }
  }

  /// Check if required permissions are granted for specific media type
  Future<PermissionResult> checkPermissions(MediaType mediaType) async {
    return await _checkPermissionsUseCase.call(mediaType);
  }

  /// Request permissions for specific media type
  Future<PermissionResult> requestPermissions(MediaType mediaType) async {
    try {
      return await _repository.requestPermissions(mediaType);
    } catch (e) {
      if (e is MediaError) {
        rethrow;
      }
      throw MediaErrorFactory.platformError(
        platform: 'unknown',
        message: 'Failed to request permissions: ${e.toString()}',
        code: 'PERMISSION_REQUEST_FAILED',
      );
    }
  }

  /// Check if all required permissions are granted (legacy method)
  Future<bool> hasPermission([MediaType mediaType = MediaType.all]) async {
    try {
      return await _checkPermissionsUseCase
          .areAllRequiredPermissionsGranted(mediaType);
    } catch (e) {
      return false;
    }
  }

  /// Request storage permission (legacy method)
  Future<bool> requestPermission([MediaType mediaType = MediaType.all]) async {
    try {
      final result = await requestPermissions(mediaType);
      return result.isGranted;
    } catch (e) {
      return false;
    }
  }

  /// Query audio files with permission checking and error handling
  Future<List<AudioModel>> queryAudios({AudioQueryOptions? options}) async {
    return await _queryMediaUseCase.queryAudios(options: options);
  }

  /// Query audio files from a specific album
  Future<List<AudioModel>> queryAudiosFromAlbum(int albumId,
      {AudioQueryOptions? options}) async {
    return await _queryMediaUseCase.queryAudiosFromAlbum(albumId,
        options: options);
  }

  /// Query audio files from a specific artist
  Future<List<AudioModel>> queryAudiosFromArtist(int artistId,
      {AudioQueryOptions? options}) async {
    return await _queryMediaUseCase.queryAudiosFromArtist(artistId,
        options: options);
  }

  /// Query audio files from a specific genre
  Future<List<AudioModel>> queryAudiosFromGenre(int genreId,
      {AudioQueryOptions? options}) async {
    return await _queryMediaUseCase.queryAudiosFromGenre(genreId,
        options: options);
  }

  /// Query audio files from a specific path
  Future<List<AudioModel>> queryAudiosFromPath(String path,
      {AudioQueryOptions? options}) async {
    return await _queryMediaUseCase.queryAudiosFromPath(path, options: options);
  }

  /// Query video files with permission checking and error handling
  Future<List<VideoModel>> queryVideos({VideoQueryOptions? options}) async {
    return await _queryMediaUseCase.queryVideos(options: options);
  }

  /// Query video files from a specific path
  Future<List<VideoModel>> queryVideosFromPath(String path,
      {VideoQueryOptions? options}) async {
    return await _queryMediaUseCase.queryVideosFromPath(path, options: options);
  }

  /// Query document files with permission checking and error handling
  Future<List<DocumentModel>> queryDocuments({QueryOptions? options}) async {
    return await _queryMediaUseCase.queryDocuments(options: options);
  }

  /// Query document files from a specific path
  Future<List<DocumentModel>> queryDocumentsFromPath(String path,
      {QueryOptions? options}) async {
    return await _queryMediaUseCase.queryDocumentsFromPath(path,
        options: options);
  }

  /// Query folder/directory information with permission checking and error handling
  Future<List<FolderModel>> queryFolders({QueryOptions? options}) async {
    return await _queryMediaUseCase.queryFolders(options: options);
  }

  /// Query folders from a specific path
  Future<List<dynamic>> queryFoldersFromPath(String path,
      {QueryOptions? options,
      FolderBrowsingMode browsingMode = FolderBrowsingMode.all}) async {
    return await _queryMediaUseCase.queryFoldersFromPath(path,
        options: options, browsingMode: browsingMode);
  }

  /// Query album information
  Future<List<Map<String, dynamic>>> queryAlbums(
      {QueryOptions? options}) async {
    try {
      // Check permissions first
      final permissionResult =
          await _checkPermissionsUseCase.call(MediaType.audio);
      if (!permissionResult.isGranted) {
        throw MediaErrorFactory.permissionDenied(
          missingPermissions: permissionResult.missingPermissions ?? [],
          status: permissionResult.status,
          message: 'Audio permissions not granted: ${permissionResult.message}',
        );
      }

      return await _repository.queryAlbums(options: options);
    } catch (e) {
      if (e is MediaError) {
        rethrow;
      }
      throw MediaErrorFactory.queryError(
        queryType: 'album',
        message: 'Failed to query albums: ${e.toString()}',
      );
    }
  }

  /// Query artist information
  Future<List<Map<String, dynamic>>> queryArtists(
      {QueryOptions? options}) async {
    try {
      // Check permissions first
      final permissionResult =
          await _checkPermissionsUseCase.call(MediaType.audio);
      if (!permissionResult.isGranted) {
        throw MediaErrorFactory.permissionDenied(
          missingPermissions: permissionResult.missingPermissions ?? [],
          status: permissionResult.status,
          message: 'Audio permissions not granted: ${permissionResult.message}',
        );
      }

      return await _repository.queryArtists(options: options);
    } catch (e) {
      if (e is MediaError) {
        rethrow;
      }
      throw MediaErrorFactory.queryError(
        queryType: 'artist',
        message: 'Failed to query artists: ${e.toString()}',
      );
    }
  }

  /// Query genre information
  Future<List<Map<String, dynamic>>> queryGenres(
      {QueryOptions? options}) async {
    try {
      // Check permissions first
      final permissionResult =
          await _checkPermissionsUseCase.call(MediaType.audio);
      if (!permissionResult.isGranted) {
        throw MediaErrorFactory.permissionDenied(
          missingPermissions: permissionResult.missingPermissions ?? [],
          status: permissionResult.status,
          message: 'Audio permissions not granted: ${permissionResult.message}',
        );
      }

      return await _repository.queryGenres(options: options);
    } catch (e) {
      if (e is MediaError) {
        rethrow;
      }
      throw MediaErrorFactory.queryError(
        queryType: 'genre',
        message: 'Failed to query genres: ${e.toString()}',
      );
    }
  }

  /// Query artwork/thumbnail for media
  Future<ArtworkModel> queryArtwork(int id, ArtworkType type,
      {ArtworkSize size = ArtworkSize.medium}) async {
    try {
      return await _repository.queryArtwork(id, type, size: size);
    } catch (e) {
      if (e is MediaError) {
        rethrow;
      }
      throw MediaErrorFactory.artworkError(
        mediaId: id,
        artworkType: type,
        message: 'Failed to query artwork: ${e.toString()}',
      );
    }
  }

  /// Clear cached artworks
  Future<void> clearCachedArtworks() async {
    try {
      await _repository.clearCachedArtworks();
    } catch (e) {
      if (e is MediaError) {
        rethrow;
      }
      throw MediaErrorFactory.platformError(
        platform: 'unknown',
        message: 'Failed to clear cached artworks: ${e.toString()}',
        code: 'CLEAR_CACHE_FAILED',
      );
    }
  }

  /// Clear scan cache to force fresh file system scan
  Future<void> clearScanCache() async {
    try {
      await _repository.clearScanCache();
    } catch (e) {
      if (e is MediaError) {
        rethrow;
      }
      throw MediaErrorFactory.platformError(
        platform: 'unknown',
        message: 'Failed to clear scan cache: ${e.toString()}',
        code: 'CLEAR_SCAN_CACHE_FAILED',
      );
    }
  }

  /// Scan media files in a specific path
  Future<void> scanMedia(String path) async {
    try {
      await _repository.scanMedia(path);
    } catch (e) {
      if (e is MediaError) {
        rethrow;
      }
      throw MediaErrorFactory.storageError(
        message: 'Failed to scan media: ${e.toString()}',
        path: path,
        operation: 'scan',
      );
    }
  }

  /// Get device information
  Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      return await _repository.getDeviceInfo();
    } catch (e) {
      if (e is MediaError) {
        rethrow;
      }
      throw MediaErrorFactory.platformError(
        platform: 'unknown',
        message: 'Failed to get device info: ${e.toString()}',
        code: 'DEVICE_INFO_FAILED',
      );
    }
  }

  /// Get missing required permissions for specific media type
  Future<List<MediaPermission>> getMissingRequiredPermissions(
      MediaType mediaType) async {
    return await _checkPermissionsUseCase
        .getMissingRequiredPermissions(mediaType);
  }

  /// Check if specific permission is granted
  Future<bool> isPermissionGranted(MediaPermission permission) async {
    return await _checkPermissionsUseCase.isPermissionGranted(permission);
  }

  // Enhanced file system scanning methods

  /// Scan directory recursively for files and folders
  Future<List<dynamic>> scanDirectoryRecursively(String path,
      {String fileType = 'all'}) async {
    return await _queryMediaUseCase.scanDirectoryRecursively(path,
        fileType: fileType);
  }

  /// Scan common directories for specific file types
  Future<List<dynamic>> scanCommonDirectories({String fileType = 'all'}) async {
    return await _queryMediaUseCase.scanCommonDirectories(fileType: fileType);
  }

  /// Get list of common directories
  Future<List<String>> getCommonDirectories() async {
    return await _queryMediaUseCase.getCommonDirectories();
  }

  /// Listen for permission changes
  /// Returns a stream that emits permission change events
  /// When permissions are granted, you should reload your data
  /// When permissions are denied, you should clear your data and show an error
  Stream<PermissionChangeEvent> listenToPermissionChanges() {
    return _repository.listenToPermissionChanges();
  }

  /// Debug artwork availability in the media library
  /// Returns statistics about how many items have artwork
  Future<Map<String, dynamic>> debugArtworkAvailability() async {
    try {
      return await _repository.debugArtworkAvailability();
    } catch (e) {
      if (e is MediaError) {
        rethrow;
      }
      throw MediaErrorFactory.platformError(
        platform: 'unknown',
        message: 'Failed to debug artwork availability: ${e.toString()}',
        code: 'DEBUG_ARTWORK_FAILED',
      );
    }
  }

  /// Create a permission data manager to handle permission changes
  /// This helps you manage data based on permission changes for specific media types
  PermissionDataManager createPermissionDataManager() {
    return PermissionDataManager(listenToPermissionChanges());
  }

  // MARK: - Media Extraction Methods (iOS & macOS)

  /// Export a track from the music library to a temporary file
  /// Returns the file path of the exported track
  /// Note: This method is available on iOS and macOS
  Future<Map<String, dynamic>> exportTrack(String trackId) async {
    try {
      return await _repository.exportTrack(trackId);
    } catch (e) {
      if (e is MediaError) {
        rethrow;
      }
      throw MediaErrorFactory.platformError(
        platform: 'ios',
        message: 'Failed to export track: ${e.toString()}',
        code: 'EXPORT_TRACK_FAILED',
      );
    }
  }

  /// Export a track with its artwork from the music library
  /// Returns both the audio file path and artwork file path
  /// Note: This method is available on iOS and macOS
  Future<Map<String, dynamic>> exportTrackWithArtwork(String trackId) async {
    try {
      return await _repository.exportTrackWithArtwork(trackId);
    } catch (e) {
      if (e is MediaError) {
        rethrow;
      }
      throw MediaErrorFactory.platformError(
        platform: 'ios',
        message: 'Failed to export track with artwork: ${e.toString()}',
        code: 'EXPORT_TRACK_WITH_ARTWORK_FAILED',
      );
    }
  }

  /// Extract artwork from a track and save it as a JPEG file
  /// Returns the file path of the extracted artwork
  /// Note: This method is available on iOS and macOS
  Future<Map<String, dynamic>> extractArtwork(String trackId) async {
    try {
      return await _repository.extractArtwork(trackId);
    } catch (e) {
      if (e is MediaError) {
        rethrow;
      }
      throw MediaErrorFactory.platformError(
        platform: 'ios',
        message: 'Failed to extract artwork: ${e.toString()}',
        code: 'EXTRACT_ARTWORK_FAILED',
      );
    }
  }

  /// Check if the app can export tracks from the music library
  /// Returns true if music library access is authorized
  /// Note: This method is available on iOS and macOS
  Future<bool> canExportTrack() async {
    try {
      return await _repository.canExportTrack();
    } catch (e) {
      if (e is MediaError) {
        rethrow;
      }
      throw MediaErrorFactory.platformError(
        platform: 'ios',
        message: 'Failed to check export capability: ${e.toString()}',
        code: 'CAN_EXPORT_TRACK_FAILED',
      );
    }
  }

  /// Get the file extension for a track path
  /// Returns the extension in lowercase
  /// Note: This method is available on iOS and macOS
  Future<Map<String, dynamic>> getTrackExtension(String trackPath) async {
    try {
      return await _repository.getTrackExtension(trackPath);
    } catch (e) {
      if (e is MediaError) {
        rethrow;
      }
      throw MediaErrorFactory.platformError(
        platform: 'ios',
        message: 'Failed to get track extension: ${e.toString()}',
        code: 'GET_TRACK_EXTENSION_FAILED',
      );
    }
  }
}
