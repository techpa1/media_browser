import '../entities/media_permission.dart';
import '../entities/media_error.dart';
import '../repositories/media_repository.dart';
import 'check_permissions_usecase.dart';
import '../../models/audio_model.dart';
import '../../models/video_model.dart';
import '../../models/document_model.dart';
import '../../models/folder_model.dart';
import '../../models/query_options.dart';
import '../../enums/folder_browsing_mode.dart';

/// Use case for querying media files with permission checking
class QueryMediaUseCase {
  final MediaRepository _repository;
  final CheckPermissionsUseCase _checkPermissionsUseCase;

  const QueryMediaUseCase(this._repository, this._checkPermissionsUseCase);

  /// Query audio files with permission checking
  Future<List<AudioModel>> queryAudios({AudioQueryOptions? options}) async {
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

      return await _repository.queryAudios(options: options);
    } catch (e) {
      if (e is MediaError) {
        rethrow;
      }
      throw MediaErrorFactory.queryError(
        queryType: 'audio',
        message: 'Failed to query audio files: ${e.toString()}',
      );
    }
  }

  /// Query video files with permission checking
  Future<List<VideoModel>> queryVideos({VideoQueryOptions? options}) async {
    try {
      // Check permissions first
      final permissionResult =
          await _checkPermissionsUseCase.call(MediaType.video);
      if (!permissionResult.isGranted) {
        throw MediaErrorFactory.permissionDenied(
          missingPermissions: permissionResult.missingPermissions ?? [],
          status: permissionResult.status,
          message: 'Video permissions not granted: ${permissionResult.message}',
        );
      }

      return await _repository.queryVideos(options: options);
    } catch (e) {
      if (e is MediaError) {
        rethrow;
      }
      throw MediaErrorFactory.queryError(
        queryType: 'video',
        message: 'Failed to query video files: ${e.toString()}',
      );
    }
  }

  /// Query document files with permission checking
  Future<List<DocumentModel>> queryDocuments({QueryOptions? options}) async {
    try {
      // Check permissions first
      final permissionResult =
          await _checkPermissionsUseCase.call(MediaType.document);
      if (!permissionResult.isGranted) {
        throw MediaErrorFactory.permissionDenied(
          missingPermissions: permissionResult.missingPermissions ?? [],
          status: permissionResult.status,
          message:
              'Document permissions not granted: ${permissionResult.message}',
        );
      }

      return await _repository.queryDocuments(options: options);
    } catch (e) {
      if (e is MediaError) {
        rethrow;
      }
      throw MediaErrorFactory.queryError(
        queryType: 'document',
        message: 'Failed to query document files: ${e.toString()}',
      );
    }
  }

  /// Query folder information with permission checking
  Future<List<FolderModel>> queryFolders({QueryOptions? options}) async {
    try {
      // Check permissions first
      final permissionResult =
          await _checkPermissionsUseCase.call(MediaType.folder);
      if (!permissionResult.isGranted) {
        throw MediaErrorFactory.permissionDenied(
          missingPermissions: permissionResult.missingPermissions ?? [],
          status: permissionResult.status,
          message:
              'Folder permissions not granted: ${permissionResult.message}',
        );
      }

      return await _repository.queryFolders(options: options);
    } catch (e) {
      if (e is MediaError) {
        rethrow;
      }
      throw MediaErrorFactory.queryError(
        queryType: 'folder',
        message: 'Failed to query folders: ${e.toString()}',
      );
    }
  }

  /// Query audio files from specific album
  Future<List<AudioModel>> queryAudiosFromAlbum(int albumId,
      {AudioQueryOptions? options}) async {
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

      return await _repository.queryAudiosFromAlbum(albumId, options: options);
    } catch (e) {
      if (e is MediaError) {
        rethrow;
      }
      throw MediaErrorFactory.queryError(
        queryType: 'audio_from_album',
        message: 'Failed to query audio files from album: ${e.toString()}',
      );
    }
  }

  /// Query audio files from specific artist
  Future<List<AudioModel>> queryAudiosFromArtist(int artistId,
      {AudioQueryOptions? options}) async {
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

      return await _repository.queryAudiosFromArtist(artistId,
          options: options);
    } catch (e) {
      if (e is MediaError) {
        rethrow;
      }
      throw MediaErrorFactory.queryError(
        queryType: 'audio_from_artist',
        message: 'Failed to query audio files from artist: ${e.toString()}',
      );
    }
  }

  /// Query audio files from specific genre
  Future<List<AudioModel>> queryAudiosFromGenre(int genreId,
      {AudioQueryOptions? options}) async {
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

      return await _repository.queryAudiosFromGenre(genreId, options: options);
    } catch (e) {
      if (e is MediaError) {
        rethrow;
      }
      throw MediaErrorFactory.queryError(
        queryType: 'audio_from_genre',
        message: 'Failed to query audio files from genre: ${e.toString()}',
      );
    }
  }

  /// Query audio files from specific path
  Future<List<AudioModel>> queryAudiosFromPath(String path,
      {AudioQueryOptions? options}) async {
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

      return await _repository.queryAudiosFromPath(path, options: options);
    } catch (e) {
      if (e is MediaError) {
        rethrow;
      }
      throw MediaErrorFactory.queryError(
        queryType: 'audio_from_path',
        message: 'Failed to query audio files from path: ${e.toString()}',
        queryPath: path,
      );
    }
  }

  /// Query video files from specific path
  Future<List<VideoModel>> queryVideosFromPath(String path,
      {VideoQueryOptions? options}) async {
    try {
      // Check permissions first
      final permissionResult =
          await _checkPermissionsUseCase.call(MediaType.video);
      if (!permissionResult.isGranted) {
        throw MediaErrorFactory.permissionDenied(
          missingPermissions: permissionResult.missingPermissions ?? [],
          status: permissionResult.status,
          message: 'Video permissions not granted: ${permissionResult.message}',
        );
      }

      return await _repository.queryVideosFromPath(path, options: options);
    } catch (e) {
      if (e is MediaError) {
        rethrow;
      }
      throw MediaErrorFactory.queryError(
        queryType: 'video_from_path',
        message: 'Failed to query video files from path: ${e.toString()}',
        queryPath: path,
      );
    }
  }

  /// Query document files from specific path
  Future<List<DocumentModel>> queryDocumentsFromPath(String path,
      {QueryOptions? options}) async {
    try {
      // Check permissions first
      final permissionResult =
          await _checkPermissionsUseCase.call(MediaType.document);
      if (!permissionResult.isGranted) {
        throw MediaErrorFactory.permissionDenied(
          missingPermissions: permissionResult.missingPermissions ?? [],
          status: permissionResult.status,
          message:
              'Document permissions not granted: ${permissionResult.message}',
        );
      }

      return await _repository.queryDocumentsFromPath(path, options: options);
    } catch (e) {
      if (e is MediaError) {
        rethrow;
      }
      throw MediaErrorFactory.queryError(
        queryType: 'document_from_path',
        message: 'Failed to query document files from path: ${e.toString()}',
        queryPath: path,
      );
    }
  }

  /// Query folders from specific path
  Future<List<dynamic>> queryFoldersFromPath(String path,
      {QueryOptions? options,
      FolderBrowsingMode browsingMode = FolderBrowsingMode.all}) async {
    try {
      // Check permissions first
      final permissionResult =
          await _checkPermissionsUseCase.call(MediaType.folder);
      if (!permissionResult.isGranted) {
        throw MediaErrorFactory.permissionDenied(
          missingPermissions: permissionResult.missingPermissions ?? [],
          status: permissionResult.status,
          message:
              'Folder permissions not granted: ${permissionResult.message}',
        );
      }

      return await _repository.queryFoldersFromPath(path,
          options: options, browsingMode: browsingMode);
    } catch (e) {
      if (e is MediaError) {
        rethrow;
      }
      throw MediaErrorFactory.queryError(
        queryType: 'folder_from_path',
        message: 'Failed to query folders from path: ${e.toString()}',
        queryPath: path,
      );
    }
  }

  // Enhanced file system scanning methods

  /// Scan directory recursively for files and folders
  Future<List<dynamic>> scanDirectoryRecursively(String path,
      {String fileType = 'all'}) async {
    try {
      // Check permissions first
      final permissionResult =
          await _checkPermissionsUseCase.call(MediaType.folder);
      if (!permissionResult.isGranted) {
        throw MediaErrorFactory.permissionDenied(
          missingPermissions: permissionResult.missingPermissions ?? [],
          status: permissionResult.status,
          message:
              'Folder permissions not granted: ${permissionResult.message}',
        );
      }

      return await _repository.scanDirectoryRecursively(path,
          fileType: fileType);
    } catch (e) {
      if (e is MediaError) {
        rethrow;
      }
      throw MediaErrorFactory.queryError(
        queryType: 'scan_directory',
        message: 'Failed to scan directory recursively: ${e.toString()}',
        queryPath: path,
      );
    }
  }

  /// Scan common directories for specific file types
  Future<List<dynamic>> scanCommonDirectories({String fileType = 'all'}) async {
    try {
      // Check permissions first
      final permissionResult =
          await _checkPermissionsUseCase.call(MediaType.folder);
      if (!permissionResult.isGranted) {
        throw MediaErrorFactory.permissionDenied(
          missingPermissions: permissionResult.missingPermissions ?? [],
          status: permissionResult.status,
          message:
              'Folder permissions not granted: ${permissionResult.message}',
        );
      }

      return await _repository.scanCommonDirectories(fileType: fileType);
    } catch (e) {
      if (e is MediaError) {
        rethrow;
      }
      throw MediaErrorFactory.queryError(
        queryType: 'scan_common_directories',
        message: 'Failed to scan common directories: ${e.toString()}',
      );
    }
  }

  /// Get list of common directories
  Future<List<String>> getCommonDirectories() async {
    try {
      return await _repository.getCommonDirectories();
    } catch (e) {
      throw MediaErrorFactory.queryError(
        queryType: 'get_common_directories',
        message: 'Failed to get common directories: ${e.toString()}',
      );
    }
  }
}
