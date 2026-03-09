import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'simple_audio_query_method_channel.dart';
import 'src/models/audio_model.dart';
import 'src/models/video_model.dart';
import 'src/models/document_model.dart';
import 'src/models/folder_model.dart';
import 'src/models/artwork_model.dart';
import 'src/models/query_options.dart';

abstract class SimpleMediaQueryPlatform extends PlatformInterface {
  /// Constructs a SimpleMediaQueryPlatform.
  SimpleMediaQueryPlatform() : super(token: _token);

  static final Object _token = Object();

  static SimpleMediaQueryPlatform _instance = MethodChannelSimpleMediaQuery();

  /// The default instance of [SimpleMediaQueryPlatform] to use.
  ///
  /// Defaults to [MethodChannelSimpleMediaQuery].
  static SimpleMediaQueryPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SimpleMediaQueryPlatform] when
  /// they register themselves.
  static set instance(SimpleMediaQueryPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  // Platform version
  Future<String?> getPlatformVersion() {
    throw UnimplementedError('getPlatformVersion() has not been implemented.');
  }

  // Permission methods
  Future<bool> requestPermission() {
    throw UnimplementedError('requestPermission() has not been implemented.');
  }

  Future<bool> hasPermission() {
    throw UnimplementedError('hasPermission() has not been implemented.');
  }

  // Audio query methods
  Future<List<AudioModel>> queryAudios({AudioQueryOptions? options}) {
    throw UnimplementedError('queryAudios() has not been implemented.');
  }

  Future<List<AudioModel>> queryAudiosFromAlbum(int albumId,
      {AudioQueryOptions? options}) {
    throw UnimplementedError(
        'queryAudiosFromAlbum() has not been implemented.');
  }

  Future<List<AudioModel>> queryAudiosFromArtist(int artistId,
      {AudioQueryOptions? options}) {
    throw UnimplementedError(
        'queryAudiosFromArtist() has not been implemented.');
  }

  Future<List<AudioModel>> queryAudiosFromGenre(int genreId,
      {AudioQueryOptions? options}) {
    throw UnimplementedError(
        'queryAudiosFromGenre() has not been implemented.');
  }

  Future<List<AudioModel>> queryAudiosFromPath(String path,
      {AudioQueryOptions? options}) {
    throw UnimplementedError('queryAudiosFromPath() has not been implemented.');
  }

  // Video query methods
  Future<List<VideoModel>> queryVideos({VideoQueryOptions? options}) {
    throw UnimplementedError('queryVideos() has not been implemented.');
  }

  Future<List<VideoModel>> queryVideosFromPath(String path,
      {VideoQueryOptions? options}) {
    throw UnimplementedError('queryVideosFromPath() has not been implemented.');
  }

  // Document query methods
  Future<List<DocumentModel>> queryDocuments({QueryOptions? options}) {
    throw UnimplementedError('queryDocuments() has not been implemented.');
  }

  Future<List<DocumentModel>> queryDocumentsFromPath(String path,
      {QueryOptions? options}) {
    throw UnimplementedError(
        'queryDocumentsFromPath() has not been implemented.');
  }

  // Folder query methods
  Future<List<FolderModel>> queryFolders({QueryOptions? options}) {
    throw UnimplementedError('queryFolders() has not been implemented.');
  }

  Future<List<FolderModel>> queryFoldersFromPath(String path,
      {QueryOptions? options}) {
    throw UnimplementedError(
        'queryFoldersFromPath() has not been implemented.');
  }

  // Album query methods
  Future<List<Map<String, dynamic>>> queryAlbums({QueryOptions? options}) {
    throw UnimplementedError('queryAlbums() has not been implemented.');
  }

  // Artist query methods
  Future<List<Map<String, dynamic>>> queryArtists({QueryOptions? options}) {
    throw UnimplementedError('queryArtists() has not been implemented.');
  }

  // Genre query methods
  Future<List<Map<String, dynamic>>> queryGenres({QueryOptions? options}) {
    throw UnimplementedError('queryGenres() has not been implemented.');
  }

  // Artwork methods
  Future<ArtworkModel> queryArtwork(int id, ArtworkType type,
      {ArtworkSize size = ArtworkSize.medium}) {
    throw UnimplementedError('queryArtwork() has not been implemented.');
  }

  Future<void> clearCachedArtworks() {
    throw UnimplementedError('clearCachedArtworks() has not been implemented.');
  }

  // Media scanning
  Future<void> scanMedia(String path) {
    throw UnimplementedError('scanMedia() has not been implemented.');
  }

  // Device information
  Future<Map<String, dynamic>> getDeviceInfo() {
    throw UnimplementedError('getDeviceInfo() has not been implemented.');
  }
}
