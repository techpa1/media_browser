import 'dart:io';
import 'dart:async';
import '../datasources/media_datasource.dart';
import '../../domain/repositories/media_repository.dart';
import '../../domain/entities/media_permission.dart';
import '../../domain/entities/media_error.dart';
import '../../domain/entities/permission_change_event.dart';
import '../../models/audio_model.dart';
import '../../models/video_model.dart';
import '../../models/document_model.dart';
import '../../models/folder_model.dart';
import '../../models/artwork_model.dart';
import '../../models/query_options.dart';
import '../../enums/folder_browsing_mode.dart';

/// Implementation of MediaRepository
class MediaRepositoryImpl implements MediaRepository {
  final MediaDataSource _dataSource;

  const MediaRepositoryImpl(this._dataSource);

  @override
  Future<PermissionResult> checkPermissions(MediaType mediaType) async {
    try {
      return await _dataSource.checkPermissions(mediaType);
    } catch (e) {
      throw MediaErrorFactory.platformError(
        platform: Platform.operatingSystem,
        message: 'Failed to check permissions: ${e.toString()}',
        code: 'PERMISSION_CHECK_FAILED',
      );
    }
  }

  @override
  Future<PermissionResult> requestPermissions(MediaType mediaType) async {
    try {
      return await _dataSource.requestPermissions(mediaType);
    } catch (e) {
      throw MediaErrorFactory.platformError(
        platform: Platform.operatingSystem,
        message: 'Failed to request permissions: ${e.toString()}',
        code: 'PERMISSION_REQUEST_FAILED',
      );
    }
  }

  @override
  Future<List<AudioModel>> queryAudios({AudioQueryOptions? options}) async {
    try {
      return await _dataSource.queryAudios(options: options);
    } catch (e) {
      throw MediaErrorFactory.queryError(
        queryType: 'audio',
        message: 'Failed to query audio files: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<AudioModel>> queryAudiosFromAlbum(int albumId,
      {AudioQueryOptions? options}) async {
    try {
      return await _dataSource.queryAudiosFromAlbum(albumId, options: options);
    } catch (e) {
      throw MediaErrorFactory.queryError(
        queryType: 'audio_from_album',
        message: 'Failed to query audio files from album: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<AudioModel>> queryAudiosFromArtist(int artistId,
      {AudioQueryOptions? options}) async {
    try {
      return await _dataSource.queryAudiosFromArtist(artistId,
          options: options);
    } catch (e) {
      throw MediaErrorFactory.queryError(
        queryType: 'audio_from_artist',
        message: 'Failed to query audio files from artist: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<AudioModel>> queryAudiosFromGenre(int genreId,
      {AudioQueryOptions? options}) async {
    try {
      return await _dataSource.queryAudiosFromGenre(genreId, options: options);
    } catch (e) {
      throw MediaErrorFactory.queryError(
        queryType: 'audio_from_genre',
        message: 'Failed to query audio files from genre: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<AudioModel>> queryAudiosFromPath(String path,
      {AudioQueryOptions? options}) async {
    try {
      return await _dataSource.queryAudiosFromPath(path, options: options);
    } catch (e) {
      throw MediaErrorFactory.queryError(
        queryType: 'audio_from_path',
        message: 'Failed to query audio files from path: ${e.toString()}',
        queryPath: path,
      );
    }
  }

  @override
  Future<List<VideoModel>> queryVideos({VideoQueryOptions? options}) async {
    try {
      return await _dataSource.queryVideos(options: options);
    } catch (e) {
      throw MediaErrorFactory.queryError(
        queryType: 'video',
        message: 'Failed to query video files: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<VideoModel>> queryVideosFromPath(String path,
      {VideoQueryOptions? options}) async {
    try {
      return await _dataSource.queryVideosFromPath(path, options: options);
    } catch (e) {
      throw MediaErrorFactory.queryError(
        queryType: 'video_from_path',
        message: 'Failed to query video files from path: ${e.toString()}',
        queryPath: path,
      );
    }
  }

  @override
  Future<List<DocumentModel>> queryDocuments({QueryOptions? options}) async {
    try {
      return await _dataSource.queryDocuments(options: options);
    } catch (e) {
      throw MediaErrorFactory.queryError(
        queryType: 'document',
        message: 'Failed to query document files: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<DocumentModel>> queryDocumentsFromPath(String path,
      {QueryOptions? options}) async {
    try {
      return await _dataSource.queryDocumentsFromPath(path, options: options);
    } catch (e) {
      throw MediaErrorFactory.queryError(
        queryType: 'document_from_path',
        message: 'Failed to query document files from path: ${e.toString()}',
        queryPath: path,
      );
    }
  }

  @override
  Future<List<FolderModel>> queryFolders({QueryOptions? options}) async {
    try {
      return await _dataSource.queryFolders(options: options);
    } catch (e) {
      throw MediaErrorFactory.queryError(
        queryType: 'folder',
        message: 'Failed to query folders: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<dynamic>> queryFoldersFromPath(String path,
      {QueryOptions? options,
      FolderBrowsingMode browsingMode = FolderBrowsingMode.all}) async {
    try {
      return await _dataSource.queryFoldersFromPath(path,
          options: options, browsingMode: browsingMode);
    } catch (e) {
      throw MediaErrorFactory.queryError(
        queryType: 'folder_from_path',
        message: 'Failed to query folders from path: ${e.toString()}',
        queryPath: path,
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> queryAlbums(
      {QueryOptions? options}) async {
    try {
      return await _dataSource.queryAlbums(options: options);
    } catch (e) {
      throw MediaErrorFactory.queryError(
        queryType: 'album',
        message: 'Failed to query albums: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> queryArtists(
      {QueryOptions? options}) async {
    try {
      return await _dataSource.queryArtists(options: options);
    } catch (e) {
      throw MediaErrorFactory.queryError(
        queryType: 'artist',
        message: 'Failed to query artists: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> queryGenres(
      {QueryOptions? options}) async {
    try {
      return await _dataSource.queryGenres(options: options);
    } catch (e) {
      throw MediaErrorFactory.queryError(
        queryType: 'genre',
        message: 'Failed to query genres: ${e.toString()}',
      );
    }
  }

  @override
  Future<ArtworkModel> queryArtwork(int id, ArtworkType type,
      {ArtworkSize size = ArtworkSize.medium}) async {
    try {
      return await _dataSource.queryArtwork(id, type, size: size);
    } catch (e) {
      throw MediaErrorFactory.artworkError(
        mediaId: id,
        artworkType: type,
        message: 'Failed to query artwork: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> clearCachedArtworks() async {
    try {
      await _dataSource.clearCachedArtworks();
    } catch (e) {
      throw MediaErrorFactory.platformError(
        platform: Platform.operatingSystem,
        message: 'Failed to clear cached artworks: ${e.toString()}',
        code: 'CLEAR_CACHE_FAILED',
      );
    }
  }

  @override
  Future<void> clearScanCache() async {
    try {
      await _dataSource.clearScanCache();
    } catch (e) {
      throw MediaErrorFactory.platformError(
        platform: Platform.operatingSystem,
        message: 'Failed to clear scan cache: ${e.toString()}',
        code: 'CLEAR_SCAN_CACHE_FAILED',
      );
    }
  }

  @override
  Future<void> scanMedia(String path) async {
    try {
      await _dataSource.scanMedia(path);
    } catch (e) {
      throw MediaErrorFactory.storageError(
        message: 'Failed to scan media: ${e.toString()}',
        path: path,
        operation: 'scan',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      return await _dataSource.getDeviceInfo();
    } catch (e) {
      throw MediaErrorFactory.platformError(
        platform: Platform.operatingSystem,
        message: 'Failed to get device info: ${e.toString()}',
        code: 'DEVICE_INFO_FAILED',
      );
    }
  }

  @override
  Future<String> getPlatformVersion() async {
    try {
      return await _dataSource.getPlatformVersion();
    } catch (e) {
      throw MediaErrorFactory.platformError(
        platform: Platform.operatingSystem,
        message: 'Failed to get platform version: ${e.toString()}',
        code: 'PLATFORM_VERSION_FAILED',
      );
    }
  }

  // Enhanced file system scanning methods

  @override
  Future<List<dynamic>> scanDirectoryRecursively(String path,
      {String fileType = 'all'}) async {
    try {
      return await _dataSource.scanDirectoryRecursively(path,
          fileType: fileType);
    } catch (e) {
      throw MediaErrorFactory.queryError(
        queryType: 'scan_directory',
        message: 'Failed to scan directory recursively: ${e.toString()}',
        queryPath: path,
      );
    }
  }

  @override
  Future<List<dynamic>> scanCommonDirectories({String fileType = 'all'}) async {
    try {
      return await _dataSource.scanCommonDirectories(fileType: fileType);
    } catch (e) {
      throw MediaErrorFactory.queryError(
        queryType: 'scan_common_directories',
        message: 'Failed to scan common directories: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<String>> getCommonDirectories() async {
    try {
      return await _dataSource.getCommonDirectories();
    } catch (e) {
      throw MediaErrorFactory.queryError(
        queryType: 'get_common_directories',
        message: 'Failed to get common directories: ${e.toString()}',
      );
    }
  }

  @override
  Stream<PermissionChangeEvent> listenToPermissionChanges() {
    try {
      return _dataSource.listenToPermissionChanges();
    } catch (e) {
      throw MediaErrorFactory.platformError(
        platform: Platform.operatingSystem,
        message: 'Failed to listen to permission changes: ${e.toString()}',
        code: 'PERMISSION_LISTEN_FAILED',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> debugArtworkAvailability() async {
    try {
      return await _dataSource.debugArtworkAvailability();
    } catch (e) {
      throw MediaErrorFactory.platformError(
        platform: Platform.operatingSystem,
        message: 'Failed to debug artwork availability: ${e.toString()}',
        code: 'DEBUG_ARTWORK_FAILED',
      );
    }
  }

  // MARK: - Media Extraction Methods (iOS Only)

  @override
  Future<Map<String, dynamic>> exportTrack(String trackId) async {
    try {
      return await _dataSource.exportTrack(trackId);
    } catch (e) {
      throw MediaErrorFactory.platformError(
        platform: Platform.operatingSystem,
        message: 'Failed to export track: ${e.toString()}',
        code: 'EXPORT_TRACK_FAILED',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> exportTrackWithArtwork(String trackId) async {
    try {
      return await _dataSource.exportTrackWithArtwork(trackId);
    } catch (e) {
      throw MediaErrorFactory.platformError(
        platform: Platform.operatingSystem,
        message: 'Failed to export track with artwork: ${e.toString()}',
        code: 'EXPORT_TRACK_WITH_ARTWORK_FAILED',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> extractArtwork(String trackId) async {
    try {
      return await _dataSource.extractArtwork(trackId);
    } catch (e) {
      throw MediaErrorFactory.platformError(
        platform: Platform.operatingSystem,
        message: 'Failed to extract artwork: ${e.toString()}',
        code: 'EXTRACT_ARTWORK_FAILED',
      );
    }
  }

  @override
  Future<bool> canExportTrack() async {
    try {
      return await _dataSource.canExportTrack();
    } catch (e) {
      throw MediaErrorFactory.platformError(
        platform: Platform.operatingSystem,
        message: 'Failed to check export capability: ${e.toString()}',
        code: 'CAN_EXPORT_TRACK_FAILED',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getTrackExtension(String trackPath) async {
    try {
      return await _dataSource.getTrackExtension(trackPath);
    } catch (e) {
      throw MediaErrorFactory.platformError(
        platform: Platform.operatingSystem,
        message: 'Failed to get track extension: ${e.toString()}',
        code: 'GET_TRACK_EXTENSION_FAILED',
      );
    }
  }
}
