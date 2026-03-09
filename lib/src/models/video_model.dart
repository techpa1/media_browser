/// Video model containing information about video files
class VideoModel {
  /// Unique identifier for the video file
  final int id;

  /// Title of the video file
  final String title;

  /// Artist/creator name
  final String artist;

  /// Album/collection name
  final String album;

  /// Genre of the video
  final String genre;

  /// Duration in milliseconds
  final int duration;

  /// File path
  final String data;

  /// File size in bytes
  final int size;

  /// Date added timestamp
  final int dateAdded;

  /// Date modified timestamp
  final int dateModified;

  /// Resolution width
  final int width;

  /// Resolution height
  final int height;

  /// Year of release
  final int year;

  /// File extension
  final String fileExtension;

  /// Display name without extension
  final String displayName;

  /// MIME type
  final String mimeType;

  /// Video codec
  final String codec;

  /// Bitrate
  final int bitrate;

  /// Frame rate
  final double frameRate;

  /// Whether the file is a movie
  final bool isMovie;

  /// Whether the file is a TV show
  final bool isTvShow;

  /// Whether the file is a music video
  final bool isMusicVideo;

  /// Whether the file is a trailer
  final bool isTrailer;

  const VideoModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.genre,
    required this.duration,
    required this.data,
    required this.size,
    required this.dateAdded,
    required this.dateModified,
    required this.width,
    required this.height,
    required this.year,
    required this.fileExtension,
    required this.displayName,
    required this.mimeType,
    required this.codec,
    required this.bitrate,
    required this.frameRate,
    required this.isMovie,
    required this.isTvShow,
    required this.isMusicVideo,
    required this.isTrailer,
  });

  /// Create VideoModel from Map
  factory VideoModel.fromMap(Map<String, dynamic> map) {
    return VideoModel(
      id: map['id'] ?? 0,
      title: map['title'] ?? '',
      artist: map['artist'] ?? '',
      album: map['album'] ?? '',
      genre: map['genre'] ?? '',
      duration: map['duration'] ?? 0,
      data: map['data'] ?? '',
      size: map['size'] ?? 0,
      dateAdded: map['date_added'] ?? 0,
      dateModified: map['date_modified'] ?? 0,
      width: map['width'] ?? 0,
      height: map['height'] ?? 0,
      year: map['year'] ?? 0,
      fileExtension: map['file_extension'] ?? '',
      displayName: map['display_name'] ?? '',
      mimeType: map['mime_type'] ?? '',
      codec: map['codec'] ?? '',
      bitrate: map['bitrate'] ?? 0,
      frameRate: (map['frame_rate'] ?? 0.0).toDouble(),
      isMovie: map['is_movie'] ?? false,
      isTvShow: map['is_tv_show'] ?? false,
      isMusicVideo: map['is_music_video'] ?? false,
      isTrailer: map['is_trailer'] ?? false,
    );
  }

  /// Convert VideoModel to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'genre': genre,
      'duration': duration,
      'data': data,
      'size': size,
      'date_added': dateAdded,
      'date_modified': dateModified,
      'width': width,
      'height': height,
      'year': year,
      'file_extension': fileExtension,
      'display_name': displayName,
      'mime_type': mimeType,
      'codec': codec,
      'bitrate': bitrate,
      'frame_rate': frameRate,
      'is_movie': isMovie,
      'is_tv_show': isTvShow,
      'is_music_video': isMusicVideo,
      'is_trailer': isTrailer,
    };
  }

  /// Get resolution as string (e.g., "1920x1080")
  String get resolution => '${width}x$height';

  /// Get aspect ratio
  double get aspectRatio => width > 0 && height > 0 ? width / height : 0.0;

  @override
  String toString() {
    return 'VideoModel(id: $id, title: $title, artist: $artist, resolution: $resolution)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VideoModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
