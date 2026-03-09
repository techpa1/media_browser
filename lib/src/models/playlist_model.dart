import 'audio_model.dart';

/// Playlist model for managing collections of audio tracks
class PlaylistModel {
  /// Unique identifier for the playlist
  final String id;

  /// Playlist name
  final String name;

  /// List of audio tracks in the playlist
  final List<AudioModel> tracks;

  /// Playlist creation date
  final DateTime createdAt;

  /// Playlist last modified date
  final DateTime modifiedAt;

  /// Playlist description
  final String? description;

  /// Whether this is a system playlist (e.g., "Recently Played")
  final bool isSystemPlaylist;

  /// Playlist artwork/cover image
  final String? artwork;

  const PlaylistModel({
    required this.id,
    required this.name,
    required this.tracks,
    required this.createdAt,
    required this.modifiedAt,
    this.description,
    this.isSystemPlaylist = false,
    this.artwork,
  });

  /// Create PlaylistModel from Map
  factory PlaylistModel.fromMap(Map<String, dynamic> map) {
    return PlaylistModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      tracks: (map['tracks'] as List<dynamic>?)
              ?.map((track) => AudioModel.fromMap(track))
              .toList() ??
          [],
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      modifiedAt: DateTime.tryParse(map['modifiedAt'] ?? '') ?? DateTime.now(),
      description: map['description'],
      isSystemPlaylist: map['isSystemPlaylist'] ?? false,
      artwork: map['artwork'],
    );
  }

  /// Convert PlaylistModel to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'tracks': tracks.map((track) => track.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
      'description': description,
      'isSystemPlaylist': isSystemPlaylist,
      'artwork': artwork,
    };
  }

  /// Get total duration of all tracks in the playlist
  Duration get totalDuration {
    final totalMs = tracks.fold<int>(0, (sum, track) => sum + track.duration);
    return Duration(milliseconds: totalMs);
  }

  /// Get number of tracks in the playlist
  int get trackCount => tracks.length;

  /// Get total size of all tracks in the playlist
  int get totalSize {
    return tracks.fold<int>(0, (sum, track) => sum + track.size);
  }

  /// Add a track to the playlist
  PlaylistModel addTrack(AudioModel track) {
    final newTracks = List<AudioModel>.from(tracks)..add(track);
    return copyWith(
      tracks: newTracks,
      modifiedAt: DateTime.now(),
    );
  }

  /// Remove a track from the playlist
  PlaylistModel removeTrack(AudioModel track) {
    final newTracks = tracks.where((t) => t.id != track.id).toList();
    return copyWith(
      tracks: newTracks,
      modifiedAt: DateTime.now(),
    );
  }

  /// Remove a track by index
  PlaylistModel removeTrackAt(int index) {
    if (index >= 0 && index < tracks.length) {
      final newTracks = List<AudioModel>.from(tracks)..removeAt(index);
      return copyWith(
        tracks: newTracks,
        modifiedAt: DateTime.now(),
      );
    }
    return this;
  }

  /// Move a track from one position to another
  PlaylistModel moveTrack(int fromIndex, int toIndex) {
    if (fromIndex >= 0 &&
        fromIndex < tracks.length &&
        toIndex >= 0 &&
        toIndex < tracks.length) {
      final newTracks = List<AudioModel>.from(tracks);
      final track = newTracks.removeAt(fromIndex);
      newTracks.insert(toIndex, track);
      return copyWith(
        tracks: newTracks,
        modifiedAt: DateTime.now(),
      );
    }
    return this;
  }

  /// Create a copy of the playlist with updated fields
  PlaylistModel copyWith({
    String? id,
    String? name,
    List<AudioModel>? tracks,
    DateTime? createdAt,
    DateTime? modifiedAt,
    String? description,
    bool? isSystemPlaylist,
    String? artwork,
  }) {
    return PlaylistModel(
      id: id ?? this.id,
      name: name ?? this.name,
      tracks: tracks ?? this.tracks,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      description: description ?? this.description,
      isSystemPlaylist: isSystemPlaylist ?? this.isSystemPlaylist,
      artwork: artwork ?? this.artwork,
    );
  }

  @override
  String toString() {
    return 'PlaylistModel(id: $id, name: $name, trackCount: $trackCount, totalDuration: $totalDuration)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlaylistModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Playlist types for different use cases
enum PlaylistType {
  /// User-created playlist
  user,

  /// System-generated playlist (e.g., Recently Played)
  system,

  /// Album-based playlist
  album,

  /// Artist-based playlist
  artist,

  /// Genre-based playlist
  genre,

  /// Folder-based playlist
  folder,
}

/// Playlist creation options
class PlaylistCreationOptions {
  /// Playlist name
  final String name;

  /// Playlist description
  final String? description;

  /// Initial tracks to add
  final List<AudioModel>? initialTracks;

  /// Playlist type
  final PlaylistType type;

  /// Whether to make it a system playlist
  final bool isSystemPlaylist;

  const PlaylistCreationOptions({
    required this.name,
    this.description,
    this.initialTracks,
    this.type = PlaylistType.user,
    this.isSystemPlaylist = false,
  });
}
