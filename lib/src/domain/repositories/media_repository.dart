import '../entities/media_permission.dart';
import '../entities/permission_change_event.dart';
import '../../models/audio_model.dart';
import '../../models/video_model.dart';
import '../../models/document_model.dart';
import '../../models/folder_model.dart';
import '../../models/artwork_model.dart';
import '../../models/query_options.dart';
import '../../enums/folder_browsing_mode.dart';
import 'dart:async';

/// Abstract repository interface for media operations
abstract class MediaRepository {
  /// Check if required permissions are granted
  Future<PermissionResult> checkPermissions(MediaType mediaType);

  /// Request permissions for specific media type
  Future<PermissionResult> requestPermissions(MediaType mediaType);

  /// Query audio files
  Future<List<AudioModel>> queryAudios({AudioQueryOptions? options});

  /// Query audio files from specific album
  Future<List<AudioModel>> queryAudiosFromAlbum(int albumId,
      {AudioQueryOptions? options});

  /// Query audio files from specific artist
  Future<List<AudioModel>> queryAudiosFromArtist(int artistId,
      {AudioQueryOptions? options});

  /// Query audio files from specific genre
  Future<List<AudioModel>> queryAudiosFromGenre(int genreId,
      {AudioQueryOptions? options});

  /// Query audio files from specific path
  Future<List<AudioModel>> queryAudiosFromPath(String path,
      {AudioQueryOptions? options});

  /// Query video files
  Future<List<VideoModel>> queryVideos({VideoQueryOptions? options});

  /// Query video files from specific path
  Future<List<VideoModel>> queryVideosFromPath(String path,
      {VideoQueryOptions? options});

  /// Query document files
  Future<List<DocumentModel>> queryDocuments({QueryOptions? options});

  /// Query document files from specific path
  Future<List<DocumentModel>> queryDocumentsFromPath(String path,
      {QueryOptions? options});

  /// Query folder information
  Future<List<FolderModel>> queryFolders({QueryOptions? options});

  /// Query folders from specific path
  Future<List<dynamic>> queryFoldersFromPath(String path,
      {QueryOptions? options,
      FolderBrowsingMode browsingMode = FolderBrowsingMode.all});

  /// Query album information
  Future<List<Map<String, dynamic>>> queryAlbums({QueryOptions? options});

  /// Query artist information
  Future<List<Map<String, dynamic>>> queryArtists({QueryOptions? options});

  /// Query genre information
  Future<List<Map<String, dynamic>>> queryGenres({QueryOptions? options});

  /// Query artwork for media
  Future<ArtworkModel> queryArtwork(int id, ArtworkType type,
      {ArtworkSize size = ArtworkSize.medium});

  /// Clear cached artworks
  Future<void> clearCachedArtworks();

  /// Clear scan cache to force fresh file system scan
  Future<void> clearScanCache();

  /// Scan media files in specific path
  Future<void> scanMedia(String path);

  /// Get device information
  Future<Map<String, dynamic>> getDeviceInfo();

  /// Get platform version
  Future<String> getPlatformVersion();

  // Enhanced file system scanning methods

  /// Scan directory recursively for files and folders
  Future<List<dynamic>> scanDirectoryRecursively(String path,
      {String fileType = 'all'});

  /// Scan common directories for specific file types
  Future<List<dynamic>> scanCommonDirectories({String fileType = 'all'});

  /// Get list of common directories
  Future<List<String>> getCommonDirectories();

  /// Listen for permission changes
  /// Returns a stream that emits permission change events
  Stream<PermissionChangeEvent> listenToPermissionChanges();

  /// Debug artwork availability in the media library
  /// Returns statistics about how many items have artwork
  Future<Map<String, dynamic>> debugArtworkAvailability();

  // MARK: - Media Extraction Methods (iOS & macOS)

  /// Export a track from the music library to a temporary file
  /// Returns the file path of the exported track
  /// Note: This method is available on iOS and macOS
  Future<Map<String, dynamic>> exportTrack(String trackId);

  /// Export a track with its artwork from the music library
  /// Returns both the audio file path and artwork file path
  /// Note: This method is available on iOS and macOS
  Future<Map<String, dynamic>> exportTrackWithArtwork(String trackId);

  /// Extract artwork from a track and save it as a JPEG file
  /// Returns the file path of the extracted artwork
  /// Note: This method is available on iOS and macOS
  Future<Map<String, dynamic>> extractArtwork(String trackId);

  /// Check if the app can export tracks from the music library
  /// Returns true if music library access is authorized
  /// Note: This method is available on iOS and macOS
  Future<bool> canExportTrack();

  /// Get the file extension for a track path
  /// Returns the extension in lowercase
  /// Note: This method is available on iOS and macOS
  Future<Map<String, dynamic>> getTrackExtension(String trackPath);
}
