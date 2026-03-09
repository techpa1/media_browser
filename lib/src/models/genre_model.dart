/// Genre model for managing genre information
class GenreModel {
  /// Unique identifier for the genre
  final int id;

  /// Genre name
  final String genre;

  /// Number of songs in this genre
  final int numOfSongs;

  /// Genre artwork path
  final String? artwork;

  const GenreModel({
    required this.id,
    required this.genre,
    required this.numOfSongs,
    this.artwork,
  });

  /// Create GenreModel from Map
  factory GenreModel.fromMap(Map<String, dynamic> map) {
    return GenreModel(
      id: map['id'] ?? 0,
      genre: map['genre'] ?? '',
      numOfSongs: map['num_of_songs'] ?? 0,
      artwork: map['artwork'],
    );
  }

  /// Convert GenreModel to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'genre': genre,
      'num_of_songs': numOfSongs,
      'artwork': artwork,
    };
  }

  @override
  String toString() {
    return 'GenreModel(id: $id, genre: $genre, numOfSongs: $numOfSongs)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GenreModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
