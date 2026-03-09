/// Audio model containing information about audio files
class AudioModel {
  /// Unique identifier for the audio file
  final int id;

  /// Title of the audio file
  final String title;

  /// Artist name
  final String artist;

  /// Album name
  final String album;

  /// Genre of the audio
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

  /// Track number
  final int track;

  /// Year of release
  final int year;

  /// Album artist
  final String albumArtist;

  /// Composer
  final String composer;

  /// File extension
  final String fileExtension;

  /// Display name without extension
  final String displayName;

  /// MIME type
  final String mimeType;

  /// Artwork/cover image path
  final String? artwork;

  /// Whether the file is music
  final bool isMusic;

  /// Whether the file is a ringtone
  final bool isRingtone;

  /// Whether the file is an alarm
  final bool isAlarm;

  /// Whether the file is a notification sound
  final bool isNotification;

  /// Whether the file is a podcast
  final bool isPodcast;

  /// Whether the file is an audiobook
  final bool isAudiobook;

  const AudioModel({
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
    required this.track,
    required this.year,
    required this.albumArtist,
    required this.composer,
    required this.fileExtension,
    required this.displayName,
    required this.mimeType,
    this.artwork,
    required this.isMusic,
    required this.isRingtone,
    required this.isAlarm,
    required this.isNotification,
    required this.isPodcast,
    required this.isAudiobook,
  });

  /// Create AudioModel from Map
  factory AudioModel.fromMap(Map<String, dynamic> map) {
    return AudioModel(
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
      track: map['track'] ?? 0,
      year: map['year'] ?? 0,
      albumArtist: map['album_artist'] ?? '',
      composer: map['composer'] ?? '',
      fileExtension: map['file_extension'] ?? '',
      displayName: map['display_name'] ?? '',
      mimeType: map['mime_type'] ?? '',
      artwork: map['artwork'],
      isMusic: map['is_music'] ?? false,
      isRingtone: map['is_ringtone'] ?? false,
      isAlarm: map['is_alarm'] ?? false,
      isNotification: map['is_notification'] ?? false,
      isPodcast: map['is_podcast'] ?? false,
      isAudiobook: map['is_audiobook'] ?? false,
    );
  }

  /// Convert AudioModel to Map
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
      'track': track,
      'year': year,
      'album_artist': albumArtist,
      'composer': composer,
      'file_extension': fileExtension,
      'display_name': displayName,
      'mime_type': mimeType,
      'artwork': artwork,
      'is_music': isMusic,
      'is_ringtone': isRingtone,
      'is_alarm': isAlarm,
      'is_notification': isNotification,
      'is_podcast': isPodcast,
      'is_audiobook': isAudiobook,
    };
  }

  @override
  String toString() {
    return 'AudioModel(id: $id, title: $title, artist: $artist, album: $album)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AudioModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
