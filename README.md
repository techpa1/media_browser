# Media Browser

A comprehensive Flutter plugin to browse and query local media files including audio, video, documents, and folders from device storage with advanced filtering and sorting capabilities.

> **Latest Version 1.1.5**: Enhanced with production-ready code quality improvements, complete removal of debug print statements, and optimized performance for release builds.

## Features

### 🎵 Audio Support
- Query audio files with metadata (title, artist, album, genre, duration, etc.)
- Filter by audio type (music, ringtones, alarms, notifications, podcasts, audiobooks)
- Support for multiple audio formats (MP3, AAC, FLAC, WAV, OGG, M4A, WMA, AMR, OPUS)
- Query by album, artist, genre, or specific path
- Advanced sorting options

### 🎬 Video Support
- Query video files with metadata (title, resolution, duration, codec, etc.)
- Filter by video type (movies, TV shows, music videos, trailers)
- Support for multiple video formats (MP4, AVI, MKV, MOV, WMV, FLV, WebM, etc.)
- Resolution and bitrate information
- Frame rate and codec details

### 📄 Document Support
- Query document files with metadata (title, author, subject, page count, etc.)
- **Enhanced support for 25+ document types** including PDF, DOC, DOCX, TXT, RTF, ODT, XLS, XLSX, PPT, PPTX, ODP, ODS, CSV, XML, JSON, HTML, CSS, JS, PY, JAVA, CPP, MD, YAML, SQL, and more
- E-book support (EPUB, MOBI, AZW)
- Language and word count information
- Encryption and compression status
- **Comprehensive MIME type detection** for all supported file formats

### 📁 Folder Support
- Query folder/directory information
- File and directory counts
- Total size calculation
- Folder type classification (music, video, documents, pictures, etc.)
- Storage location information (internal, external, SD card, etc.)
- **Recursive directory scanning** with file type filtering
- **Common directory scanning** (Music, Downloads, Documents, Pictures, etc.)
- **Enhanced file system metadata** (permissions, dates, attributes)

### 🎨 Artwork Support
- Extract artwork/thumbnails for audio and video files
- Multiple size options (small, medium, large, original)
- Support for various image formats (JPEG, PNG, WebP, BMP, GIF)
- Cached artwork management
- **✅ Fixed iOS Artwork Loading**: Complete overhaul of iOS artwork system
- **✅ Album Artwork Support**: Smart fallback to extract artwork from songs when album metadata is missing
- **✅ Cross-Platform Consistency**: iOS and Android now use identical file-based artwork storage

### 🔍 Advanced Filtering
- File size range filtering
- Date range filtering
- File extension inclusion/exclusion
- MIME type filtering
- Search query support
- Hidden and system file options

### 📊 Sorting Options
- Multiple sort types for each media category
- Ascending/descending order
- Case-insensitive sorting
- Custom sort options

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  media_browser: ^1.0.1
```

## Usage

### Basic Setup

```dart
import 'package:media_browser/media_browser.dart';

final simpleMediaQuery = SimpleMediaQuery();
```

### Request Permissions

```dart
// Check if permission is granted
bool hasPermission = await simpleMediaQuery.hasPermission();

// Request permission
bool granted = await simpleMediaQuery.requestPermission();
```

### Query Audio Files

```dart
// Query all audio files
List<AudioModel> audios = await simpleMediaQuery.queryAudios();

// Query with options
List<AudioModel> audios = await simpleMediaQuery.queryAudios(
  options: AudioQueryOptions(
    sortType: AudioSortType.title,
    sortOrder: SortOrder.ascending,
    includeMusic: true,
    includePodcasts: true,
    minDuration: 30000, // 30 seconds
    maxDuration: 300000, // 5 minutes
  ),
);

// Query from specific album
List<AudioModel> albumAudios = await simpleMediaQuery.queryAudiosFromAlbum(albumId);

// Query from specific artist
List<AudioModel> artistAudios = await simpleMediaQuery.queryAudiosFromArtist(artistId);

// Query from specific genre
List<AudioModel> genreAudios = await simpleMediaQuery.queryAudiosFromGenre(genreId);

// Query from specific path
List<AudioModel> pathAudios = await simpleMediaQuery.queryAudiosFromPath('/path/to/music');
```

### Query Video Files

```dart
// Query all video files
List<VideoModel> videos = await simpleMediaQuery.queryVideos();

// Query with options
List<VideoModel> videos = await simpleMediaQuery.queryVideos(
  options: VideoQueryOptions(
    sortType: VideoSortType.title,
    sortOrder: SortOrder.descending,
    includeMovies: true,
    includeTvShows: true,
    minWidth: 1920,
    minHeight: 1080,
  ),
);

// Query from specific path
List<VideoModel> pathVideos = await simpleMediaQuery.queryVideosFromPath('/path/to/videos');
```

### Query Document Files

```dart
// Query all document files
List<DocumentModel> documents = await simpleMediaQuery.queryDocuments();

// Query with options
List<DocumentModel> documents = await simpleMediaQuery.queryDocuments(
  options: QueryOptions(
    sortType: DocumentSortType.title,
    sortOrder: SortOrder.ascending,
    includeExtensions: ['pdf', 'doc', 'docx'],
    sizeRange: FileSizeRange.largerThan(1024 * 1024), // Larger than 1MB
  ),
);

// Query from specific path
List<DocumentModel> pathDocuments = await simpleMediaQuery.queryDocumentsFromPath('/path/to/documents');
```

### Query Folders

```dart
// Query all folders
List<FolderModel> folders = await simpleMediaQuery.queryFolders();

// Query with options
List<FolderModel> folders = await simpleMediaQuery.queryFolders(
  options: QueryOptions(
    sortType: FolderSortType.name,
    sortOrder: SortOrder.ascending,
    includeHidden: false,
    includeSystem: false,
  ),
);

// Query from specific path
List<FolderModel> pathFolders = await simpleMediaQuery.queryFoldersFromPath('/path/to/parent');
```

### Query Albums, Artists, and Genres

```dart
// Query albums
List<Map<String, dynamic>> albums = await simpleMediaQuery.queryAlbums();

// Query artists
List<Map<String, dynamic>> artists = await simpleMediaQuery.queryArtists();

// Query genres
List<Map<String, dynamic>> genres = await simpleMediaQuery.queryGenres();
```

### Query Artwork

```dart
// Query artwork for audio file
ArtworkModel artwork = await simpleMediaQuery.queryArtwork(
  audioId,
  ArtworkType.audio,
  size: ArtworkSize.medium,
);

// Query artwork for video file
ArtworkModel videoArtwork = await simpleMediaQuery.queryArtwork(
  videoId,
  ArtworkType.video,
  size: ArtworkSize.large,
);

// Clear cached artworks
await simpleMediaQuery.clearCachedArtworks();
```

### 🎵 Media Extraction (iOS & macOS)

**Note**: Media extraction features are available on iOS and macOS and require music library permissions.

```dart
final mediaBrowser = MediaBrowser();

// Check if export is possible
bool canExport = await mediaBrowser.canExportTrack();

if (canExport) {
  // Get a track ID from your audio query
  final audios = await mediaBrowser.queryAudios();
  if (audios.isNotEmpty) {
    final trackId = audios.first.id.toString();
    
    // Export track to temporary file
    final exportResult = await mediaBrowser.exportTrack(trackId);
    print("Exported to: ${exportResult['filePath']}");
    
    // Export track with artwork
    final exportWithArtworkResult = await mediaBrowser.exportTrackWithArtwork(trackId);
    print("Audio: ${exportWithArtworkResult['audioFilePath']}");
    print("Artwork: ${exportWithArtworkResult['artworkFilePath']}");
    
    // Extract just the artwork
    final artworkResult = await mediaBrowser.extractArtwork(trackId);
    print("Artwork saved to: ${artworkResult['artworkPath']}");
    
    // Get file extension from track path
    final extensionResult = await mediaBrowser.getTrackExtension("ipod-library://item/item.m4a");
    print("Extension: ${extensionResult['extension']}");
  }
}
```

#### Supported Audio Formats
- **MP3**: Full support with QuickTime container extraction
- **M4A**: Native Apple format support  
- **WAV**: Uncompressed audio support
- **AIF/AIFF**: Apple audio interchange format support

#### Media Extraction Features
- **High-Quality Artwork**: Extract artwork at 1000x1000px resolution
- **Multiple Export Options**: Export audio only, or audio with separate artwork file
- **Format Detection**: Automatic file extension detection
- **Permission-Aware**: Automatic music library permission checking
- **Error Handling**: Comprehensive error reporting with detailed messages

### Enhanced File System Scanning

```dart
// Scan directory recursively for all files and folders
List<dynamic> allItems = await simpleMediaQuery.scanDirectoryRecursively('/storage/emulated/0/Music');

// Scan directory for specific file types
List<dynamic> audioFiles = await simpleMediaQuery.scanDirectoryRecursively(
  '/storage/emulated/0/Music', 
  fileType: 'audio'
);

List<dynamic> videoFiles = await simpleMediaQuery.scanDirectoryRecursively(
  '/storage/emulated/0/Movies', 
  fileType: 'video'
);

List<dynamic> documents = await simpleMediaQuery.scanDirectoryRecursively(
  '/storage/emulated/0/Documents', 
  fileType: 'document'
);

// Scan common directories for all file types
List<dynamic> commonFiles = await simpleMediaQuery.scanCommonDirectories();

// Scan common directories for specific file types
List<dynamic> commonAudio = await simpleMediaQuery.scanCommonDirectories(fileType: 'audio');
List<dynamic> commonVideos = await simpleMediaQuery.scanCommonDirectories(fileType: 'video');
List<dynamic> commonDocs = await simpleMediaQuery.scanCommonDirectories(fileType: 'document');

// Get list of available common directories
List<String> directories = await simpleMediaQuery.getCommonDirectories();
// Returns: ['/storage/emulated/0/Music', '/storage/emulated/0/Download', '/storage/emulated/0/Documents', ...]
```

## Media Player Integration

The example app includes a complete media player implementation with gapless playback:

### Media Player Service

```dart
import 'package:media_browser/src/services/media_player_service.dart';

final mediaPlayer = MediaPlayerService();

// Initialize the player
await mediaPlayer.initialize();

// Load a playlist
await mediaPlayer.loadPlaylist(audioTracks);

// Play the current track
await mediaPlayer.play();

// Pause playback
await mediaPlayer.pause();

// Skip to next track
await mediaPlayer.next();

// Skip to previous track
await mediaPlayer.previous();

// Toggle shuffle mode
await mediaPlayer.toggleShuffle();

// Seek to position
await mediaPlayer.seek(Duration(minutes: 2));

// Set volume
await mediaPlayer.setVolume(0.8);

// Listen to player state changes
mediaPlayer.playerStateStream.listen((state) {
  print('Player state: ${state.playing}');
});

// Listen to current track changes
mediaPlayer.currentTrackStream.listen((index) {
  print('Current track index: $index');
});
```

### Navigation System

The example app includes a comprehensive navigation system for browsing media:

```dart
// Navigate to album contents
void _navigateToAlbum(Map<String, dynamic> album) {
  final albumTracks = _audios
      .where((track) => track.album == album['album'] && track.artist == album['artist'])
      .toList();
  
  _navigationStack.add(NavigationItem(
    title: album['album'],
    type: 'album',
    data: album,
    items: albumTracks,
  ));
  
  _currentData = albumTracks;
  setState(() {});
}

// Navigate to artist contents
void _navigateToArtist(Map<String, dynamic> artist) {
  final artistTracks = _audios
      .where((track) => track.artist == artist['artist'])
      .toList();
  
  _navigationStack.add(NavigationItem(
    title: artist['artist'],
    type: 'artist',
    data: artist,
    items: artistTracks,
  ));
  
  _currentData = artistTracks;
  setState(() {});
}

// Navigate back
void _navigateBack() {
  if (_navigationStack.isNotEmpty) {
    _navigationStack.removeLast();
    if (_navigationStack.isNotEmpty) {
      final previousItem = _navigationStack.last;
      _currentData = previousItem.items;
    } else {
      _currentData = [];
    }
    setState(() {});
  }
}
```

## Supported File Formats

### Audio Formats
- MP3, AAC, FLAC, WAV, OGG, M4A, WMA, AMR, OPUS

### Video Formats
- MP4, AVI, MKV, MOV, WMV, FLV, WebM, M4V, MPG, MPEG, M2V, MTS, M2TS, TS, VOB

### Document Formats
- PDF, DOC, DOCX, TXT, RTF, XLS, XLSX, PPT, PPTX, CSV, XML, HTML, EPUB, MOBI, AZW

### Image Formats (for artwork)
- JPEG, PNG, WebP, BMP, GIF, SVG, TIFF, ICO, HEIC, HEIF

### Archive Formats
- ZIP, RAR, TAR, GZ, BZ2, XZ, 7Z, ISO

## Permissions

### Android Setup

#### 1. Add Permissions to AndroidManifest.xml

Add the following permissions to your `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Storage permissions -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />

<!-- Media permissions for Android 13+ (API 33+) -->
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />

<!-- Internet permission for future cloud storage support -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

#### 2. Handle Runtime Permissions

For Android 6.0+ (API 23+), you need to handle runtime permissions. The plugin will automatically check and request permissions, but you can also handle them manually:

```dart
// Check permissions before querying
final permissionResult = await simpleMediaQuery.checkPermissions(MediaType.audio);
if (!permissionResult.isGranted) {
  // Handle missing permissions
  print('Missing permissions: ${permissionResult.missingPermissions}');
  
  // Request permissions
  final requestResult = await simpleMediaQuery.requestPermissions(MediaType.audio);
  if (!requestResult.isGranted) {
    // Handle permission denial
    return;
  }
}
```

#### 3. Android Version Compatibility

- **Android 6.0+ (API 23+)**: Runtime permissions required
- **Android 13+ (API 33+)**: Granular media permissions (`READ_MEDIA_*`)
- **Android 10+ (API 29+)**: Scoped storage restrictions apply

### iOS Setup

#### 1. Add Usage Descriptions to Info.plist

Add the following keys to your `ios/Runner/Info.plist`:

```xml
<!-- Required for audio/music access -->
<key>NSAppleMusicUsageDescription</key>
<string>This app needs access to your music library to display and manage your audio files.</string>

<!-- Required for video/photo access -->
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs access to your photo library to display and manage your video files.</string>

<!-- Optional: For media library access -->
<key>NSMediaLibraryUsageDescription</key>
<string>This app needs access to your media library to organize your media files.</string>
```

#### 2. Handle iOS Permissions

iOS permissions are handled automatically by the system, but you can check and request them:

```dart
// Check permissions
final permissionResult = await simpleMediaQuery.checkPermissions(MediaType.audio);
if (!permissionResult.isGranted) {
  // Request permissions
  final requestResult = await simpleMediaQuery.requestPermissions(MediaType.audio);
  if (!requestResult.isGranted) {
    // Handle permission denial
    return;
  }
}
```

#### 3. iOS Version Compatibility

- **iOS 11.0+**: Required minimum version
- **iOS 14.0+**: Enhanced privacy controls
- **iOS 16.0+**: Improved media access APIs

### Permission Types by Media Type

| Media Type | Android Permissions | iOS Permissions |
|------------|-------------------|-----------------|
| **Audio** | `READ_EXTERNAL_STORAGE`, `READ_MEDIA_AUDIO` | `NSAppleMusicUsageDescription` |
| **Video** | `READ_EXTERNAL_STORAGE`, `READ_MEDIA_VIDEO` | `NSPhotoLibraryUsageDescription` |
| **Documents** | `READ_EXTERNAL_STORAGE` | None (Documents directory) |
| **Folders** | `READ_EXTERNAL_STORAGE` | None (App directories) |
| **All** | All above permissions | All above permissions |

### Error Handling

The plugin provides detailed error information when permissions are missing or operations fail:

```dart
try {
  final audios = await simpleMediaQuery.queryAudios();
} on PermissionError catch (e) {
  print('Permission Error: ${e.message}');
  print('Missing permissions: ${e.missingPermissions}');
  print('Status: ${e.status}');
} on PlatformError catch (e) {
  print('Platform Error: ${e.message}');
  print('Platform: ${e.platform}');
  if (TimeoutUtils.isTimeoutError(e)) {
    print('This was a timeout error');
    final timeoutInfo = TimeoutUtils.getTimeoutInfo(e);
    print('Timeout details: $timeoutInfo');
  }
} on MediaError catch (e) {
  print('Media Error: ${e.message}');
}
```

### Timeout Handling

All operations have built-in timeout protection to prevent infinite loops:

- **Quick Operations** (10 seconds): Permission checks, platform version, device info
- **Standard Operations** (30 seconds): Media queries (audio, video, documents, folders)
- **Heavy Operations** (60 seconds): Artwork queries, media scanning, cache clearing

```dart
// Check if an error is a timeout
if (TimeoutUtils.isTimeoutError(error)) {
  print('Operation timed out');
  final timeoutInfo = TimeoutUtils.getTimeoutInfo(error);
  print('Timeout details: $timeoutInfo');
}

// Custom timeout for specific operations
final result = await TimeoutUtils.executeWithTimeout(
  () => simpleMediaQuery.queryAudios(),
  timeout: Duration(seconds: 45),
  operationName: 'custom_audio_query',
);
```

### Permission Status Types

- `granted`: All required permissions are granted
- `denied`: Some permissions are denied
- `permanentlyDenied`: Permissions permanently denied (Android)
- `restricted`: Permissions restricted by system (iOS)
- `limited`: Limited access granted (iOS 14+)
- `provisional`: Provisional access granted (iOS 14+)

## Platform Support

- ✅ **Android** (API 21+) - Full native implementation with MediaStore
- ✅ **iOS** (iOS 11.0+) - Full native implementation with MediaPlayer/Photos
- ✅ **macOS** (macOS 10.14+) - Full native implementation with MediaPlayer/Photos
- ✅ **Windows** (Windows 10+) - File system scanning implementation
- ✅ **Linux** (Ubuntu 18.04+) - File system scanning implementation
- ⚠️ **Web** - Limited implementation (file picker required)

### Platform-Specific Setup

#### Windows Setup
No additional setup required. The plugin will automatically scan common directories:
- `%USERPROFILE%\Music`
- `%USERPROFILE%\Videos`
- `%USERPROFILE%\Documents`
- `%USERPROFILE%\Downloads`

#### macOS Setup
Add the following to your `macos/Runner/Info.plist`:

```xml
<key>NSAppleMusicUsageDescription</key>
<string>This app needs access to your music library to display and manage your audio files.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs access to your photo library to display and manage your video files.</string>
```

#### Linux Setup
No additional setup required. The plugin will automatically scan common directories:
- `~/Music`
- `~/Videos`
- `~/Documents`
- `~/Downloads`

#### Web Setup
Web platform has limited functionality due to browser security restrictions. File access requires user interaction through file pickers:

```dart
// Use file picker for web
if (kIsWeb) {
  final files = await WebFilePicker.pickAudioFiles();
  // Process selected files
}
```

## Example App

Check out the example app in the `example/` directory to see a complete implementation demonstrating all features including:

### 🎵 **Media Player Integration**
- **Gapless Playback**: Seamless track transitions using `just_audio`
- **Playlist Management**: Load, add, clear playlists with proper state management
- **Playback Controls**: Play, pause, stop, next, previous, seek functionality
- **Shuffle Support**: Toggle shuffle mode with proper index management
- **Real-time State Management**: Stream-based updates for player state, position, duration

### 🧭 **Navigation System**
- **Deep Browsing**: Navigate through albums, artists, folders to reach media files
- **Breadcrumb Navigation**: Visual breadcrumb trail with clickable navigation
- **Navigation Stack**: Full browsing history with back navigation
- **Context-Aware UI**: UI adapts based on current navigation level

### 🎨 **Artwork Display**
- **Async Image Loading**: Non-blocking artwork loading with caching
- **Smart Caching**: Memory + disk caching for optimal performance
- **Fallback Support**: Graceful degradation when artwork isn't available
- **Multiple Sizes**: Support for small, medium, and large artwork sizes

### 📱 **UI Features**
- **List View Default**: Efficient browsing with list view as default
- **Grid/List Toggle**: Switch between grid and list views
- **Search Functionality**: Search across all media types
- **Media Type Filtering**: Filter by audio, video, documents, folders
- **Responsive Design**: Optimized for different screen sizes

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the BSD 3-Clause License - see the [LICENSE](LICENSE) file for details.

## Changelog

### 1.0.0
- **Initial Release**: Complete media browser plugin with comprehensive features
- **Media Support**: Audio, video, document, and folder querying with metadata
- **Advanced Filtering**: File size, date range, extension, and MIME type filtering
- **Sorting Options**: Multiple sort types for each media category
- **Artwork Support**: Extract and cache artwork/thumbnails for audio and video files
- **Cross-Platform**: Full support for Android, iOS, macOS, Windows, Linux, and Web
- **Permission Handling**: Comprehensive permission management with timeout protection
- **Data Models**: Rich data models with comprehensive metadata
- **Error Handling**: Detailed error information and timeout protection

### 1.1.5 (Latest)
- **Production-Ready Code Quality**: Complete removal of all debug print statements for optimal release performance
- **Zero Debug Overhead**: Debug logging only in development builds, no performance impact in production
- **Enhanced Logging Architecture**: Proper conditional compilation and system logging integration
- **Media Player Integration**: Added `just_audio` integration for gapless playback
- **Navigation System**: Implemented deep browsing with navigation stack and breadcrumbs
- **UI Architecture**: Moved image caching and artwork widgets to example app (UI layer)
- **Performance Improvements**: Async artwork loading with smart caching to prevent UI hangs
- **Enhanced Example App**: Complete media player with playlist management and playback controls
- **List View Default**: Set list view as default for better browsing experience
- **Breadcrumb Navigation**: Visual navigation trail with clickable breadcrumbs
- **Context-Aware Browsing**: UI adapts based on navigation level (root, album, artist, folder)
- **Artwork Caching**: Memory + disk caching for optimal performance
- **Fallback Support**: Graceful degradation when artwork isn't available
- **Media Repository**: Centralized data access layer for media queries
- **Browsing Service**: Context-aware browsing with state management
- **Playlist Model**: Full playlist management with CRUD operations

## Acknowledgments

This plugin is inspired by the excellent [on_audio_query](https://pub.dev/packages/on_audio_query) package and extends its functionality to support multiple media types.