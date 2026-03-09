/// Artwork model containing information about media artwork/thumbnails
class ArtworkModel {
  /// Unique identifier for the artwork
  final int id;

  /// Artwork file path (for local file paths)
  final String? filePath;

  /// Artwork format
  final ArtworkFormat format;

  /// Artwork size
  final ArtworkSize size;

  /// Whether the artwork is available
  final bool isAvailable;

  /// Error message if artwork is not available
  final String? error;

  const ArtworkModel({
    required this.id,
    this.filePath,
    required this.format,
    required this.size,
    required this.isAvailable,
    this.error,
  });

  /// Create ArtworkModel from Map
  factory ArtworkModel.fromMap(Map<String, dynamic> map) {
    return ArtworkModel(
      id: map['id'] ?? 0,
      filePath: map['data'] as String?,
      format: ArtworkFormat.fromString(map['format'] ?? ''),
      size: ArtworkSize.fromString(map['size'] ?? ''),
      isAvailable: map['is_available'] ?? false,
      error: map['error'],
    );
  }

  /// Convert ArtworkModel to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'data': filePath,
      'format': format.toString(),
      'size': size.toString(),
      'is_available': isAvailable,
      'error': error,
    };
  }

  @override
  String toString() {
    return 'ArtworkModel(id: $id, format: $format, size: $size, isAvailable: $isAvailable)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ArtworkModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Artwork format enumeration
enum ArtworkFormat {
  jpeg,
  png,
  webp,
  bmp,
  gif,
  other;

  /// Create ArtworkFormat from string
  factory ArtworkFormat.fromString(String format) {
    switch (format.toLowerCase()) {
      case 'jpeg':
      case 'jpg':
        return ArtworkFormat.jpeg;
      case 'png':
        return ArtworkFormat.png;
      case 'webp':
        return ArtworkFormat.webp;
      case 'bmp':
        return ArtworkFormat.bmp;
      case 'gif':
        return ArtworkFormat.gif;
      default:
        return ArtworkFormat.other;
    }
  }

  @override
  String toString() {
    return name;
  }
}

/// Artwork size enumeration
enum ArtworkSize {
  small,
  medium,
  large,
  original;

  /// Create ArtworkSize from string
  factory ArtworkSize.fromString(String size) {
    switch (size.toLowerCase()) {
      case 'small':
        return ArtworkSize.small;
      case 'medium':
        return ArtworkSize.medium;
      case 'large':
        return ArtworkSize.large;
      case 'original':
        return ArtworkSize.original;
      default:
        return ArtworkSize.medium;
    }
  }

  /// Get pixel dimensions for the size
  int get pixelSize {
    switch (this) {
      case ArtworkSize.small:
        return 150;
      case ArtworkSize.medium:
        return 300;
      case ArtworkSize.large:
        return 600;
      case ArtworkSize.original:
        return -1; // Original size
    }
  }

  @override
  String toString() {
    return name;
  }
}

/// Artwork type enumeration
enum ArtworkType {
  audio,
  video,
  album,
  artist,
  genre,
  playlist,
  folder;

  /// Create ArtworkType from string
  factory ArtworkType.fromString(String type) {
    switch (type.toLowerCase()) {
      case 'audio':
        return ArtworkType.audio;
      case 'video':
        return ArtworkType.video;
      case 'album':
        return ArtworkType.album;
      case 'artist':
        return ArtworkType.artist;
      case 'genre':
        return ArtworkType.genre;
      case 'playlist':
        return ArtworkType.playlist;
      case 'folder':
        return ArtworkType.folder;
      default:
        return ArtworkType.audio;
    }
  }

  @override
  String toString() {
    return name;
  }
}
