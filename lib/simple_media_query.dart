/// A Flutter plugin to browse and query local media files including audio, video, documents, and folders from device storage with filtering and sorting capabilities.
library media_browser;

// Export all public APIs
export 'src/domain/entities/media_permission.dart';
export 'src/domain/entities/media_error.dart';
export 'src/models/audio_model.dart';
export 'src/models/video_model.dart';
export 'src/models/document_model.dart';
export 'src/models/folder_model.dart';
export 'src/models/artwork_model.dart';
export 'src/models/query_options.dart';
export 'src/enums/media_filter.dart' hide MediaType;
export 'src/enums/sort_type.dart';
export 'src/utils/timeout_utils.dart';

import 'src/domain/entities/media_permission.dart';
import 'src/domain/entities/media_error.dart';
import 'src/domain/repositories/media_repository.dart';
import 'src/domain/usecases/check_permissions_usecase.dart';
import 'src/domain/usecases/query_media_usecase.dart';
import 'src/data/repositories/media_repository_impl.dart';
import 'src/data/datasources/method_channel_datasource.dart';
import 'src/models/audio_model.dart';
import 'src/models/video_model.dart';
import 'src/models/document_model.dart';
import 'src/models/folder_model.dart';
import 'src/models/artwork_model.dart';
import 'src/models/query_options.dart';

/// The main class for querying media files from device storage
/// Uses clean architecture with proper error handling and permission management
class SimpleMediaQuery {
  late final MediaRepository _repository;
  late final CheckPermissionsUseCase _checkPermissionsUseCase;
  late final QueryMediaUseCase _queryMediaUseCase;

  /// Initialize the plugin with clean architecture
  SimpleMediaQuery() {
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
      {QueryOptions? options}) async {
    return await _queryMediaUseCase.queryFoldersFromPath(path,
        options: options);
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
}
