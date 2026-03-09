import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/audio_model.dart';

/// Media player service with gapless playback support
class MediaPlayerService {
  static final MediaPlayerService _instance = MediaPlayerService._internal();
  factory MediaPlayerService() => _instance;
  MediaPlayerService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<AudioModel> _currentPlaylist = [];
  int _currentIndex = 0;
  bool _isShuffled = false;
  List<int> _shuffleIndices = [];

  // Stream controllers for state management
  final StreamController<PlayerState> _playerStateController =
      StreamController<PlayerState>.broadcast();
  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration> _durationController =
      StreamController<Duration>.broadcast();
  final StreamController<int> _currentTrackController =
      StreamController<int>.broadcast();
  final StreamController<bool> _isShuffledController =
      StreamController<bool>.broadcast();

  // Getters for streams
  Stream<PlayerState> get playerStateStream => _playerStateController.stream;
  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration> get durationStream => _durationController.stream;
  Stream<int> get currentTrackStream => _currentTrackController.stream;
  Stream<bool> get isShuffledStream => _isShuffledController.stream;

  // Current state getters
  PlayerState get currentState => _audioPlayer.playerState;
  Duration get currentPosition => _audioPlayer.position;
  Duration get currentDuration => _audioPlayer.duration ?? Duration.zero;
  int get currentTrackIndex => _currentIndex;
  bool get isShuffled => _isShuffled;
  List<AudioModel> get currentPlaylist => List.unmodifiable(_currentPlaylist);
  AudioModel? get currentTrack =>
      _currentPlaylist.isNotEmpty && _currentIndex < _currentPlaylist.length
          ? _currentPlaylist[_currentIndex]
          : null;

  /// Initialize the media player service
  Future<void> initialize() async {
    // Listen to player state changes
    _audioPlayer.playerStateStream.listen((state) {
      _playerStateController.add(state);
    });

    // Listen to position changes
    _audioPlayer.positionStream.listen((position) {
      _positionController.add(position);
    });

    // Listen to duration changes
    _audioPlayer.durationStream.listen((duration) {
      if (duration != null) {
        _durationController.add(duration);
      }
    });

    // Listen to sequence state changes for gapless playback
    _audioPlayer.sequenceStateStream.listen((sequenceState) {
      if (sequenceState != null) {
        _currentIndex = sequenceState.currentIndex;
        _currentTrackController.add(_currentIndex);
      }
    });
  }

  /// Load a playlist with gapless support
  Future<void> loadPlaylist(List<AudioModel> tracks,
      {int startIndex = 0}) async {
    try {
      _currentPlaylist.clear();
      _currentPlaylist.addAll(tracks);
      _currentIndex = startIndex.clamp(0, tracks.length - 1);

      // Create audio sources for gapless playback
      final audioSources = tracks.map((track) {
        // Handle different URI formats
        Uri uri;
        if (track.data.startsWith('http://') ||
            track.data.startsWith('https://')) {
          uri = Uri.parse(track.data);
        } else if (track.data.startsWith('file://')) {
          uri = Uri.parse(track.data);
        } else if (track.data.isNotEmpty) {
          uri = Uri.file(track.data);
        } else {
          throw Exception('Invalid or empty audio file path: ${track.data}');
        }

        return AudioSource.uri(
          uri,
          tag: AudioMetadata(
            album: track.album,
            title: track.title,
            artwork: track.artwork,
            artist: track.artist,
            duration: Duration(milliseconds: track.duration),
          ),
        );
      }).toList();

      // Create playlist with gapless support
      final playlist = ConcatenatingAudioSource(
        children: audioSources,
        useLazyPreparation: true, // Enable gapless preparation
      );

      // Load the playlist
      await _audioPlayer.setAudioSource(playlist, initialIndex: _currentIndex);

      _currentTrackController.add(_currentIndex);

      if (kDebugMode) {
        print(
            '🎵 Loaded playlist with ${tracks.length} tracks, starting at index $_currentIndex');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading playlist: $e');
      }
      rethrow;
    }
  }

  /// Play the current track
  Future<void> play() async {
    try {
      await _audioPlayer.play();
      if (kDebugMode) {
        print('▶️ Playing: ${currentTrack?.title}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error playing track: $e');
      }
      rethrow;
    }
  }

  /// Pause the current track
  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
      if (kDebugMode) {
        print('⏸️ Paused: ${currentTrack?.title}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error pausing track: $e');
      }
      rethrow;
    }
  }

  /// Stop the current track
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      if (kDebugMode) {
        print('⏹️ Stopped playback');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error stopping track: $e');
      }
      rethrow;
    }
  }

  /// Play next track (with gapless support)
  Future<void> next() async {
    try {
      if (_isShuffled && _shuffleIndices.isNotEmpty) {
        final currentShuffleIndex = _shuffleIndices.indexOf(_currentIndex);
        if (currentShuffleIndex < _shuffleIndices.length - 1) {
          _currentIndex = _shuffleIndices[currentShuffleIndex + 1];
        } else {
          _currentIndex = _shuffleIndices.first;
        }
      } else {
        _currentIndex = (_currentIndex + 1) % _currentPlaylist.length;
      }

      await _audioPlayer.seek(Duration.zero, index: _currentIndex);
      _currentTrackController.add(_currentIndex);

      if (kDebugMode) {
        print('⏭️ Next track: ${currentTrack?.title}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error playing next track: $e');
      }
      rethrow;
    }
  }

  /// Play previous track
  Future<void> previous() async {
    try {
      if (_isShuffled && _shuffleIndices.isNotEmpty) {
        final currentShuffleIndex = _shuffleIndices.indexOf(_currentIndex);
        if (currentShuffleIndex > 0) {
          _currentIndex = _shuffleIndices[currentShuffleIndex - 1];
        } else {
          _currentIndex = _shuffleIndices.last;
        }
      } else {
        _currentIndex = (_currentIndex - 1 + _currentPlaylist.length) %
            _currentPlaylist.length;
      }

      await _audioPlayer.seek(Duration.zero, index: _currentIndex);
      _currentTrackController.add(_currentIndex);

      if (kDebugMode) {
        print('⏮️ Previous track: ${currentTrack?.title}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error playing previous track: $e');
      }
      rethrow;
    }
  }

  /// Seek to a specific position
  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
      if (kDebugMode) {
        print('⏰ Seeked to: ${position.inSeconds}s');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error seeking: $e');
      }
      rethrow;
    }
  }

  /// Toggle shuffle mode
  Future<void> toggleShuffle() async {
    _isShuffled = !_isShuffled;

    if (_isShuffled) {
      _generateShuffleIndices();
    }

    _isShuffledController.add(_isShuffled);

    if (kDebugMode) {
      print('🔀 Shuffle ${_isShuffled ? 'enabled' : 'disabled'}');
    }
  }

  /// Generate shuffle indices
  void _generateShuffleIndices() {
    _shuffleIndices = List.generate(_currentPlaylist.length, (index) => index);
    _shuffleIndices.shuffle();

    // Ensure current track is first in shuffle
    _shuffleIndices.remove(_currentIndex);
    _shuffleIndices.insert(0, _currentIndex);
  }

  /// Play a specific track by index
  Future<void> playTrack(int index) async {
    if (index >= 0 && index < _currentPlaylist.length) {
      try {
        _currentIndex = index;
        await _audioPlayer.seek(Duration.zero, index: index);
        _currentTrackController.add(_currentIndex);

        if (kDebugMode) {
          print('🎵 Playing track at index $index: ${currentTrack?.title}');
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error playing track at index $index: $e');
        }
        rethrow;
      }
    }
  }

  /// Add tracks to the current playlist
  Future<void> addToPlaylist(List<AudioModel> tracks) async {
    final currentLength = _currentPlaylist.length;
    _currentPlaylist.addAll(tracks);

    // If this is the first track being added, load the playlist
    if (currentLength == 0 && tracks.isNotEmpty) {
      await loadPlaylist(_currentPlaylist);
    } else if (tracks.isNotEmpty) {
      // Add to existing playlist
      // Note: addAudioSource is not available in just_audio
      // We need to reload the entire playlist for now
      await loadPlaylist(_currentPlaylist);
    }

    if (kDebugMode) {
      print('➕ Added ${tracks.length} tracks to playlist');
    }
  }

  /// Clear the current playlist
  Future<void> clearPlaylist() async {
    await _audioPlayer.stop();
    _currentPlaylist.clear();
    _currentIndex = 0;
    _shuffleIndices.clear();
    _isShuffled = false;

    _currentTrackController.add(_currentIndex);
    _isShuffledController.add(_isShuffled);

    if (kDebugMode) {
      print('🗑️ Cleared playlist');
    }
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
    if (kDebugMode) {
      print('🔊 Volume set to: ${(volume * 100).round()}%');
    }
  }

  /// Get current volume
  double get volume => _audioPlayer.volume;

  /// Dispose resources
  Future<void> dispose() async {
    await _audioPlayer.dispose();
    await _playerStateController.close();
    await _positionController.close();
    await _durationController.close();
    await _currentTrackController.close();
    await _isShuffledController.close();
  }
}

/// Audio metadata for just_audio
class AudioMetadata {
  final String? album;
  final String? title;
  final String? artwork;
  final String? artist;
  final Duration? duration;

  const AudioMetadata({
    this.album,
    this.title,
    this.artwork,
    this.artist,
    this.duration,
  });
}
