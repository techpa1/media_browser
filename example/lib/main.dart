import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:media_browser/media_browser.dart';
import 'package:media_browser/src/services/media_player_service.dart';
import 'package:media_browser/src/services/browsing_service.dart';
import 'widgets/artwork_widget.dart';

void main() {
  runApp(const MyApp());
}

/// Navigation item for tracking browsing history
class NavigationItem {
  final String title;
  final String type; // 'root', 'album', 'artist', 'genre', 'folder'
  final dynamic data;
  final List<dynamic> items;

  NavigationItem({
    required this.title,
    required this.type,
    required this.data,
    required this.items,
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Media Browser Example',
      theme: ThemeData.dark(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
      ],
      home: const MediaQueryHome(),
    );
  }
}

class MediaQueryHome extends StatefulWidget {
  const MediaQueryHome({super.key});

  @override
  State<MediaQueryHome> createState() => _MediaQueryHomeState();
}

class _MediaQueryHomeState extends State<MediaQueryHome>
    with TickerProviderStateMixin {
  final MediaBrowser _mediaBrowser = MediaBrowser();
  final MediaPlayerService _mediaPlayer = MediaPlayerService();
  final BrowsingService _browsingService = BrowsingService();

  // Media data
  List<AudioModel> _audios = [];
  List<VideoModel> _videos = [];
  List<DocumentModel> _documents = [];
  List<FolderModel> _folders = [];
  List<Map<String, dynamic>> _albums = [];
  List<Map<String, dynamic>> _artists = [];
  List<Map<String, dynamic>> _genres = [];

  // UI state
  int _selectedTabIndex = 0;
  bool _isLoading = false;
  bool _isGridView = false; // Default to list view
  bool _hasInitialized = false;
  late TabController _tabController;

  // Search state
  final TextEditingController _searchController = TextEditingController();

  // Navigation state
  final List<NavigationItem> _navigationStack = [];
  List<dynamic> _currentData = [];
  String _searchQuery = '';
  bool _isSearching = false;

  // Media type selection
  final Map<MediaType, bool> _selectedMediaTypes = {
    MediaType.audio: true,
    MediaType.video: true,
    MediaType.document: true,
    MediaType.folder: true,
  };

  // Tab options - will be dynamically generated based on selected media types
  List<String> _tabs = [];

  @override
  void initState() {
    super.initState();
    _updateTabs();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
    _searchController.addListener(_onSearchChanged);
    _initializeNavigation();
    _initializeServices();
    initPlatformState();

    // Automatically request permissions and load media data on app launch
    _initializeApp();
  }

  void _initializeNavigation() {
    // Initialize with root navigation items
    _navigationStack.clear();
    _currentData = [];
  }

  Future<void> _initializeServices() async {
    try {
      await _mediaPlayer.initialize();
      await _browsingService.initialize();

      // Listen to player state changes
      _mediaPlayer.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {});
        }
      });

      // Listen to current track changes
      _mediaPlayer.currentTrackStream.listen((index) {
        if (mounted) {
          setState(() {});
        }
      });

      if (kDebugMode) {
        print('🎵 Media services initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing media services: $e');
      }
    }
  }

  void _updateTabs() {
    _tabs = [];
    if (_selectedMediaTypes[MediaType.audio] == true) {
      _tabs.addAll(['Albums', 'Artists', 'Genres', 'Tracks']);
    }
    if (_selectedMediaTypes[MediaType.video] == true) {
      _tabs.add('Videos');
    }
    if (_selectedMediaTypes[MediaType.document] == true) {
      _tabs.add('Documents');
    }
    if (_selectedMediaTypes[MediaType.folder] == true) {
      _tabs.add('Folders');
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _isSearching = _searchQuery.isNotEmpty;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _isSearching = false;
    });
  }

  void _showSearchBar() {
    setState(() {
      _isSearching = true;
    });
  }

  void _showMediaTypeSelectionDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Select Media Types'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose which media types you want to browse:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              ...MediaType.values.map((mediaType) => CheckboxListTile(
                    title: Text(_getMediaTypeDisplayName(mediaType)),
                    subtitle: Text(_getMediaTypeDescription(mediaType)),
                    value: _selectedMediaTypes[mediaType] ?? false,
                    onChanged: (bool? value) {
                      setDialogState(() {
                        _selectedMediaTypes[mediaType] = value ?? false;
                      });
                    },
                  )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _updateTabs();
                  // Dispose old controller and create new one with updated length
                  _tabController.dispose();
                  _tabController =
                      TabController(length: _tabs.length, vsync: this);
                  _tabController.addListener(() {
                    setState(() {
                      _selectedTabIndex = _tabController.index;
                    });
                  });
                  // Reset to first tab if current index is out of bounds
                  if (_selectedTabIndex >= _tabs.length) {
                    _selectedTabIndex = 0;
                  }
                });
                Navigator.of(context).pop();
                // Reload media data with new selection
                _loadMediaData();
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  // Action handlers for different media types
  void _handleAlbumAction(String action, Map<String, dynamic> album) {
    switch (action) {
      case 'play':
        _playAlbum(album);
        break;
      case 'shuffle':
        _shuffleAlbum(album);
        break;
      case 'info':
        _showAlbumInfo(album);
        break;
    }
  }

  void _handleTrackAction(String action, AudioModel track) {
    switch (action) {
      case 'play':
        _playTrack(track);
        break;
      case 'add_to_queue':
        _addToQueue(track);
        break;
      case 'extract':
        _demonstrateMediaExtraction(track);
        break;
      case 'info':
        _showTrackInfo(track);
        break;
    }
  }

  void _handleVideoAction(String action, VideoModel video) {
    switch (action) {
      case 'play':
        _playVideo(video);
        break;
      case 'share':
        _shareVideo(video);
        break;
      case 'info':
        _showVideoInfo(video);
        break;
    }
  }

  void _handleDocumentAction(String action, DocumentModel document) {
    switch (action) {
      case 'open':
        _openDocument(document);
        break;
      case 'share':
        _shareDocument(document);
        break;
      case 'info':
        _showDocumentInfo(document);
        break;
    }
  }

  void _handleFolderAction(String action, FolderModel folder) {
    switch (action) {
      case 'open':
        _openFolder(folder);
        break;
      case 'info':
        _showFolderInfo(folder);
        break;
    }
  }

  void _handleFolderActionFromMap(String action, Map<String, dynamic> folder) {
    switch (action) {
      case 'open':
        _navigateToFolder(folder);
        break;
      case 'info':
        _showFolderInfoFromMap(folder);
        break;
    }
  }

  // Real action implementations
  Future<void> _playAlbum(Map<String, dynamic> album) async {
    try {
      // Get tracks from this album
      final albumTracks = _audios
          .where((track) =>
              track.album == album['album'] && track.artist == album['artist'])
          .toList();

      if (albumTracks.isNotEmpty) {
        await _mediaPlayer.loadPlaylist(albumTracks);
        await _mediaPlayer.play();
        _showSnackBar('Playing album: ${album['album']}');
        if (kDebugMode) {
          print(
              '🎵 Playing album: ${album['album']} by ${album['artist']} (${albumTracks.length} tracks)');
        }

        // Try to extract artwork for the first track in the album (iOS/macOS)
        try {
          bool canExport = await _mediaBrowser.canExportTrack();
          if (canExport && albumTracks.isNotEmpty) {
            final firstTrack = albumTracks.first;
            if (kDebugMode) {
              print(
                  '🎨 Attempting to extract artwork for album: ${album['album']}');
            }
            final artworkResult =
                await _mediaBrowser.extractArtwork(firstTrack.id.toString());
            if (artworkResult['success'] == true) {
              if (kDebugMode) {
                print(
                    '✅ Album artwork extracted successfully: ${artworkResult['filePath']}');
              }
              _showSnackBar('Album artwork extracted: ${album['album']}');
            } else {
              if (kDebugMode) {
                print(
                    '⚠️ Album artwork extraction failed: ${artworkResult['error']}');
              }
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ Error extracting album artwork: $e');
          }
        }
      } else {
        _showSnackBar('No tracks found for album: ${album['album']}');
      }
    } catch (e) {
      _showSnackBar('Error playing album: $e');
      if (kDebugMode) {
        print('❌ Error playing album: $e');
      }
    }
  }

  Future<void> _shuffleAlbum(Map<String, dynamic> album) async {
    try {
      // Get tracks from this album
      final albumTracks = _audios
          .where((track) =>
              track.album == album['album'] && track.artist == album['artist'])
          .toList();

      if (albumTracks.isNotEmpty) {
        // Shuffle the tracks
        albumTracks.shuffle();
        await _mediaPlayer.loadPlaylist(albumTracks);
        await _mediaPlayer.play();
        _showSnackBar('Shuffle playing album: ${album['album']}');
        if (kDebugMode) {
          print(
              '🔀 Shuffle playing album: ${album['album']} by ${album['artist']} (${albumTracks.length} tracks)');
        }
      } else {
        _showSnackBar('No tracks found for album: ${album['album']}');
      }
    } catch (e) {
      _showSnackBar('Error shuffle playing album: $e');
      if (kDebugMode) {
        print('❌ Error shuffle playing album: $e');
      }
    }
  }

  Future<void> _browseArtist(Map<String, dynamic> artist) async {
    try {
      // Get tracks from this artist
      final artistTracks =
          _audios.where((track) => track.artist == artist['artist']).toList();

      if (artistTracks.isNotEmpty) {
        // Navigate to artist tracks
        _navigateToArtist(artist, artistTracks);
      } else {
        _showSnackBar('No tracks found for artist: ${artist['artist']}');
      }
    } catch (e) {
      _showSnackBar('Error browsing artist: $e');
      if (kDebugMode) {
        print('❌ Error browsing artist: $e');
      }
    }
  }

  void _navigateToAlbum(Map<String, dynamic> album) async {
    try {
      // Get tracks from this album
      final albumTracks = _audios
          .where((track) =>
              track.album == album['album'] && track.artist == album['artist'])
          .toList();

      if (albumTracks.isNotEmpty) {
        // Add to navigation stack
        _navigationStack.add(NavigationItem(
          title: album['album'] ?? 'Unknown Album',
          type: 'album',
          data: album,
          items: albumTracks,
        ));

        // Update current data
        _currentData = albumTracks;

        setState(() {});
        _showSnackBar('Browsing album: ${album['album']}');
      } else {
        _showSnackBar('No tracks found for album: ${album['album']}');
      }
    } catch (e) {
      _showSnackBar('Error browsing album: $e');
      if (kDebugMode) {
        print('❌ Error browsing album: $e');
      }
    }
  }

  void _navigateToArtist(Map<String, dynamic> artist, List<AudioModel> tracks) {
    // Add to navigation stack
    _navigationStack.add(NavigationItem(
      title: artist['artist'] ?? 'Unknown Artist',
      type: 'artist',
      data: artist,
      items: tracks,
    ));

    // Update current data
    _currentData = tracks;

    setState(() {});
    _showSnackBar('Browsing artist: ${artist['artist']}');
  }

  void _navigateToFolder(Map<String, dynamic> folder) async {
    try {
      // Get the current media type context
      final currentMediaType = _getCurrentMediaType();

      // Determine browsing mode based on current media type
      FolderBrowsingMode browsingMode;
      switch (currentMediaType) {
        case 'audio':
          browsingMode = FolderBrowsingMode.audio;
          break;
        case 'video':
          browsingMode = FolderBrowsingMode.video;
          break;
        case 'document':
          browsingMode = FolderBrowsingMode.document;
          break;
        case 'folder':
          browsingMode = FolderBrowsingMode.foldersOnly;
          break;
        default:
          browsingMode = FolderBrowsingMode.all;
          break;
      }

      // Query contents of this folder with context-aware browsing mode
      final folderContents = await _mediaBrowser.queryFoldersFromPath(
        folder['path'],
        browsingMode: browsingMode,
      );

      if (folderContents.isNotEmpty) {
        // Add to navigation stack
        _navigationStack.add(NavigationItem(
          title: folder['name'] ?? 'Unknown Folder',
          type: 'folder',
          data: folder,
          items: folderContents,
        ));

        // Update current data
        _currentData = folderContents;

        setState(() {});
        _showSnackBar(
            'Browsing folder: ${folder['name']} (${currentMediaType})');
      } else {
        _showSnackBar('Folder is empty: ${folder['name']}');
      }
    } catch (e) {
      _showSnackBar('Error browsing folder: $e');
      if (kDebugMode) {
        print('❌ Error browsing folder: $e');
      }
    }
  }

  void _navigateBack() {
    if (_navigationStack.isNotEmpty) {
      _navigationStack.removeLast();

      if (_navigationStack.isNotEmpty) {
        // Go back to previous level
        final previousItem = _navigationStack.last;
        _currentData = previousItem.items;
      } else {
        // Go back to root
        _currentData = [];
      }

      setState(() {});
    }
  }

  void _navigateToRoot() {
    _navigationStack.clear();
    _currentData = [];
    setState(() {});
  }

  String _getCurrentMediaType() {
    // If we're in navigation context, determine from the current tab
    if (_navigationStack.isNotEmpty) {
      return _getMediaTypeFromTabIndex(_selectedTabIndex);
    }

    // Otherwise, determine from the current tab
    return _getMediaTypeFromTabIndex(_selectedTabIndex);
  }

  String _getMediaTypeFromTabIndex(int tabIndex) {
    switch (tabIndex) {
      case 0: // Albums
      case 1: // Artists
      case 2: // Genres
      case 3: // Tracks
        return 'audio';
      case 4: // Videos
        return 'video';
      case 5: // Documents
        return 'document';
      case 6: // Folders
        return 'folder';
      default:
        return 'all';
    }
  }

  Widget _buildBreadcrumbTitle() {
    if (_navigationStack.isEmpty) {
      return const Text(
        'Local',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      );
    }

    return Row(
      children: [
        GestureDetector(
          onTap: _navigateToRoot,
          child: const Text(
            'Local',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
        ..._navigationStack
            .map((item) => [
                  const Text(' > ', style: TextStyle(color: Colors.white54)),
                  GestureDetector(
                    onTap: () => _navigateToItem(item),
                    child: Text(
                      item.title,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ])
            .expand((x) => x),
      ],
    );
  }

  void _navigateToItem(NavigationItem item) {
    // Find the index of this item in the navigation stack
    final index = _navigationStack.indexOf(item);
    if (index != -1) {
      // Remove all items after this one
      _navigationStack.removeRange(index + 1, _navigationStack.length);
      _currentData = item.items;
      setState(() {});
    }
  }

  void _showAlbumInfo(Map<String, dynamic> album) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(album['album'] ?? 'Unknown Album'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Artist: ${album['artist'] ?? 'Unknown'}'),
            Text('Songs: ${album['num_of_songs'] ?? 0}'),
            Text('Year: ${album['year'] ?? 'Unknown'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _playTrack(AudioModel track) async {
    try {
      // Check if we can export this track (iOS/macOS only)
      bool canExport = false;
      try {
        canExport = await _mediaBrowser.canExportTrack();
        if (kDebugMode) {
          print('🎵 Can export track: $canExport');
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Could not check export capability: $e');
        }
      }

      // Find the track index in current playlist
      final trackIndex = _audios.indexWhere((t) => t.id == track.id);

      if (trackIndex != -1) {
        // Load the entire playlist and play the specific track
        await _mediaPlayer.loadPlaylist(_audios, startIndex: trackIndex);
        await _mediaPlayer.play();
        _showSnackBar('Playing: ${track.title}');
        if (kDebugMode) {
          print('🎵 Playing track: ${track.title} by ${track.artist}');
        }
      } else {
        // Play single track
        await _mediaPlayer.loadPlaylist([track]);
        await _mediaPlayer.play();
        _showSnackBar('Playing: ${track.title}');
        if (kDebugMode) {
          print('🎵 Playing single track: ${track.title} by ${track.artist}');
        }
      }

      // Try to extract artwork if export is supported (iOS/macOS)
      if (canExport) {
        try {
          if (kDebugMode) {
            print('🎨 Attempting to extract artwork for track: ${track.title}');
          }
          final artworkResult =
              await _mediaBrowser.extractArtwork(track.id.toString());
          if (artworkResult['success'] == true) {
            if (kDebugMode) {
              print(
                  '✅ Artwork extracted successfully: ${artworkResult['filePath']}');
            }
            _showSnackBar('Artwork extracted for: ${track.title}');
          } else {
            if (kDebugMode) {
              print('⚠️ Artwork extraction failed: ${artworkResult['error']}');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ Error extracting artwork: $e');
          }
        }

        // Try to export track (iOS/macOS)
        try {
          if (kDebugMode) {
            print('📤 Attempting to export track: ${track.title}');
          }
          final exportResult =
              await _mediaBrowser.exportTrack(track.id.toString());
          if (exportResult['success'] == true) {
            if (kDebugMode) {
              print(
                  '✅ Track exported successfully: ${exportResult['filePath']}');
            }
            _showSnackBar('Track exported: ${track.title}');
          } else {
            if (kDebugMode) {
              print('⚠️ Track export failed: ${exportResult['error']}');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ Error exporting track: $e');
          }
        }
      }
    } catch (e) {
      _showSnackBar('Error playing track: $e');
      if (kDebugMode) {
        print('❌ Error playing track: $e');
      }
    }
  }

  Future<void> _addToQueue(AudioModel track) async {
    try {
      await _mediaPlayer.addToPlaylist([track]);
      _showSnackBar('Added to queue: ${track.title}');
      if (kDebugMode) {
        print('➕ Added to queue: ${track.title} by ${track.artist}');
      }
    } catch (e) {
      _showSnackBar('Error adding to queue: $e');
      if (kDebugMode) {
        print('❌ Error adding to queue: $e');
      }
    }
  }

  /// Demonstrate all MediaExtractionService functions for a track
  Future<void> _demonstrateMediaExtraction(AudioModel track) async {
    try {
      if (kDebugMode) {
        print(
            '🔧 Starting MediaExtractionService demonstration for: ${track.title}');
      }
      _showSnackBar('Testing media extraction for: ${track.title}');

      // 1. Check if export is supported
      if (kDebugMode) {
        print('1️⃣ Checking export capability...');
      }
      bool canExport = false;
      try {
        canExport = await _mediaBrowser.canExportTrack();
        if (kDebugMode) {
          print('✅ Export capability check: $canExport');
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Export capability check failed: $e');
        }
        _showSnackBar('Export not supported on this platform');
        return;
      }

      if (!canExport) {
        if (kDebugMode) {
          print('⚠️ Export not supported on this platform');
        }
        _showSnackBar('Media extraction not supported on this platform');
        return;
      }

      // 2. Get track extension
      if (kDebugMode) {
        print('2️⃣ Getting track extension...');
      }
      try {
        final extension =
            await _mediaBrowser.getTrackExtension(track.id.toString());
        if (kDebugMode) {
          print('✅ Track extension: $extension');
        }
      } catch (e) {
        print('❌ Failed to get track extension: $e');
      }

      // 3. Extract artwork
      print('3️⃣ Extracting artwork...');
      try {
        final artworkResult =
            await _mediaBrowser.extractArtwork(track.id.toString());
        if (artworkResult['success'] == true) {
          print('✅ Artwork extracted: ${artworkResult['filePath']}');
          _showSnackBar('Artwork extracted successfully!');
        } else {
          print('⚠️ Artwork extraction failed: ${artworkResult['error']}');
        }
      } catch (e) {
        print('❌ Artwork extraction error: $e');
      }

      // 4. Export track
      print('4️⃣ Exporting track...');
      try {
        final exportResult =
            await _mediaBrowser.exportTrack(track.id.toString());
        if (exportResult['success'] == true) {
          print('✅ Track exported: ${exportResult['filePath']}');
          _showSnackBar('Track exported successfully!');
        } else {
          print('⚠️ Track export failed: ${exportResult['error']}');
        }
      } catch (e) {
        print('❌ Track export error: $e');
      }

      // 5. Export track with artwork
      print('5️⃣ Exporting track with artwork...');
      try {
        final exportWithArtworkResult =
            await _mediaBrowser.exportTrackWithArtwork(track.id.toString());
        if (exportWithArtworkResult['success'] == true) {
          print(
              '✅ Track with artwork exported: ${exportWithArtworkResult['filePath']}');
          _showSnackBar('Track with artwork exported successfully!');
        } else {
          print(
              '⚠️ Track with artwork export failed: ${exportWithArtworkResult['error']}');
        }
      } catch (e) {
        print('❌ Track with artwork export error: $e');
      }

      print('🎉 MediaExtractionService demonstration completed!');
      _showSnackBar('Media extraction demonstration completed!');
    } catch (e) {
      print('❌ MediaExtractionService demonstration failed: $e');
      _showSnackBar('Media extraction demonstration failed: $e');
    }
  }

  void _showTrackInfo(AudioModel track) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(track.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Artist: ${track.artist}'),
            Text('Album: ${track.album}'),
            Text('Duration: ${_formatDuration(track.duration)}'),
            Text('Genre: ${track.genre}'),
            Text('Year: ${track.year}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _playVideo(VideoModel video) {
    _showSnackBar('Playing video: ${video.title}');
    // Note: For actual video playback, you would integrate with a video player
    print('🎥 Would play video: ${video.title}');
  }

  void _shareVideo(VideoModel video) {
    _showSnackBar('Sharing video: ${video.title}');
    // Note: For actual sharing, you would use the share_plus package
    print('📤 Would share video: ${video.title}');
  }

  void _showVideoInfo(VideoModel video) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(video.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Duration: ${_formatDuration(video.duration)}'),
            Text('Resolution: ${video.width}x${video.height}'),
            Text('Size: ${_formatFileSize(video.size)}'),
            Text('Path: ${video.data}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _openDocument(DocumentModel document) {
    _showSnackBar('Opening document: ${document.title}');
    // Note: For actual document opening, you would use url_launcher or similar
    print('📄 Would open document: ${document.title}');
  }

  void _shareDocument(DocumentModel document) {
    _showSnackBar('Sharing document: ${document.title}');
    // Note: For actual sharing, you would use the share_plus package
    print('📤 Would share document: ${document.title}');
  }

  void _showDocumentInfo(DocumentModel document) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(document.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${document.mimeType}'),
            Text('Size: ${_formatFileSize(document.size)}'),
            Text('Path: ${document.data}'),
            Text('Date: ${document.dateAdded}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _openFolder(FolderModel folder) {
    _showSnackBar('Opening folder: ${folder.name}');
    // Note: For actual folder navigation, you would implement a folder browser
    print('📁 Would open folder: ${folder.name} at ${folder.path}');
  }

  void _showFolderInfo(FolderModel folder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(folder.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Path: ${folder.path}'),
            Text('Files: ${folder.fileCount}'),
            Text('Date: ${folder.dateCreated}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showFolderInfoFromMap(Map<String, dynamic> folder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(folder['name'] ?? 'Unknown Folder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Path: ${folder['path'] ?? 'Unknown'}'),
            Text('Files: ${folder['file_count'] ?? 0}'),
            Text('Directories: ${folder['directory_count'] ?? 0}'),
            Text('Date: ${folder['date_created'] ?? 'Unknown'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.blue,
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Filtering methods for each media type
  List<Map<String, dynamic>> _getFilteredAlbums() {
    if (_searchQuery.isEmpty) return _albums;
    return _albums.where((album) {
      final albumName = (album['album'] ?? '').toString().toLowerCase();
      final artistName = (album['artist'] ?? '').toString().toLowerCase();
      return albumName.contains(_searchQuery) ||
          artistName.contains(_searchQuery);
    }).toList();
  }

  List<Map<String, dynamic>> _getFilteredArtists() {
    if (_searchQuery.isEmpty) return _artists;
    return _artists.where((artist) {
      final artistName = (artist['artist'] ?? '').toString().toLowerCase();
      return artistName.contains(_searchQuery);
    }).toList();
  }

  List<Map<String, dynamic>> _getFilteredGenres() {
    if (_searchQuery.isEmpty) return _genres;
    return _genres.where((genre) {
      final genreName = (genre['genre'] ?? '').toString().toLowerCase();
      return genreName.contains(_searchQuery);
    }).toList();
  }

  List<AudioModel> _getFilteredTracks() {
    if (_searchQuery.isEmpty) return _audios;
    return _audios.where((track) {
      final title = track.title.toLowerCase();
      final artist = track.artist.toLowerCase();
      final album = track.album.toLowerCase();
      return title.contains(_searchQuery) ||
          artist.contains(_searchQuery) ||
          album.contains(_searchQuery);
    }).toList();
  }

  List<VideoModel> _getFilteredVideos() {
    if (_searchQuery.isEmpty) return _videos;
    return _videos.where((video) {
      final title = video.title.toLowerCase();
      final displayName = video.displayName.toLowerCase();
      return title.contains(_searchQuery) || displayName.contains(_searchQuery);
    }).toList();
  }

  List<DocumentModel> _getFilteredDocuments() {
    if (_searchQuery.isEmpty) return _documents;
    return _documents.where((doc) {
      final title = doc.title.toLowerCase();
      final displayName = doc.displayName.toLowerCase();
      return title.contains(_searchQuery) || displayName.contains(_searchQuery);
    }).toList();
  }

  List<FolderModel> _getFilteredFolders() {
    if (_searchQuery.isEmpty) return _folders;
    return _folders.where((folder) {
      final name = folder.name.toLowerCase();
      final path = folder.path.toLowerCase();
      return name.contains(_searchQuery) || path.contains(_searchQuery);
    }).toList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load media data after the widget tree is built and context is available
    if (!_hasInitialized && !_isLoading) {
      _hasInitialized = true;
      // Use a small delay to ensure the context is fully available
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _loadMediaData();
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> initPlatformState() async {
    try {
      print('🔧 Testing platform version...');
      final version = await _mediaBrowser.getPlatformVersion();
      print('🔧 Platform version: $version');
    } on PlatformException catch (e) {
      print('💥 Platform version error: $e');
    } catch (e) {
      print('💥 General error: $e');
    }
  }

  Future<void> _initializeApp() async {
    print('🚀 Initializing app - requesting permissions and loading media...');

    // Wait a bit for the UI to be ready
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      // First, request all permissions automatically
      await _requestAllPermissionsOnLaunch();

      // Wait a bit more for permissions to be processed
      await Future.delayed(const Duration(milliseconds: 1000));

      // Then load media data
      await _loadMediaData();

      print('✅ App initialization completed successfully');
    } catch (e) {
      print('❌ Error during app initialization: $e');
      // Still try to load media data even if permission request failed
      await _loadMediaData();
    }
  }

  Future<void> _requestAllPermissionsOnLaunch() async {
    print('🔐 Checking and requesting permissions on app launch...');

    try {
      // Request each permission type individually
      final permissionTypes = [
        MediaType.audio,
        MediaType.video,
        MediaType.document,
        MediaType.folder,
      ];

      List<String> grantedPermissions = [];
      List<String> deniedPermissions = [];

      for (final mediaType in permissionTypes) {
        try {
          print('🔐 Checking permission for: $mediaType');

          // First, check current permission status
          final checkResult = await _mediaBrowser.checkPermissions(mediaType);
          print('📋 Current status for $mediaType: ${checkResult.status}');

          if (checkResult.isGranted) {
            grantedPermissions.add(mediaType.toString());
            print('✅ Permission already granted: $mediaType');
            continue;
          }

          // Check if we can request this permission
          final missingPermissions = checkResult.missingPermissions ?? [];
          if (missingPermissions.isEmpty) {
            print('⚠️ No missing permissions for $mediaType, but not granted');
            continue;
          }

          final canRequest =
              missingPermissions.any((permission) => permission.canRequest);
          if (!canRequest) {
            deniedPermissions
                .add('${mediaType.toString()} (permanently denied)');
            print('❌ Permission permanently denied: $mediaType');
            continue;
          }

          // Request permission for this specific type
          print('🔐 Requesting permission for: $mediaType');
          final result = await _mediaBrowser.requestPermissions(mediaType);
          print(
              '📋 Request result for $mediaType: ${result.status} - ${result.message}');

          if (result.isGranted) {
            grantedPermissions.add(mediaType.toString());
            print('✅ Permission granted: $mediaType');
          } else {
            deniedPermissions.add(mediaType.toString());
            print('❌ Permission denied: $mediaType');
          }
        } catch (e) {
          deniedPermissions.add('${mediaType.toString()} (Error: $e)');
          print('💥 Error handling permission for $mediaType: $e');
        }
      }

      print('📊 Permission summary:');
      print('✅ Granted: ${grantedPermissions.join(", ")}');
      print('❌ Denied: ${deniedPermissions.join(", ")}');

      // If some permissions were denied, show a dialog after a delay
      if (deniedPermissions.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 2000));
        if (mounted) {
          _showPermissionDeniedDialog(deniedPermissions);
        }
      }
    } catch (e) {
      print('💥 Error during permission request: $e');
    }
  }

  void _showPermissionDeniedDialog(List<String> deniedPermissions) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Some Permissions Denied'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Some permissions were denied. The app will work with limited functionality:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ...deniedPermissions.map((permission) => Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 4),
                  child: Text('• ${_getPermissionDescription(permission)}'),
                )),
            const SizedBox(height: 16),
            const Text(
              'You can grant these permissions later in your device settings or by tapping "Retry" below.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _requestAllPermissionsOnLaunch();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadMediaData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check permissions first - only for selected media types
      final permissionTypes = _selectedMediaTypes.entries
          .where((entry) => entry.value == true)
          .map((entry) => entry.key)
          .toList();

      // Check permissions for each media type (for logging purposes)
      for (final mediaType in permissionTypes) {
        try {
          print('🔍 Checking permission for: $mediaType');
          final result = await _mediaBrowser.checkPermissions(mediaType);
          print(
              '📋 Permission result for $mediaType: ${result.status} - ${result.message}');
          if (!result.isGranted) {
            print('❌ Missing permission: $mediaType');
          } else {
            print('✅ Permission granted: $mediaType');
          }
        } catch (e) {
          print('💥 Error checking permission for $mediaType: $e');
        }
      }

      // Only load media types for which permissions are granted
      print('🔍 Loading media types with granted permissions...');

      final List<Future> loadTasks = [];
      final List<String> taskTypes = [];

      // Check each media type individually and only load if permission is granted
      if (_selectedMediaTypes[MediaType.audio] == true) {
        try {
          final audioPermission =
              await _mediaBrowser.checkPermissions(MediaType.audio);

          bool shouldLoadAudio = false;

          if (audioPermission.isGranted) {
            shouldLoadAudio = true;
            print('✅ Loading audio media (permission granted)');
          } else {
            // Check if we can request permission (notDetermined state)
            final missingPermissions = audioPermission.missingPermissions ?? [];
            final canRequest =
                missingPermissions.any((permission) => permission.canRequest);

            if (canRequest) {
              print('🔐 Requesting audio permission...');
              final requestResult =
                  await _mediaBrowser.requestPermissions(MediaType.audio);
              if (requestResult.isGranted) {
                shouldLoadAudio = true;
                print(
                    '✅ Loading audio media (permission granted after request)');
              } else {
                print(
                    '❌ Skipping audio media (permission denied after request)');
              }
            } else {
              print('❌ Skipping audio media (permission permanently denied)');
            }
          }

          // Only add audio loading tasks once, regardless of how permission was obtained
          if (shouldLoadAudio) {
            loadTasks.addAll([
              _mediaBrowser.queryAudios(),
              _mediaBrowser.queryAlbums(),
              _mediaBrowser.queryArtists(),
              _mediaBrowser.queryGenres(),
            ]);
            taskTypes.addAll(['audios', 'albums', 'artists', 'genres']);
          }
        } catch (e) {
          print('❌ Error handling audio permission: $e');
        }
      }

      if (_selectedMediaTypes[MediaType.video] == true) {
        try {
          final videoPermission =
              await _mediaBrowser.checkPermissions(MediaType.video);

          bool shouldLoadVideo = false;

          if (videoPermission.isGranted) {
            shouldLoadVideo = true;
            print('✅ Loading video media (permission granted)');
          } else {
            // Check if we can request permission (notDetermined state)
            final missingPermissions = videoPermission.missingPermissions ?? [];
            final canRequest =
                missingPermissions.any((permission) => permission.canRequest);

            if (canRequest) {
              print('🔐 Requesting video permission...');
              final requestResult =
                  await _mediaBrowser.requestPermissions(MediaType.video);
              if (requestResult.isGranted) {
                shouldLoadVideo = true;
                print(
                    '✅ Loading video media (permission granted after request)');
              } else {
                print(
                    '❌ Skipping video media (permission denied after request)');
              }
            } else {
              print('❌ Skipping video media (permission permanently denied)');
            }
          }

          // Only add video loading task once, regardless of how permission was obtained
          if (shouldLoadVideo) {
            loadTasks.add(_mediaBrowser.queryVideos());
            taskTypes.add('videos');
          }
        } catch (e) {
          print('❌ Error handling video permission: $e');
        }
      }

      if (_selectedMediaTypes[MediaType.document] == true) {
        try {
          final documentPermission =
              await _mediaBrowser.checkPermissions(MediaType.document);

          bool shouldLoadDocument = false;

          if (documentPermission.isGranted) {
            shouldLoadDocument = true;
            print('✅ Loading document media (permission granted)');
          } else {
            // Check if we can request permission (notDetermined state)
            final missingPermissions =
                documentPermission.missingPermissions ?? [];
            final canRequest =
                missingPermissions.any((permission) => permission.canRequest);

            if (canRequest) {
              print('🔐 Requesting document permission...');
              final requestResult =
                  await _mediaBrowser.requestPermissions(MediaType.document);
              if (requestResult.isGranted) {
                shouldLoadDocument = true;
                print(
                    '✅ Loading document media (permission granted after request)');
              } else {
                print(
                    '❌ Skipping document media (permission denied after request)');
              }
            } else {
              print(
                  '❌ Skipping document media (permission permanently denied)');
            }
          }

          // Only add document loading task once, regardless of how permission was obtained
          if (shouldLoadDocument) {
            loadTasks.add(_mediaBrowser.queryDocuments());
            taskTypes.add('documents');
          }
        } catch (e) {
          print('❌ Error handling document permission: $e');
        }
      }

      if (_selectedMediaTypes[MediaType.folder] == true) {
        try {
          final folderPermission =
              await _mediaBrowser.checkPermissions(MediaType.folder);

          bool shouldLoadFolder = false;

          if (folderPermission.isGranted) {
            shouldLoadFolder = true;
            print('✅ Loading folder media (permission granted)');
          } else {
            // Check if we can request permission (notDetermined state)
            final missingPermissions =
                folderPermission.missingPermissions ?? [];
            final canRequest =
                missingPermissions.any((permission) => permission.canRequest);

            if (canRequest) {
              print('🔐 Requesting folder permission...');
              final requestResult =
                  await _mediaBrowser.requestPermissions(MediaType.folder);
              if (requestResult.isGranted) {
                shouldLoadFolder = true;
                print(
                    '✅ Loading folder media (permission granted after request)');
              } else {
                print(
                    '❌ Skipping folder media (permission denied after request)');
              }
            } else {
              print('❌ Skipping folder media (permission permanently denied)');
            }
          }

          // Only add folder loading task once, regardless of how permission was obtained
          if (shouldLoadFolder) {
            loadTasks.add(_mediaBrowser.queryFolders());
            taskTypes.add('folders');
          }
        } catch (e) {
          print('❌ Error handling folder permission: $e');
        }
      }

      if (loadTasks.isNotEmpty) {
        final results = await Future.wait(loadTasks);

        setState(() {
          int resultIndex = 0;

          // Process results based on what was actually loaded (permission-granted media types)
          if (_selectedMediaTypes[MediaType.audio] == true &&
              taskTypes.contains('audios')) {
            _audios = results[resultIndex++] as List<AudioModel>;
            _albums = results[resultIndex++] as List<Map<String, dynamic>>;
            _artists = results[resultIndex++] as List<Map<String, dynamic>>;
            _genres = results[resultIndex++] as List<Map<String, dynamic>>;
          } else {
            _audios = [];
            _albums = [];
            _artists = [];
            _genres = [];
          }

          if (_selectedMediaTypes[MediaType.video] == true &&
              taskTypes.contains('videos')) {
            _videos = results[resultIndex++] as List<VideoModel>;
          } else {
            _videos = [];
          }

          if (_selectedMediaTypes[MediaType.document] == true &&
              taskTypes.contains('documents')) {
            _documents = results[resultIndex++] as List<DocumentModel>;
          } else {
            _documents = [];
          }

          if (_selectedMediaTypes[MediaType.folder] == true &&
              taskTypes.contains('folders')) {
            _folders = results[resultIndex++] as List<FolderModel>;
          } else {
            _folders = [];
          }

          print(
              '📁 Loaded media: ${_audios.length} tracks, ${_albums.length} albums, ${_artists.length} artists');
          print(
              '📁 Loaded media: ${_videos.length} videos, ${_documents.length} documents, ${_folders.length} folders');
        });
      } else {
        // No media loaded due to missing permissions
        print(
            '⚠️ No media loaded - all selected media types require permissions');
        setState(() {
          _audios = [];
          _albums = [];
          _artists = [];
          _genres = [];
          _videos = [];
          _documents = [];
          _folders = [];
        });
      }
    } on PermissionError catch (e) {
      // Handle permission errors specifically
      _showPermissionRequestDialog(e);
    } on MediaError catch (e) {
      // Handle other media errors
      _showErrorDialog('Media Error: ${e.message}');
    } catch (e) {
      // Handle any other errors
      _showErrorDialog('Failed to load media: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getPermissionDescription(String permission) {
    switch (permission.toLowerCase()) {
      case 'mediatype.audio':
        return 'Audio: Access to music library and audio files';
      case 'mediatype.video':
        return 'Video: Access to photo library and video files';
      case 'mediatype.document':
        return 'Documents: Access to document files (usually granted automatically)';
      case 'mediatype.folder':
        return 'Folders: Access to folder structure (usually granted automatically)';
      default:
        return permission;
    }
  }

  void _showPermissionRequestDialog(PermissionError error) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(error.message),
            const SizedBox(height: 16),
            const Text(
              'This app needs access to your media files to display them. Please grant the required permissions.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _requestPermissions();
            },
            child: const Text('Grant Permissions'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestPermissions() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Request each permission type individually
      final permissionTypes = [
        MediaType.audio,
        MediaType.video,
        MediaType.document,
        MediaType.folder,
      ];

      List<String> grantedPermissions = [];
      List<String> deniedPermissions = [];

      for (final mediaType in permissionTypes) {
        try {
          print('🔐 Requesting permission for: $mediaType');
          // Request permission for this specific type
          final result = await _mediaBrowser.requestPermissions(mediaType);
          print(
              '📋 Request result for $mediaType: ${result.status} - ${result.message}');

          if (result.isGranted) {
            grantedPermissions.add(mediaType.toString());
            print('✅ Permission granted: $mediaType');
          } else {
            deniedPermissions.add(mediaType.toString());
            print('❌ Permission denied: $mediaType');
          }
        } catch (e) {
          deniedPermissions.add('${mediaType.toString()} (Error: $e)');
          print('💥 Error requesting permission for $mediaType: $e');
        }
      }

      // Check overall permission status after all requests
      final overallResult = await _mediaBrowser.checkPermissions(MediaType.all);

      if (overallResult.isGranted) {
        // All permissions granted, reload media data
        await _loadMediaData();
      } else {
        // Some permissions still denied, show status
        _showPermissionStatusDialog(
            grantedPermissions, deniedPermissions, overallResult);
      }
    } catch (e) {
      _showErrorDialog('Failed to request permissions: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showPermissionStatusDialog(
    List<String> grantedPermissions,
    List<String> deniedPermissions,
    PermissionResult overallResult,
  ) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Status'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (grantedPermissions.isNotEmpty) ...[
                const Text(
                  '✅ Granted Permissions:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 8),
                ...grantedPermissions.map((permission) => Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 4),
                      child: Text('• $permission'),
                    )),
                const SizedBox(height: 16),
              ],
              if (deniedPermissions.isNotEmpty) ...[
                const Text(
                  '❌ Denied Permissions:',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                ),
                const SizedBox(height: 8),
                ...deniedPermissions.map((permission) => Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 4),
                      child: Text('• $permission'),
                    )),
                const SizedBox(height: 16),
              ],
              if (overallResult.message != null) ...[
                const Text(
                  'Status:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(overallResult.message!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          if (deniedPermissions.isNotEmpty)
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _requestPermissions();
              },
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  String _getMediaTypeDisplayName(MediaType mediaType) {
    switch (mediaType) {
      case MediaType.audio:
        return 'Audio';
      case MediaType.video:
        return 'Video';
      case MediaType.document:
        return 'Documents';
      case MediaType.folder:
        return 'Folders';
      case MediaType.all:
        return 'All Media';
    }
  }

  String _getMediaTypeDescription(MediaType mediaType) {
    switch (mediaType) {
      case MediaType.audio:
        return 'Music files, albums, artists, genres';
      case MediaType.video:
        return 'Video files and movies';
      case MediaType.document:
        return 'PDFs, text files, presentations';
      case MediaType.folder:
        return 'File system folders';
      case MediaType.all:
        return 'All media types combined';
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  List<dynamic> _getCurrentData() {
    // If we're in a navigation context, return the current data
    if (_navigationStack.isNotEmpty) {
      return _currentData;
    }

    // Otherwise, return the root data based on selected tab
    switch (_selectedTabIndex) {
      case 0:
        return _getFilteredAlbums();
      case 1:
        return _getFilteredArtists();
      case 2:
        return _getFilteredGenres();
      case 3:
        return _getFilteredTracks();
      case 4:
        return _getFilteredVideos();
      case 5:
        return _getFilteredDocuments();
      case 6:
        return _getFilteredFolders();
      default:
        return [];
    }
  }

  String _getItemCount() {
    final data = _getCurrentData();
    final count = data.length;
    final type = _tabs[_selectedTabIndex];
    return '$count ${type}';
  }

  Widget _buildListItem(dynamic item, int index) {
    // If we're in navigation context, determine item type dynamically
    if (_navigationStack.isNotEmpty) {
      return _buildDynamicListItem(item);
    }

    // Otherwise, use tab-based logic
    switch (_selectedTabIndex) {
      case 0:
        return _buildAlbumItem(item as Map<String, dynamic>);
      case 1:
        return _buildArtistItem(item as Map<String, dynamic>);
      case 2:
        return _buildGenreItem(item as Map<String, dynamic>);
      case 3:
        return _buildTrackItem(item as AudioModel);
      case 4:
        return _buildVideoItem(item as VideoModel);
      case 5:
        return _buildDocumentItem(item as DocumentModel);
      case 6:
        return _buildFolderItem(item as FolderModel);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDynamicListItem(dynamic item) {
    // Determine item type based on runtime type
    // Plugin should have already filtered the data, so we just display what we get
    if (item is AudioModel) {
      return _buildTrackItem(item);
    } else if (item is VideoModel) {
      return _buildVideoItem(item);
    } else if (item is DocumentModel) {
      return _buildDocumentItem(item);
    } else if (item is FolderModel) {
      return _buildFolderItem(item);
    } else if (item is Map<String, dynamic>) {
      // Handle Map items (could be album, artist, genre, or folder data)
      if (item.containsKey('album')) {
        return _buildAlbumItem(item);
      } else if (item.containsKey('artist') && !item.containsKey('album')) {
        return _buildArtistItem(item);
      } else if (item.containsKey('genre')) {
        return _buildGenreItem(item);
      } else if (item.containsKey('path')) {
        // This is folder data from Map
        return _buildFolderItemFromMap(item);
      }
    }

    // Fallback
    return ListTile(
      title: Text('Unknown item: ${item.runtimeType}'),
      subtitle: Text('Type: ${item.runtimeType}'),
    );
  }

  Widget _buildAlbumItem(Map<String, dynamic> album) {
    return ListTile(
      leading: ArtworkWidget(
        id: album['id'] ?? 0,
        type: ArtworkType.album,
        size: ArtworkSize.small,
        width: 40,
        height: 40,
        placeholder: CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey[800],
          child: Icon(
            Icons.album,
            color: Colors.white54,
            size: 20,
          ),
        ),
        errorWidget: CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey[800],
          child: Icon(
            Icons.album,
            color: Colors.white54,
            size: 20,
          ),
        ),
      ),
      title: Text(album['album'] ?? 'Unknown Album'),
      subtitle: Text(
          '${album['artist'] ?? 'Unknown Artist'} • ${album['num_of_songs'] ?? 0} songs'),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: Colors.white),
        onSelected: (value) => _handleAlbumAction(value, album),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'play',
            child: Row(
              children: [
                Icon(Icons.play_arrow, color: Colors.blue),
                SizedBox(width: 8),
                Text('Play Album'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'shuffle',
            child: Row(
              children: [
                Icon(Icons.shuffle, color: Colors.green),
                SizedBox(width: 8),
                Text('Shuffle Play'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'info',
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange),
                SizedBox(width: 8),
                Text('Album Info'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistItem(Map<String, dynamic> artist) {
    final name = artist['artist'] ?? 'Unknown Artist';
    final initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';

    return ListTile(
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.grey[800],
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      title: Text(name),
      subtitle: Text('${artist['num_of_songs'] ?? 0} songs'),
      trailing: const Icon(Icons.more_vert),
    );
  }

  Widget _buildGenreItem(Map<String, dynamic> genre) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.grey[800],
        child: const Icon(Icons.music_note, color: Colors.white),
      ),
      title: Text(genre['genre'] ?? 'Unknown Genre'),
      subtitle: Text('${genre['num_of_songs'] ?? 0} songs'),
      trailing: const Icon(Icons.more_vert),
    );
  }

  Widget _buildTrackItem(AudioModel track) {
    return ListTile(
      leading: ArtworkWidget(
        id: track.id,
        type: ArtworkType.audio,
        size: ArtworkSize.small,
        width: 40,
        height: 40,
        placeholder: CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey[800],
          child: Icon(
            Icons.music_note,
            color: Colors.white54,
            size: 20,
          ),
        ),
        errorWidget: CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey[800],
          child: Icon(
            Icons.music_note,
            color: Colors.white54,
            size: 20,
          ),
        ),
      ),
      title: Text(track.title),
      subtitle: Text('${track.artist} • ${track.album}'),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: Colors.white),
        onSelected: (value) => _handleTrackAction(value, track),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'play',
            child: Row(
              children: [
                Icon(Icons.play_arrow, color: Colors.blue),
                SizedBox(width: 8),
                Text('Play'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'add_to_queue',
            child: Row(
              children: [
                Icon(Icons.queue_music, color: Colors.green),
                SizedBox(width: 8),
                Text('Add to Queue'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'extract',
            child: Row(
              children: [
                Icon(Icons.download, color: Colors.orange),
                SizedBox(width: 8),
                Text('Extract Media (iOS/macOS)'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'info',
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange),
                SizedBox(width: 8),
                Text('Track Info'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoItem(VideoModel video) {
    return ListTile(
      leading: ArtworkWidget(
        id: video.id,
        type: ArtworkType.video,
        size: ArtworkSize.small,
        width: 40,
        height: 40,
        placeholder: CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey[800],
          child: Icon(
            Icons.video_library,
            color: Colors.white54,
            size: 20,
          ),
        ),
        errorWidget: CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey[800],
          child: Icon(
            Icons.video_library,
            color: Colors.white54,
            size: 20,
          ),
        ),
      ),
      title: Text(video.title),
      subtitle: Text(
          '${video.width}x${video.height} • ${_formatDuration(video.duration)}'),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: Colors.white),
        onSelected: (value) => _handleVideoAction(value, video),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'play',
            child: Row(
              children: [
                Icon(Icons.play_arrow, color: Colors.blue),
                SizedBox(width: 8),
                Text('Play Video'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'share',
            child: Row(
              children: [
                Icon(Icons.share, color: Colors.green),
                SizedBox(width: 8),
                Text('Share'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'info',
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange),
                SizedBox(width: 8),
                Text('Video Info'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentItem(DocumentModel document) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.grey[800],
        child: const Icon(Icons.description, color: Colors.white),
      ),
      title: Text(document.title),
      subtitle:
          Text('${_formatFileSize(document.size)} • ${document.fileExtension}'),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: Colors.white),
        onSelected: (value) => _handleDocumentAction(value, document),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'open',
            child: Row(
              children: [
                Icon(Icons.open_in_new, color: Colors.blue),
                SizedBox(width: 8),
                Text('Open'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'share',
            child: Row(
              children: [
                Icon(Icons.share, color: Colors.green),
                SizedBox(width: 8),
                Text('Share'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'info',
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange),
                SizedBox(width: 8),
                Text('Document Info'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderItem(FolderModel folder) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.grey[800],
        child: const Icon(Icons.folder, color: Colors.white),
      ),
      title: Text(folder.name),
      subtitle:
          Text('${folder.fileCount} files • ${folder.directoryCount} folders'),
      onTap: () => _navigateToFolder(folder.toMap()),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: Colors.white),
        onSelected: (value) => _handleFolderAction(value, folder),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'open',
            child: Row(
              children: [
                Icon(Icons.folder_open, color: Colors.blue),
                SizedBox(width: 8),
                Text('Open Folder'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'info',
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange),
                SizedBox(width: 8),
                Text('Folder Info'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderItemFromMap(Map<String, dynamic> folder) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.grey[800],
        child: const Icon(Icons.folder, color: Colors.white),
      ),
      title: Text(folder['name'] ?? 'Unknown Folder'),
      subtitle: Text(
          '${folder['file_count'] ?? 0} files • ${folder['directory_count'] ?? 0} folders'),
      onTap: () => _navigateToFolder(folder),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: Colors.white),
        onSelected: (value) => _handleFolderActionFromMap(value, folder),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'open',
            child: Row(
              children: [
                Icon(Icons.folder_open, color: Colors.blue),
                SizedBox(width: 8),
                Text('Open Folder'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'info',
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange),
                SizedBox(width: 8),
                Text('Folder Info'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    final data = _getCurrentData();
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];
        return _buildGridItem(item, index);
      },
    );
  }

  Widget _buildGridItem(dynamic item, int index) {
    // If we're in navigation context, determine item type dynamically
    if (_navigationStack.isNotEmpty) {
      return _buildDynamicGridItem(item);
    }

    // Otherwise, use tab-based logic
    switch (_selectedTabIndex) {
      case 0:
        return _buildAlbumGridItem(item as Map<String, dynamic>);
      case 1:
        return _buildArtistGridItem(item as Map<String, dynamic>);
      case 2:
        return _buildGenreGridItem(item as Map<String, dynamic>);
      case 3:
        return _buildTrackGridItem(item as AudioModel);
      case 4:
        return _buildVideoGridItem(item as VideoModel);
      case 5:
        return _buildDocumentGridItem(item as DocumentModel);
      case 6:
        return _buildFolderGridItem(item as FolderModel);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDynamicGridItem(dynamic item) {
    // Determine item type based on runtime type
    // Plugin should have already filtered the data, so we just display what we get
    if (item is AudioModel) {
      return _buildTrackGridItem(item);
    } else if (item is VideoModel) {
      return _buildVideoGridItem(item);
    } else if (item is DocumentModel) {
      return _buildDocumentGridItem(item);
    } else if (item is FolderModel) {
      return _buildFolderGridItem(item);
    } else if (item is Map<String, dynamic>) {
      // Handle Map items (could be album, artist, genre, or folder data)
      if (item.containsKey('album')) {
        return _buildAlbumGridItem(item);
      } else if (item.containsKey('artist') && !item.containsKey('album')) {
        return _buildArtistGridItem(item);
      } else if (item.containsKey('genre')) {
        return _buildGenreGridItem(item);
      } else if (item.containsKey('path')) {
        // This is folder data from Map
        return _buildFolderGridItemFromMap(item);
      }
    }

    // Fallback
    return Card(
      color: Colors.grey[900],
      child: const Center(
        child: Text('Unknown item', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildAlbumGridItem(Map<String, dynamic> album) {
    return Card(
      color: Colors.grey[900],
      child: InkWell(
        onTap: () => _navigateToAlbum(album),
        onLongPress: () => _shuffleAlbum(album),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ArtworkWidget(
              id: album['id'] ?? 0,
              type: ArtworkType.album,
              size: ArtworkSize.medium,
              width: 80,
              height: 80,
              borderRadius: BorderRadius.circular(40),
              placeholder: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey[800],
                child: Icon(
                  Icons.album,
                  color: Colors.white54,
                  size: 40,
                ),
              ),
              errorWidget: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey[800],
                child: Icon(
                  Icons.album,
                  color: Colors.white54,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                album['album'] ?? 'Unknown Album',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${album['num_of_songs'] ?? 0} songs',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistGridItem(Map<String, dynamic> artist) {
    final name = artist['artist'] ?? 'Unknown Artist';
    final initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';

    return Card(
      color: Colors.grey[900],
      child: InkWell(
        onTap: () => _browseArtist(artist),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey[800],
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                name,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${artist['num_of_songs'] ?? 0} songs',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenreGridItem(Map<String, dynamic> genre) {
    return Card(
      color: Colors.grey[900],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.grey[800],
            child: const Icon(Icons.music_note, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              genre['genre'] ?? 'Unknown Genre',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${genre['num_of_songs'] ?? 0} songs',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTrackGridItem(AudioModel track) {
    return Card(
      color: Colors.grey[900],
      child: InkWell(
        onTap: () => _playTrack(track),
        onLongPress: () => _addToQueue(track),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ArtworkWidget(
              id: track.id,
              type: ArtworkType.audio,
              size: ArtworkSize.medium,
              width: 80,
              height: 80,
              borderRadius: BorderRadius.circular(40),
              placeholder: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey[800],
                child: const Icon(
                  Icons.music_note,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              errorWidget: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey[800],
                child: const Icon(
                  Icons.music_note,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                track.title,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              track.artist,
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoGridItem(VideoModel video) {
    return Card(
      color: Colors.grey[900],
      child: InkWell(
        onTap: () => _playVideo(video),
        onLongPress: () => _shareVideo(video),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ArtworkWidget(
              id: video.id,
              type: ArtworkType.video,
              size: ArtworkSize.medium,
              width: 80,
              height: 80,
              borderRadius: BorderRadius.circular(40),
              placeholder: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey[800],
                child: const Icon(
                  Icons.videocam,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              errorWidget: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey[800],
                child: const Icon(
                  Icons.videocam,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                video.title,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${video.width}x${video.height}',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentGridItem(DocumentModel document) {
    return Card(
      color: Colors.grey[900],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.grey[800],
            child: const Icon(Icons.description, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              document.title,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            document.fileExtension,
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFolderGridItem(FolderModel folder) {
    return Card(
      color: Colors.grey[900],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.grey[800],
            child: const Icon(Icons.folder, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              folder.name,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${folder.fileCount} files',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFolderGridItemFromMap(Map<String, dynamic> folder) {
    return Card(
      color: Colors.grey[900],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.grey[800],
            child: const Icon(Icons.folder, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              folder['name'] ?? 'Unknown Folder',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${folder['fileCount'] ?? 0} files',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search media...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
                autofocus: true,
              )
            : _buildBreadcrumbTitle(),
        actions: [
          if (_navigationStack.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: _navigateBack,
            ),
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search,
                color: Colors.white),
            onPressed: () {
              if (_isSearching) {
                _clearSearch();
              } else {
                _showSearchBar();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: _showMediaTypeSelectionDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () async {
              // Clear scan cache first, then request permissions and load media data
              try {
                await _mediaBrowser.clearScanCache();
                if (kDebugMode) {
                  print('🗑️ Scan cache cleared');
                }
              } catch (e) {
                if (kDebugMode) {
                  print('⚠️ Failed to clear scan cache: $e');
                }
              }

              // Request permissions first, then load media data
              await _requestAllPermissionsOnLaunch();
              await Future.delayed(const Duration(milliseconds: 500));
              await _loadMediaData();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab bar
          Container(
            color: Colors.black,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: Colors.blue,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[400],
              tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
            ),
          ),
          // Content header
          Container(
            color: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  _getItemCount(),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    _isGridView ? Icons.view_list : Icons.grid_view,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _isGridView = !_isGridView;
                    });
                  },
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.blue),
                  )
                : _isGridView
                    ? _buildGridView()
                    : ListView.builder(
                        itemCount: _getCurrentData().length,
                        itemBuilder: (context, index) {
                          final item = _getCurrentData()[index];
                          return _buildListItem(item, index);
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: _buildMediaPlayerControls(),
    );
  }

  /// Build media player controls widget
  Widget _buildMediaPlayerControls() {
    final currentTrack = _mediaPlayer.currentTrack;
    final playerState = _mediaPlayer.currentState;
    final isPlaying = playerState.playing;
    final position = _mediaPlayer.currentPosition;
    final duration = _mediaPlayer.currentDuration;

    if (currentTrack == null) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 80,
      color: Colors.grey[900],
      child: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: duration.inMilliseconds > 0
                ? position.inMilliseconds / duration.inMilliseconds
                : 0.0,
            backgroundColor: Colors.grey[700],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          // Player controls
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Track info
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentTrack.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          currentTrack.artist,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Control buttons
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous,
                            color: Colors.white),
                        onPressed: _mediaPlayer.currentPlaylist.length > 1
                            ? () async {
                                try {
                                  await _mediaPlayer.previous();
                                } catch (e) {
                                  _showSnackBar('Error: $e');
                                }
                              }
                            : null,
                      ),
                      IconButton(
                        icon: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                        onPressed: () async {
                          try {
                            if (isPlaying) {
                              await _mediaPlayer.pause();
                            } else {
                              await _mediaPlayer.play();
                            }
                          } catch (e) {
                            _showSnackBar('Error: $e');
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next, color: Colors.white),
                        onPressed: _mediaPlayer.currentPlaylist.length > 1
                            ? () async {
                                try {
                                  await _mediaPlayer.next();
                                } catch (e) {
                                  _showSnackBar('Error: $e');
                                }
                              }
                            : null,
                      ),
                      IconButton(
                        icon: Icon(
                          _mediaPlayer.isShuffled
                              ? Icons.shuffle
                              : Icons.shuffle,
                          color: _mediaPlayer.isShuffled
                              ? Colors.blue
                              : Colors.white,
                        ),
                        onPressed: () async {
                          try {
                            await _mediaPlayer.toggleShuffle();
                          } catch (e) {
                            _showSnackBar('Error: $e');
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
