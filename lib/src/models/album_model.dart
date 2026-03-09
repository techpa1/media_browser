/// Album model for managing album information
class AlbumModel {
  /// Unique identifier for the album
  final int id;

  /// Album name
  final String album;

  /// Artist name
  final String artist;

  /// Number of songs in the album
  final int numOfSongs;

  /// Album year
  final int year;

  /// Album artwork path
  final String? artwork;

  const AlbumModel({
    required this.id,
    required this.album,
    required this.artist,
    required this.numOfSongs,
    required this.year,
    this.artwork,
  });

  /// Create AlbumModel from Map
  factory AlbumModel.fromMap(Map<String, dynamic> map) {
    return AlbumModel(
      id: map['id'] ?? 0,
      album: map['album'] ?? '',
      artist: map['artist'] ?? '',
      numOfSongs: map['num_of_songs'] ?? 0,
      year: map['year'] ?? 0,
      artwork: map['artwork'],
    );
  }

  /// Convert AlbumModel to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'album': album,
      'artist': artist,
      'num_of_songs': numOfSongs,
      'year': year,
      'artwork': artwork,
    };
  }

  @override
  String toString() {
    return 'AlbumModel(id: $id, album: $album, artist: $artist, numOfSongs: $numOfSongs, year: $year)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AlbumModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
