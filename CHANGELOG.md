# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.2] - 2026-03-09

### Fixed
- **iOS: MethodChannel heavy work on main thread** – All heavy MethodChannel handlers (queries, scan, artwork, export/extract) now run on a background queue (`DispatchQueue.global(qos: .userInitiated)`) instead of the main thread. Results are delivered on the main thread as required by Flutter. This prevents UI freezes during large media queries and export operations.

### Changed
- **Threading audit** – Confirmed Android and macOS already run heavy work off the main thread (Dispatchers.IO / global queue). Dart side uses the main isolate only; consider `compute()` for heavy result parsing if needed.

[1.1.6] - 2025-11-20
Fixed

Fixed critical crash issue in extractQuicktimeMovie method when extracting MP3 files
Replaced unsafe C-style file operations with Swift's native FileHandle API
Improved memory safety by eliminating raw pointer manipulation
Fixed race conditions in concurrent track extraction operations
Added proper error handling and guaranteed resource cleanup with defer blocks

Changed

Refactored TSLibraryImport class to use asynchronous asset loading
Added thread-safe queue for export operations
Improved DRM-protected content detection with early failure
Enhanced error messages with more detailed logging

Added

Memory leak prevention with weak self references in closures
Automatic cleanup of temporary files after MP3 extraction
Comprehensive bounds checking in file read/write operations
Support for chunk-based file reading (100KB buffer) for large files

Security

Eliminated buffer overflow vulnerabilities in QuickTime atom parsing
Added validation for file existence before operations
Improved thread safety to prevent data corruption

## [1.1.5] - 2024-12-25

### 🧹 Code Quality & Performance

#### **Complete Print Statement Removal**
- **Production Code Cleanup**: Removed all remaining `print()` statements from iOS, macOS, and Dart code
- **Debug-Only Logging**: All debug output now properly wrapped with conditional checks (`#if DEBUG` for iOS/macOS, `kDebugMode` for Dart)
- **Zero Debug Overhead**: No logging code executed in release builds for optimal performance
- **Clean Console Output**: Debug logs only appear during development, eliminating production noise

#### **Enhanced Logging Architecture**
- **iOS/macOS Logger**: Updated Logger utilities to use pure `os_log` without console print statements
- **Example App**: Cleaned up all print statements with proper `kDebugMode` conditional checks
- **Method Channel**: Added debug mode checks for platform communication logging
- **Consistent Implementation**: Unified logging approach across all platforms and components

#### **Performance Optimizations**
- **Release Build Benefits**: Smaller binary size and faster execution without debug overhead
- **Development Experience**: Clean, conditional debug output for better development workflow
- **System Integration**: Proper `os_log` usage for iOS/macOS system-level logging without console pollution

### 🔧 Technical Implementation
- **Conditional Compilation**: Debug code completely excluded from release builds
- **Zero Runtime Cost**: Debug checks resolved at compile time where possible
- **Platform Consistency**: Uniform logging behavior across iOS, macOS, and Dart implementations

---

## [1.1.4] - 2024-12-19

### 🚀 Performance & Quality Improvements
- **Debug-Only Logging**: Replaced all `print` statements with proper logger that only logs in debug mode
- **Production Ready**: No logging overhead in release builds
- **Structured Logging**: Uses Apple's `os_log` framework for better log management
- **Swift Compiler Fixes**: Resolved all Swift compiler errors and improved code quality

### 🔧 Technical Improvements
- **Logger Implementation**: Added dedicated `Logger.swift` utility for both iOS and macOS
- **Conditional Compilation**: Logs only appear in debug builds using `#if DEBUG` preprocessor directives
- **Apple Framework Integration**: Uses `os_log` for structured logging with proper categorization
- **Error Handling**: Improved error logging with appropriate log levels (debug, info, error, warning)

## [1.1.3] - 2024-12-19

### 🎵 iOS & macOS Media Extraction Service

#### **New Media Extraction APIs (iOS & macOS)**
- **`exportTrack(trackId)`**: Export audio tracks from music library to temporary files
- **`exportTrackWithArtwork(trackId)`**: Export tracks with high-quality artwork as separate files
- **`extractArtwork(trackId)`**: Extract and save artwork as JPEG files (1000x1000px)
- **`canExportTrack()`**: Check if music library export is possible
- **`getTrackExtension(trackPath)`**: Get file extension from track paths

#### **Supported Audio Formats**
- **MP3**: Full support with QuickTime container extraction
- **M4A**: Native Apple format support
- **WAV**: Uncompressed audio support
- **AIF/AIFF**: Apple audio interchange format support

#### **Technical Implementation**
- **TSLibraryImport**: Custom implementation for handling various audio formats
- **AVAssetExportSession**: Native iOS/macOS audio processing
- **MPMediaLibrary**: Integration with Apple Music library
- **Permission-Aware**: Automatic music library permission checking
- **Error Handling**: Comprehensive error reporting with detailed messages
- **Cross-Platform**: Identical functionality on both iOS and macOS

#### **Usage Example**
```dart
final mediaBrowser = MediaBrowser();

// Check permissions first
final permissionResult = await mediaBrowser.checkPermissions(MediaType.audio);
if (permissionResult.isGranted) {
  // Export track with artwork
  final result = await mediaBrowser.exportTrackWithArtwork("1234567890");
  print("Audio: ${result['audioFilePath']}");
  print("Artwork: ${result['artworkFilePath']}");
}
```

#### **Architecture Integration**
- **Clean Architecture**: Follows existing plugin patterns
- **Service Layer**: Dedicated `MediaExtractionService` class
- **Repository Pattern**: Full integration with existing data layer
- **Method Channel**: Seamless Flutter-to-iOS communication
- **Error Propagation**: Consistent error handling throughout the stack

### 🔧 Bug Fixes
- **iOS Permission Logic**: Fixed permission checking to properly handle `notDetermined` states
- **Threading Issues**: Moved iOS permission checks to main thread for reliability
- **Type Casting**: Resolved platform channel type casting issues
- **Swift Compiler Errors**: Fixed NSNumber conversion and reserved keyword issues
- **ID Handling**: Improved track ID conversion using `UInt64(bitPattern: Int64(id))`

### 🚀 Performance & Quality Improvements
- **Debug-Only Logging**: Replaced all `print` statements with proper logger that only logs in debug mode
- **Production Ready**: No logging overhead in release builds
- **Structured Logging**: Uses Apple's `os_log` framework for better log management

## [1.1.2] - 2024-12-19

### 🔐 Enhanced Permission State Detection & Platform-Specific Logic

#### **Detailed Permission States**
- **Granular Permission Status**: Added detailed permission state detection for both Android and iOS
- **Smart Permission Handling**: Distinguishes between denied, permanently denied, and restricted permissions
- **Request Capability Detection**: Indicates whether permissions can be requested or need manual settings access
- **Rationale Detection**: Identifies when to show permission rationale to users

#### **Platform-Specific Permission Behavior**

**iOS:**
- **`notDetermined`** → Direct request (iOS OS shows system dialog)
- **`denied`** → Go to settings (cannot retry dialog)
- **`restricted`** → Go to settings (system restriction)

**Android:**
- **`denied`** → Show dialog (can retry multiple times)
- **`permanently_denied`** → Go to settings (user selected "Don't ask again")

#### **New Permission Fields**
- **`status`**: Detailed permission status (granted/denied/permanently_denied/notDetermined)
- **`canRequest`**: Whether permission can be requested via dialog
- **`shouldShowRationale`**: Whether to show explanation before requesting

#### **Critical Fixes**
- **iOS Permission Logic**: Fixed iOS permission behavior to match actual platform limitations
- **Type Casting Error Fix**: Resolved `type '_Map<Object?, Object?>' is not a subtype of type 'PermissionResult?'` error
- **Safe Type Conversion**: Replaced unsafe `as` casting with safe `Map.from()` and `List.from()` conversions
- **Method Channel Safety**: Removed generic type parameter from `invokeMethod<T>()` calls

#### **Platform-Specific Improvements**

**Android:**
- **Permission States**: `granted`, `denied`, `permanently_denied`
- **Request Capability**: Uses `shouldShowRequestPermissionRationale()` to detect if permission can be requested
- **Permanent Denial Detection**: Tracks permission request history to identify permanently denied permissions
- **Smart Dialog Logic**: Prevents showing permission dialogs for permanently denied permissions

**iOS:**
- **Permission States**: `granted`, `denied`, `permanently_denied` (restricted), `notDetermined`
- **Authorization Status Mapping**: Maps iOS authorization statuses to consistent permission states
- **Request Capability**: Determines if permission can be requested based on current status
- **System Dialog Handling**: iOS OS automatically shows permission dialog for `notDetermined` state

#### **Developer Benefits**
- **Smart UI Logic**: Apps can now show appropriate UI based on permission state
- **No Unnecessary Dialogs**: Prevents showing permission dialogs for permanently denied permissions
- **Better UX**: Guides users to settings when permissions are permanently denied
- **Consistent API**: Same permission state structure across Android and iOS
- **Eliminates Runtime Crashes**: Fixes critical type casting errors that could cause app crashes

### 🚀 Impact
- **Improved User Experience**: No more unnecessary permission dialogs
- **Better Permission Handling**: Smart detection of permission states
- **Developer Friendly**: Clear indication of what actions are possible
- **Platform Consistent**: Unified permission state handling across platforms
- **Enhanced Stability**: More robust platform channel communication

## [1.1.1] - 2024-12-19

### 🔧 Permission Monitoring Improvements

#### **Real-time Permission Change Monitoring**
- **Cross-Platform Monitoring**: Added real-time permission change detection for iOS and Android
- **Event Channel Integration**: Implemented EventChannel for permission change notifications
- **Granular Media Type Handling**: Only reload/clear data for affected media types
- **Performance Optimization**: Reduced monitoring frequency from 2s to 5s to improve battery life

#### **Enhanced Permission Data Management**
- **PermissionDataManager**: New utility class for easy permission change handling
- **Media Type Callbacks**: Set specific callbacks for each media type (audio, video, document, folder)
- **Automatic Data Management**: Automatically reload data when permissions granted, clear when denied
- **Error Handling**: Comprehensive error handling for permission monitoring failures

#### **Platform-Specific Improvements**
- **iOS**: Fixed document/folder permission mapping (handled through audio permissions)
- **Android**: Corrected image permission mapping (separate from video permissions)
- **Cross-Platform Consistency**: Unified permission handling across platforms

#### **Developer Experience**
- **Simple API**: Easy-to-use permission monitoring with clear callbacks
- **Better Documentation**: Clear documentation for MediaType.other usage
- **Error Recovery**: Robust error handling prevents silent failures

### 🐛 Bug Fixes
- Fixed iOS permission mapping for documents and folders
- Corrected Android image permission type mapping
- Improved error handling in permission monitoring streams
- Enhanced performance with optimized monitoring intervals

### 📚 API Changes
- Added `listenToPermissionChanges()` method to MediaBrowser
- Added `createPermissionDataManager()` method to MediaBrowser
- Added `PermissionDataManager` utility class
- Added `PermissionChangeEvent` entity class

## [1.1.0] - 2024-12-19

### 🚀 Major Fixes & Improvements

#### **iOS Artwork Loading - Complete Overhaul**
- **Fixed Critical iOS Artwork Issue**: Resolved complete artwork loading failure on iOS devices
- **Data Format Consistency**: Fixed data format mismatch between iOS (base64) and Android (file paths)
- **Album Artwork Support**: Implemented proper album artwork extraction with fallback strategy
- **Negative ID Handling**: Fixed "Negative value is not representable" crash for negative persistent IDs

#### **Android Permission System Enhancement**
- **Real Permission Requests**: Fixed `requestPermissions` to actually request permissions instead of just checking
- **ActivityAware Implementation**: Added proper ActivityAware interface for permission dialogs
- **Permission Result Handling**: Implemented proper permission result callback handling
- **Enhanced Error Handling**: Added comprehensive error handling for permission scenarios

### 🔧 Technical Improvements

#### **iOS Artwork Architecture**
- **Separated Artwork Types**: Split audio and album artwork handling for proper functionality
- **Smart Fallback Strategy**: Album artwork now extracts from songs when album metadata is missing
- **File-Based Artwork**: Changed from base64 to file-based artwork storage (matching Android)
- **Multiple Size Fallback**: Implemented fallback from requested size → smaller → original size
- **Comprehensive Logging**: Added detailed debug logging for artwork operations

#### **Code Quality & Architecture**
- **Helper Function Refactoring**: Created `processArtworkImage()` to eliminate code duplication
- **Error Handling**: Enhanced error handling with detailed error messages
- **Cache Management**: Implemented proper artwork file cleanup with `clearCachedArtworks()`
- **Type Safety**: Fixed ID type conversions with proper bit pattern handling

### 🐛 Bug Fixes

#### **iOS Platform**
- **Fixed Album Artwork**: Albums now display artwork by extracting from contained songs
- **Fixed Negative ID Crash**: Proper handling of negative persistent IDs using bit pattern conversion
- **Fixed Data Format**: Artwork now returns file paths instead of base64 (consistent with Android)
- **Fixed Permission Flow**: Proper permission request and result handling

#### **Android Platform**
- **Fixed Permission Requests**: `requestPermissions` now shows actual permission dialogs
- **Fixed Activity Access**: Proper activity binding for permission dialogs
- **Fixed Result Callbacks**: Proper handling of permission request results

### 📱 Developer Experience

#### **Enhanced Debugging**
- **Comprehensive Logging**: Added detailed logging for artwork operations across platforms
- **Error Messages**: Improved error messages with specific failure reasons
- **Debug Information**: Added warnings for negative IDs and other edge cases

#### **Consistent API**
- **Cross-Platform Consistency**: iOS and Android now behave identically for artwork
- **File Path Standardization**: Both platforms return file paths for artwork data
- **Error Handling**: Consistent error handling patterns across platforms

### 🔄 Breaking Changes
- **None**: All changes are backward compatible

### 📋 Migration Notes
- **No Migration Required**: All existing code will continue to work
- **Enhanced Functionality**: Existing artwork calls will now work properly on iOS
- **Improved Reliability**: Permission requests will now work correctly on Android

### 🧪 Testing Recommendations
- **Test Album Artwork**: Verify album artwork displays correctly on iOS devices
- **Test Permission Flow**: Verify permission dialogs appear and work correctly on Android
- **Test Negative IDs**: Verify no crashes occur with negative persistent IDs
- **Test Artwork Caching**: Verify artwork files are properly cached and cleaned up

---

## [1.0.1] - 2024-12-XX

### Added
- **Enhanced Data Models**
  - `AlbumModel`, `ArtistModel`, `GenreModel` classes for structured data
  - Enhanced `AudioModel` with artwork property
  - `MediaRepository` for centralized data access
  - `BrowsingService` for context-aware browsing with state management
  - `PlaylistModel` for full playlist management with CRUD operations

- **Media Player Services**
  - `MediaPlayerService` class with comprehensive playback functionality
  - Gapless playback using `ConcatenatingAudioSource` for seamless track transitions
  - Playlist management with load, add, clear, and shuffle operations
  - Real-time state management with streams for player state, position, duration, and current track
  - Volume control and seek functionality
  - Shuffle mode with proper index management

### Changed
- **Plugin Architecture**: Moved UI-specific components (image caching, artwork widgets) from plugin to example app for better separation of concerns
- **Dependencies**: Added `just_audio: ^0.9.36` dependency for media playback functionality

### Fixed
- **Artwork Loading**: Fixed base64 encoding issues with `Base64.NO_WRAP` to prevent corruption
- **Compilation Errors**: Fixed missing method references and import issues
- **Lint Warnings**: Resolved all linter warnings and errors

### Technical Improvements
- **Error Handling**: Enhanced error handling for artwork loading
- **Code Organization**: Better separation of concerns between plugin and UI layers
- **Plugin Structure**: Cleaner plugin structure with UI components properly separated

### Dependencies Added
- `just_audio: ^0.9.36` for media playback functionality

---

## [1.0.0] - 2024-01-XX

### Added
- **Audio Support**
  - Query audio files with comprehensive metadata (title, artist, album, genre, duration, etc.)
  - Filter by audio type (music, ringtones, alarms, notifications, podcasts, audiobooks)
  - Support for multiple audio formats (MP3, AAC, FLAC, WAV, OGG, M4A, WMA, AMR, OPUS)
  - Query by album, artist, genre, or specific path
  - Advanced sorting options for audio files

- **Video Support**
  - Query video files with metadata (title, resolution, duration, codec, etc.)
  - Filter by video type (movies, TV shows, music videos, trailers)
  - Support for multiple video formats (MP4, AVI, MKV, MOV, WMV, FLV, WebM, M4V, MPG, MPEG, M2V, MTS, M2TS, TS, VOB)
  - Resolution and bitrate information
  - Frame rate and codec details
  - Query from specific paths

- **Document Support**
  - Query document files with metadata (title, author, subject, page count, etc.)
  - Support for various document types (PDF, DOC, DOCX, TXT, RTF, XLS, XLSX, PPT, PPTX, CSV, XML, HTML, EPUB, MOBI, AZW)
  - E-book support (EPUB, MOBI, AZW)
  - Language and word count information
  - Encryption and compression status
  - Query from specific paths

- **Folder Support**
  - Query folder/directory information
  - File and directory counts
  - Total size calculation with formatted display
  - Folder type classification (music, video, documents, pictures, downloads, DCIM, movies, podcasts, audiobooks, ringtones, notifications, alarms, system, cache, temp, other)
  - Storage location information (internal, external, SD card, USB, cloud, network, other)
  - Query from specific paths

- **Artwork Support**
  - Extract artwork/thumbnails for audio and video files
  - Multiple size options (small, medium, large, original)
  - Support for various image formats (JPEG, PNG, WebP, BMP, GIF)
  - Cached artwork management with clear functionality
  - Artwork type classification (audio, video, album, artist, genre, playlist, folder)

- **Advanced Filtering System**
  - File size range filtering with helper methods (smallerThan, largerThan, between, exact)
  - Date range filtering with helper methods (after, before, between)
  - File extension inclusion/exclusion lists
  - MIME type filtering with inclusion/exclusion lists
  - Search query support with case-insensitive option
  - Hidden and system file options
  - Audio-specific filters (duration range, artist, album, genre filters)
  - Video-specific filters (resolution range, duration range)

- **Comprehensive Sorting Options**
  - Multiple sort types for each media category
  - Ascending/descending order with case-insensitive option
  - Audio sort types: title, artist, album, genre, duration, size, dateAdded, dateModified, track, year, albumArtist, composer, fileExtension, displayName
  - Video sort types: title, artist, album, genre, duration, size, dateAdded, dateModified, width, height, year, fileExtension, displayName, codec, bitrate, frameRate
  - Document sort types: title, size, dateAdded, dateModified, fileExtension, displayName, author, subject, pageCount, wordCount, language
  - Folder sort types: name, path, dateCreated, dateModified, dateAccessed, totalSize, fileCount, directoryCount
  - Generic media sort types: title, size, dateAdded, dateModified, fileExtension, displayName, mimeType

- **Data Models**
  - `AudioModel` with comprehensive audio metadata
  - `VideoModel` with video-specific metadata and resolution information
  - `DocumentModel` with document-specific metadata and type classification
  - `FolderModel` with folder information and storage location details
  - `ArtworkModel` with artwork data and format information
  - `QueryOptions` base class for filtering and sorting
  - `AudioQueryOptions` with audio-specific filtering options
  - `VideoQueryOptions` with video-specific filtering options

- **Enums and Constants**
  - `MediaType` enumeration (audio, video, document, image, folder, archive, other)
  - `DocumentType` enumeration (pdf, doc, docx, txt, rtf, xls, xlsx, ppt, pptx, csv, xml, html, epub, mobi, azw, image, archive, other)
  - `FolderType` enumeration (music, video, documents, pictures, downloads, dcim, movies, podcasts, audiobooks, ringtones, notifications, alarms, system, cache, temp, other)
  - `StorageLocation` enumeration (internal, external, sdCard, usb, cloud, network, other)
  - `ArtworkType` enumeration (audio, video, album, artist, genre, playlist, folder)
  - `ArtworkFormat` enumeration (jpeg, png, webp, bmp, gif, other)
  - `ArtworkSize` enumeration (small, medium, large, original)
  - `SortOrder` enumeration (ascending, descending)
  - Comprehensive sort type enumerations for each media type
  - File format constants for audio, video, document, image, and archive formats

- **Platform Interface**
  - Abstract `SimpleMediaQueryPlatform` class with all method signatures
  - `MethodChannelSimpleMediaQuery` implementation for method channel communication
  - Permission management (request and check permissions)
  - Media scanning functionality
  - Device information retrieval

- **Main Plugin Class**
  - `SimpleMediaQuery` main class with all public methods
  - Comprehensive API for all media types
  - Easy-to-use interface with optional parameters
  - Error handling and null safety

- **Example Application**
  - Complete example app demonstrating all features
  - Tabbed interface for different media types
  - Permission handling with user-friendly UI
  - Detailed media information display
  - Search and filtering examples
  - Artwork display functionality

- **Documentation**
  - Comprehensive README with usage examples
  - API documentation for all classes and methods
  - Installation and setup instructions
  - Permission requirements for Android and iOS
  - Supported file formats documentation
  - Platform support information

### Technical Features
- **Null Safety**: Full null safety support for Dart 3.0+
- **Type Safety**: Strong typing with comprehensive data models
- **Error Handling**: Proper error handling with try-catch blocks
- **Performance**: Efficient querying with filtering and sorting options
- **Extensibility**: Modular design allowing easy extension for new media types
- **Cross-Platform**: Support for Android and iOS with method channels
- **Memory Management**: Cached artwork management with clear functionality

### API Methods
- `getPlatformVersion()` - Get platform version information
- `requestPermission()` - Request storage permissions
- `hasPermission()` - Check if permissions are granted
- `queryAudios()` - Query audio files with optional filtering
- `queryAudiosFromAlbum()` - Query audio files from specific album
- `queryAudiosFromArtist()` - Query audio files from specific artist
- `queryAudiosFromGenre()` - Query audio files from specific genre
- `queryAudiosFromPath()` - Query audio files from specific path
- `queryVideos()` - Query video files with optional filtering
- `queryVideosFromPath()` - Query video files from specific path
- `queryDocuments()` - Query document files with optional filtering
- `queryDocumentsFromPath()` - Query document files from specific path
- `queryFolders()` - Query folder information with optional filtering
- `queryFoldersFromPath()` - Query folders from specific path
- `queryAlbums()` - Query album information
- `queryArtists()` - Query artist information
- `queryGenres()` - Query genre information
- `queryArtwork()` - Query artwork/thumbnails for media files
- `clearCachedArtworks()` - Clear cached artwork data
- `scanMedia()` - Scan media files in specific path
- `getDeviceInfo()` - Get device information

### Supported Platforms
- ✅ Android (API 21+)
- ✅ iOS (iOS 11.0+)
- ⚠️ Web (Limited support - planned for future versions)
- ⚠️ macOS (Limited support - planned for future versions)
- ⚠️ Windows (Limited support - planned for future versions)
- ⚠️ Linux (Limited support - planned for future versions)

### Dependencies
- Flutter SDK 3.0.0+
- plugin_platform_interface 2.0.2+

### Breaking Changes
- None (initial release)

### Migration Guide
- N/A (initial release)

---

## Future Releases

### Planned Features
- **Web Support**: Full web platform support with file system access
- **Desktop Support**: Native desktop platform support (macOS, Windows, Linux)
- **Playlist Management**: Create, edit, and manage playlists
- **Media Editing**: Basic media metadata editing capabilities
- **Cloud Storage**: Support for cloud storage providers
- **Advanced Search**: Full-text search across media metadata
- **Batch Operations**: Bulk operations for media files
- **Media Streaming**: Basic media streaming capabilities
- **Export/Import**: Export and import media collections
- **Statistics**: Media usage statistics and analytics

### Performance Improvements
- Lazy loading for large media collections
- Background processing for media scanning
- Optimized database queries
- Memory usage optimization
- Caching improvements

### API Enhancements
- Stream-based queries for real-time updates
- Observer pattern for media changes
- Advanced filtering with regex support
- Custom sort functions
- Pagination support for large result sets