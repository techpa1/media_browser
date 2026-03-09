/// Artist model for managing artist information
class ArtistModel {
  /// Unique identifier for the artist
  final int id;

  /// Artist name
  final String artist;

  /// Number of albums by this artist
  final int numOfAlbums;

  /// Number of songs by this artist
  final int numOfSongs;

  /// Artist artwork path
  final String? artwork;

  const ArtistModel({
    required this.id,
    required this.artist,
    required this.numOfAlbums,
    required this.numOfSongs,
    this.artwork,
  });

  /// Create ArtistModel from Map
  factory ArtistModel.fromMap(Map<String, dynamic> map) {
    return ArtistModel(
      id: map['id'] ?? 0,
      artist: map['artist'] ?? '',
      numOfAlbums: map['num_of_albums'] ?? 0,
      numOfSongs: map['num_of_songs'] ?? 0,
      artwork: map['artwork'],
    );
  }

  /// Convert ArtistModel to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'artist': artist,
      'num_of_albums': numOfAlbums,
      'num_of_songs': numOfSongs,
      'artwork': artwork,
    };
  }

  @override
  String toString() {
    return 'ArtistModel(id: $id, artist: $artist, numOfAlbums: $numOfAlbums, numOfSongs: $numOfSongs)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ArtistModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
