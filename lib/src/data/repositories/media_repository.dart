import 'package:media_browser/media_browser.dart';
import '../../models/album_model.dart';
import '../../models/artist_model.dart';
import '../../models/genre_model.dart';

/// Repository for media data operations
class MediaRepository {
  final MediaBrowser _mediaBrowser = MediaBrowser();

  /// Query all audio tracks
  Future<List<AudioModel>> queryAudios() async {
    try {
      final result = await _mediaBrowser.queryAudios();
      return result;
    } catch (e) {
      print('Error querying audios: $e');
      return [];
    }
  }

  /// Query all albums
  Future<List<AlbumModel>> queryAlbums() async {
    try {
      final result = await _mediaBrowser.queryAlbums();
      return result.map((album) => AlbumModel.fromMap(album)).toList();
    } catch (e) {
      print('Error querying albums: $e');
      return [];
    }
  }

  /// Query all artists
  Future<List<ArtistModel>> queryArtists() async {
    try {
      final result = await _mediaBrowser.queryArtists();
      return result.map((artist) => ArtistModel.fromMap(artist)).toList();
    } catch (e) {
      print('Error querying artists: $e');
      return [];
    }
  }

  /// Query all genres
  Future<List<GenreModel>> queryGenres() async {
    try {
      final result = await _mediaBrowser.queryGenres();
      return result.map((genre) => GenreModel.fromMap(genre)).toList();
    } catch (e) {
      print('Error querying genres: $e');
      return [];
    }
  }

  /// Query all folders
  Future<List<FolderModel>> queryFolders() async {
    try {
      final result = await _mediaBrowser.queryFolders();
      return result;
    } catch (e) {
      print('Error querying folders: $e');
      return [];
    }
  }

  /// Query audio tracks from a specific album
  Future<List<AudioModel>> queryAudiosFromAlbum(int albumId) async {
    try {
      final result = await _mediaBrowser.queryAudiosFromAlbum(albumId);
      return result;
    } catch (e) {
      print('Error querying audios from album: $e');
      return [];
    }
  }

  /// Query audio tracks from a specific artist
  Future<List<AudioModel>> queryAudiosFromArtist(int artistId) async {
    try {
      final result = await _mediaBrowser.queryAudiosFromArtist(artistId);
      return result;
    } catch (e) {
      print('Error querying audios from artist: $e');
      return [];
    }
  }

  /// Query audio tracks from a specific genre
  Future<List<AudioModel>> queryAudiosFromGenre(int genreId) async {
    try {
      final result = await _mediaBrowser.queryAudiosFromGenre(genreId);
      return result;
    } catch (e) {
      print('Error querying audios from genre: $e');
      return [];
    }
  }

  /// Query audio tracks from a specific path
  Future<List<AudioModel>> queryAudiosFromPath(String path) async {
    try {
      final result = await _mediaBrowser.queryAudiosFromPath(path);
      return result;
    } catch (e) {
      print('Error querying audios from path: $e');
      return [];
    }
  }

  /// Query video tracks from a specific path
  Future<List<VideoModel>> queryVideosFromPath(String path) async {
    try {
      final result = await _mediaBrowser.queryVideosFromPath(path);
      return result;
    } catch (e) {
      print('Error querying videos from path: $e');
      return [];
    }
  }

  /// Query documents from a specific path
  Future<List<DocumentModel>> queryDocumentsFromPath(String path) async {
    try {
      final result = await _mediaBrowser.queryDocumentsFromPath(path);
      return result;
    } catch (e) {
      print('Error querying documents from path: $e');
      return [];
    }
  }
}
