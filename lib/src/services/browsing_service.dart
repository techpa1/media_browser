import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/audio_model.dart';
import '../models/playlist_model.dart';
import '../models/folder_model.dart';
import '../models/album_model.dart';
import '../models/artist_model.dart';
import '../models/genre_model.dart';
import '../data/repositories/media_repository.dart';

/// Service for handling media browsing actions
class BrowsingService {
  static final BrowsingService _instance = BrowsingService._internal();
  factory BrowsingService() => _instance;
  BrowsingService._internal();

  final MediaRepository _mediaRepository = MediaRepository();

  // Stream controllers for different browsing contexts
  final StreamController<List<AudioModel>> _audioTracksController =
      StreamController<List<AudioModel>>.broadcast();
  final StreamController<List<AlbumModel>> _albumsController =
      StreamController<List<AlbumModel>>.broadcast();
  final StreamController<List<ArtistModel>> _artistsController =
      StreamController<List<ArtistModel>>.broadcast();
  final StreamController<List<GenreModel>> _genresController =
      StreamController<List<GenreModel>>.broadcast();
  final StreamController<List<FolderModel>> _foldersController =
      StreamController<List<FolderModel>>.broadcast();
  final StreamController<BrowsingContext> _browsingContextController =
      StreamController<BrowsingContext>.broadcast();

  // Current browsing state
  BrowsingContext _currentContext = BrowsingContext.all();
  List<AudioModel> _currentTracks = [];
  List<AlbumModel> _currentAlbums = [];
  List<ArtistModel> _currentArtists = [];
  List<GenreModel> _currentGenres = [];
  List<FolderModel> _currentFolders = [];

  // Getters for streams
  Stream<List<AudioModel>> get audioTracksStream =>
      _audioTracksController.stream;
  Stream<List<AlbumModel>> get albumsStream => _albumsController.stream;
  Stream<List<ArtistModel>> get artistsStream => _artistsController.stream;
  Stream<List<GenreModel>> get genresStream => _genresController.stream;
  Stream<List<FolderModel>> get foldersStream => _foldersController.stream;
  Stream<BrowsingContext> get browsingContextStream =>
      _browsingContextController.stream;

  // Current state getters
  BrowsingContext get currentContext => _currentContext;
  List<AudioModel> get currentTracks => List.unmodifiable(_currentTracks);
  List<AlbumModel> get currentAlbums => List.unmodifiable(_currentAlbums);
  List<ArtistModel> get currentArtists => List.unmodifiable(_currentArtists);
  List<GenreModel> get currentGenres => List.unmodifiable(_currentGenres);
  List<FolderModel> get currentFolders => List.unmodifiable(_currentFolders);

  /// Initialize the browsing service
  Future<void> initialize() async {
    await _loadAllMedia();
  }

  /// Load all media types
  Future<void> _loadAllMedia() async {
    try {
      // Load all media types in parallel
      final results = await Future.wait([
        _mediaRepository.queryAudios(),
        _mediaRepository.queryAlbums(),
        _mediaRepository.queryArtists(),
        _mediaRepository.queryGenres(),
        _mediaRepository.queryFolders(),
      ]);

      _currentTracks = results[0] as List<AudioModel>;
      _currentAlbums = results[1] as List<AlbumModel>;
      _currentArtists = results[2] as List<ArtistModel>;
      _currentGenres = results[3] as List<GenreModel>;
      _currentFolders = results[4] as List<FolderModel>;

      // Emit updates
      _audioTracksController.add(_currentTracks);
      _albumsController.add(_currentAlbums);
      _artistsController.add(_currentArtists);
      _genresController.add(_currentGenres);
      _foldersController.add(_currentFolders);

      if (kDebugMode) {
        print(
            '📁 Loaded media: ${_currentTracks.length} tracks, ${_currentAlbums.length} albums, ${_currentArtists.length} artists');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading media: $e');
      }
      rethrow;
    }
  }

  /// Browse all media
  Future<void> browseAll() async {
    _currentContext = BrowsingContext.all();
    _browsingContextController.add(_currentContext);
    await _loadAllMedia();
  }

  /// Browse tracks from a specific album
  Future<void> browseAlbum(AlbumModel album) async {
    try {
      _currentContext = BrowsingContext.album(album);
      _browsingContextController.add(_currentContext);

      final tracks = await _mediaRepository.queryAudiosFromAlbum(album.id);
      _currentTracks = tracks;
      _audioTracksController.add(_currentTracks);

      if (kDebugMode) {
        print('🎵 Browsing album "${album.album}": ${tracks.length} tracks');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error browsing album: $e');
      }
      rethrow;
    }
  }

  /// Browse tracks from a specific artist
  Future<void> browseArtist(ArtistModel artist) async {
    try {
      _currentContext = BrowsingContext.artist(artist);
      _browsingContextController.add(_currentContext);

      final tracks = await _mediaRepository.queryAudiosFromArtist(artist.id);
      _currentTracks = tracks;
      _audioTracksController.add(_currentTracks);

      if (kDebugMode) {
        print('🎤 Browsing artist "${artist.artist}": ${tracks.length} tracks');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error browsing artist: $e');
      }
      rethrow;
    }
  }

  /// Browse tracks from a specific genre
  Future<void> browseGenre(GenreModel genre) async {
    try {
      _currentContext = BrowsingContext.genre(genre);
      _browsingContextController.add(_currentContext);

      final tracks = await _mediaRepository.queryAudiosFromGenre(genre.id);
      _currentTracks = tracks;
      _audioTracksController.add(_currentTracks);

      if (kDebugMode) {
        print('🎭 Browsing genre "${genre.genre}": ${tracks.length} tracks');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error browsing genre: $e');
      }
      rethrow;
    }
  }

  /// Browse tracks from a specific folder
  Future<void> browseFolder(FolderModel folder) async {
    try {
      _currentContext = BrowsingContext.folder(folder);
      _browsingContextController.add(_currentContext);

      final tracks = await _mediaRepository.queryAudiosFromPath(folder.path);
      _currentTracks = tracks;
      _audioTracksController.add(_currentTracks);

      if (kDebugMode) {
        print('📁 Browsing folder "${folder.name}": ${tracks.length} tracks');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error browsing folder: $e');
      }
      rethrow;
    }
  }

  /// Search for media
  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      await browseAll();
      return;
    }

    try {
      _currentContext = BrowsingContext.search(query);
      _browsingContextController.add(_currentContext);

      final lowerQuery = query.toLowerCase();

      // Filter tracks
      final filteredTracks = _currentTracks.where((track) {
        return track.title.toLowerCase().contains(lowerQuery) ||
            track.artist.toLowerCase().contains(lowerQuery) ||
            track.album.toLowerCase().contains(lowerQuery);
      }).toList();

      // Filter albums
      final filteredAlbums = _currentAlbums.where((album) {
        return album.album.toLowerCase().contains(lowerQuery) ||
            album.artist.toLowerCase().contains(lowerQuery);
      }).toList();

      // Filter artists
      final filteredArtists = _currentArtists.where((artist) {
        return artist.artist.toLowerCase().contains(lowerQuery);
      }).toList();

      // Filter genres
      final filteredGenres = _currentGenres.where((genre) {
        return genre.genre.toLowerCase().contains(lowerQuery);
      }).toList();

      // Filter folders
      final filteredFolders = _currentFolders.where((folder) {
        return folder.name.toLowerCase().contains(lowerQuery) ||
            folder.path.toLowerCase().contains(lowerQuery);
      }).toList();

      _audioTracksController.add(filteredTracks);
      _albumsController.add(filteredAlbums);
      _artistsController.add(filteredArtists);
      _genresController.add(filteredGenres);
      _foldersController.add(filteredFolders);

      if (kDebugMode) {
        print(
            '🔍 Search "$query": ${filteredTracks.length} tracks, ${filteredAlbums.length} albums');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error searching: $e');
      }
      rethrow;
    }
  }

  /// Get recently played tracks
  Future<List<AudioModel>> getRecentlyPlayed({int limit = 50}) async {
    // This would typically come from a local database
    // For now, return a subset of current tracks
    return _currentTracks.take(limit).toList();
  }

  /// Get most played tracks
  Future<List<AudioModel>> getMostPlayed({int limit = 50}) async {
    // This would typically come from a local database with play counts
    // For now, return tracks sorted by duration (as a proxy)
    final sortedTracks = List<AudioModel>.from(_currentTracks);
    sortedTracks.sort((a, b) => b.duration.compareTo(a.duration));
    return sortedTracks.take(limit).toList();
  }

  /// Get favorite tracks
  Future<List<AudioModel>> getFavorites() async {
    // This would typically come from a local database
    // For now, return empty list
    return [];
  }

  /// Create a playlist from current browsing context
  PlaylistModel createPlaylistFromContext(String playlistName) {
    return PlaylistModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: playlistName,
      tracks: _currentTracks,
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
      description: 'Playlist created from ${_currentContext.type} browsing',
    );
  }

  /// Refresh current browsing context
  Future<void> refresh() async {
    switch (_currentContext.type) {
      case BrowsingContextType.all:
        await browseAll();
        break;
      case BrowsingContextType.album:
        if (_currentContext.album != null) {
          await browseAlbum(_currentContext.album!);
        }
        break;
      case BrowsingContextType.artist:
        if (_currentContext.artist != null) {
          await browseArtist(_currentContext.artist!);
        }
        break;
      case BrowsingContextType.genre:
        if (_currentContext.genre != null) {
          await browseGenre(_currentContext.genre!);
        }
        break;
      case BrowsingContextType.folder:
        if (_currentContext.folder != null) {
          await browseFolder(_currentContext.folder!);
        }
        break;
      case BrowsingContextType.search:
        if (_currentContext.searchQuery != null) {
          await search(_currentContext.searchQuery!);
        }
        break;
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _audioTracksController.close();
    await _albumsController.close();
    await _artistsController.close();
    await _genresController.close();
    await _foldersController.close();
    await _browsingContextController.close();
  }
}

/// Browsing context to track current browsing state
class BrowsingContext {
  final BrowsingContextType type;
  final AlbumModel? album;
  final ArtistModel? artist;
  final GenreModel? genre;
  final FolderModel? folder;
  final String? searchQuery;

  const BrowsingContext._({
    required this.type,
    this.album,
    this.artist,
    this.genre,
    this.folder,
    this.searchQuery,
  });

  /// Create context for browsing all media
  factory BrowsingContext.all() {
    return const BrowsingContext._(type: BrowsingContextType.all);
  }

  /// Create context for browsing a specific album
  factory BrowsingContext.album(AlbumModel album) {
    return BrowsingContext._(type: BrowsingContextType.album, album: album);
  }

  /// Create context for browsing a specific artist
  factory BrowsingContext.artist(ArtistModel artist) {
    return BrowsingContext._(type: BrowsingContextType.artist, artist: artist);
  }

  /// Create context for browsing a specific genre
  factory BrowsingContext.genre(GenreModel genre) {
    return BrowsingContext._(type: BrowsingContextType.genre, genre: genre);
  }

  /// Create context for browsing a specific folder
  factory BrowsingContext.folder(FolderModel folder) {
    return BrowsingContext._(type: BrowsingContextType.folder, folder: folder);
  }

  /// Create context for search results
  factory BrowsingContext.search(String query) {
    return BrowsingContext._(
        type: BrowsingContextType.search, searchQuery: query);
  }

  /// Get display title for the current context
  String get displayTitle {
    switch (type) {
      case BrowsingContextType.all:
        return 'All Media';
      case BrowsingContextType.album:
        return album?.album ?? 'Unknown Album';
      case BrowsingContextType.artist:
        return artist?.artist ?? 'Unknown Artist';
      case BrowsingContextType.genre:
        return genre?.genre ?? 'Unknown Genre';
      case BrowsingContextType.folder:
        return folder?.name ?? 'Unknown Folder';
      case BrowsingContextType.search:
        return 'Search: $searchQuery';
    }
  }

  @override
  String toString() {
    return 'BrowsingContext(type: $type, title: $displayTitle)';
  }
}

/// Types of browsing contexts
enum BrowsingContextType {
  all,
  album,
  artist,
  genre,
  folder,
  search,
}
