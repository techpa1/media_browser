import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'simple_audio_query_platform_interface.dart';
import 'src/models/audio_model.dart';
import 'src/models/video_model.dart';
import 'src/models/document_model.dart';
import 'src/models/folder_model.dart';
import 'src/models/artwork_model.dart';
import 'src/models/query_options.dart';

/// An implementation of [SimpleMediaQueryPlatform] that uses method channels.
class MethodChannelSimpleMediaQuery extends SimpleMediaQueryPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('simplmedia_browsere_media_query');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<bool> requestPermission() async {
    final result = await methodChannel.invokeMethod<bool>('requestPermission');
    return result ?? false;
  }

  @override
  Future<bool> hasPermission() async {
    final result = await methodChannel.invokeMethod<bool>('hasPermission');
    return result ?? false;
  }

  @override
  Future<List<AudioModel>> queryAudios({AudioQueryOptions? options}) async {
    final List<dynamic> result =
        await methodChannel.invokeMethod<List<dynamic>>(
              'queryAudios',
              options?.toMap(),
            ) ??
            [];

    return result
        .map((item) => AudioModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<List<AudioModel>> queryAudiosFromAlbum(int albumId,
      {AudioQueryOptions? options}) async {
    final List<dynamic> result =
        await methodChannel.invokeMethod<List<dynamic>>(
              'queryAudiosFromAlbum',
              {
                'albumId': albumId,
                'options': options?.toMap(),
              },
            ) ??
            [];

    return result
        .map((item) => AudioModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<List<AudioModel>> queryAudiosFromArtist(int artistId,
      {AudioQueryOptions? options}) async {
    final List<dynamic> result =
        await methodChannel.invokeMethod<List<dynamic>>(
              'queryAudiosFromArtist',
              {
                'artistId': artistId,
                'options': options?.toMap(),
              },
            ) ??
            [];

    return result
        .map((item) => AudioModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<List<AudioModel>> queryAudiosFromGenre(int genreId,
      {AudioQueryOptions? options}) async {
    final List<dynamic> result =
        await methodChannel.invokeMethod<List<dynamic>>(
              'queryAudiosFromGenre',
              {
                'genreId': genreId,
                'options': options?.toMap(),
              },
            ) ??
            [];

    return result
        .map((item) => AudioModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<List<AudioModel>> queryAudiosFromPath(String path,
      {AudioQueryOptions? options}) async {
    final List<dynamic> result =
        await methodChannel.invokeMethod<List<dynamic>>(
              'queryAudiosFromPath',
              {
                'path': path,
                'options': options?.toMap(),
              },
            ) ??
            [];

    return result
        .map((item) => AudioModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<List<VideoModel>> queryVideos({VideoQueryOptions? options}) async {
    final List<dynamic> result =
        await methodChannel.invokeMethod<List<dynamic>>(
              'queryVideos',
              options?.toMap(),
            ) ??
            [];

    return result
        .map((item) => VideoModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<List<VideoModel>> queryVideosFromPath(String path,
      {VideoQueryOptions? options}) async {
    final List<dynamic> result =
        await methodChannel.invokeMethod<List<dynamic>>(
              'queryVideosFromPath',
              {
                'path': path,
                'options': options?.toMap(),
              },
            ) ??
            [];

    return result
        .map((item) => VideoModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<List<DocumentModel>> queryDocuments({QueryOptions? options}) async {
    final List<dynamic> result =
        await methodChannel.invokeMethod<List<dynamic>>(
              'queryDocuments',
              options?.toMap(),
            ) ??
            [];

    return result
        .map((item) => DocumentModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<List<DocumentModel>> queryDocumentsFromPath(String path,
      {QueryOptions? options}) async {
    final List<dynamic> result =
        await methodChannel.invokeMethod<List<dynamic>>(
              'queryDocumentsFromPath',
              {
                'path': path,
                'options': options?.toMap(),
              },
            ) ??
            [];

    return result
        .map((item) => DocumentModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<List<FolderModel>> queryFolders({QueryOptions? options}) async {
    final List<dynamic> result =
        await methodChannel.invokeMethod<List<dynamic>>(
              'queryFolders',
              options?.toMap(),
            ) ??
            [];

    return result
        .map((item) => FolderModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<List<FolderModel>> queryFoldersFromPath(String path,
      {QueryOptions? options}) async {
    final List<dynamic> result =
        await methodChannel.invokeMethod<List<dynamic>>(
              'queryFoldersFromPath',
              {
                'path': path,
                'options': options?.toMap(),
              },
            ) ??
            [];

    return result
        .map((item) => FolderModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> queryAlbums(
      {QueryOptions? options}) async {
    final List<dynamic> result =
        await methodChannel.invokeMethod<List<dynamic>>(
              'queryAlbums',
              options?.toMap(),
            ) ??
            [];

    return result.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> queryArtists(
      {QueryOptions? options}) async {
    final List<dynamic> result =
        await methodChannel.invokeMethod<List<dynamic>>(
              'queryArtists',
              options?.toMap(),
            ) ??
            [];

    return result.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> queryGenres(
      {QueryOptions? options}) async {
    final List<dynamic> result =
        await methodChannel.invokeMethod<List<dynamic>>(
              'queryGenres',
              options?.toMap(),
            ) ??
            [];

    return result.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  @override
  Future<ArtworkModel> queryArtwork(int id, ArtworkType type,
      {ArtworkSize size = ArtworkSize.medium}) async {
    final Map<String, dynamic> result =
        await methodChannel.invokeMethod<Map<String, dynamic>>(
              'queryArtwork',
              {
                'id': id,
                'type': type.toString(),
                'size': size.toString(),
              },
            ) ??
            {};

    return ArtworkModel.fromMap(result);
  }

  @override
  Future<void> clearCachedArtworks() async {
    await methodChannel.invokeMethod('clearCachedArtworks');
  }

  @override
  Future<void> scanMedia(String path) async {
    await methodChannel.invokeMethod('scanMedia', {'path': path});
  }

  @override
  Future<Map<String, dynamic>> getDeviceInfo() async {
    final Map<String, dynamic>? result =
        await methodChannel.invokeMethod<Map<String, dynamic>>('getDeviceInfo');
    return result ?? {};
  }
}
