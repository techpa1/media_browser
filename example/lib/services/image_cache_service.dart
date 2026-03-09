import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:media_browser/media_browser.dart';

/// Service for caching and managing artwork images
class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  final MediaBrowser _mediaBrowser = MediaBrowser();
  final CacheManager _cacheManager = CacheManager(
    Config(
      'media_browser_cache',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 1000,
    ),
  );

  // In-memory cache for base64 decoded images
  final Map<String, ui.Image> _memoryCache = {};
  final Map<String, Uint8List> _bytesCache = {};

  /// Get cached artwork image
  Future<ui.Image?> getCachedArtwork(int id, ArtworkType type,
      {ArtworkSize size = ArtworkSize.medium}) async {
    final cacheKey = '${type.name}_${id}_${size.name}';

    // Check memory cache first
    if (_memoryCache.containsKey(cacheKey)) {
      return _memoryCache[cacheKey];
    }

    // Check bytes cache
    if (_bytesCache.containsKey(cacheKey)) {
      final bytes = _bytesCache[cacheKey]!;
      final image = await _decodeImage(bytes);
      if (image != null) {
        _memoryCache[cacheKey] = image;
        return image;
      }
    }

    // Load from media browser
    try {
      final artwork = await _mediaBrowser.queryArtwork(id, type, size: size);
      if (artwork.isAvailable) {
        Uint8List? bytes;

        // Handle file path
        if (artwork.filePath != null) {
          try {
            final file = File(artwork.filePath!);
            if (await file.exists()) {
              bytes = await file.readAsBytes();
              if (kDebugMode) {
                print(
                    '🎨 Loaded artwork from file path: ${bytes.length} bytes');
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error loading artwork from file path: $e');
            }
          }
        }

        if (bytes != null) {
          _bytesCache[cacheKey] = bytes;
          final image = await _decodeImage(bytes);
          if (image != null) {
            _memoryCache[cacheKey] = image;
            return image;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading artwork for $cacheKey: $e');
      }
    }

    return null;
  }

  /// Get cached artwork as bytes
  Future<Uint8List?> getCachedArtworkBytes(int id, ArtworkType type,
      {ArtworkSize size = ArtworkSize.medium}) async {
    final cacheKey = '${type.name}_${id}_${size.name}';

    // Check bytes cache first
    if (_bytesCache.containsKey(cacheKey)) {
      return _bytesCache[cacheKey];
    }

    // Load from media browser
    try {
      final artwork = await _mediaBrowser.queryArtwork(id, type, size: size);
      if (kDebugMode) {
        print(
            '🎨 Artwork query result for ${type.name}_$id: isAvailable=${artwork.isAvailable}, filePath=${artwork.filePath}, error=${artwork.error}');
      }
      if (artwork.isAvailable) {
        Uint8List? bytes;

        // Handle file path
        if (artwork.filePath != null) {
          try {
            final file = File(artwork.filePath!);
            if (await file.exists()) {
              bytes = await file.readAsBytes();
              if (kDebugMode) {
                print(
                    '🎨 Successfully loaded artwork from file path (${bytes.length} bytes)');
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error loading artwork from file path: $e');
            }
          }
        }

        if (bytes != null) {
          _bytesCache[cacheKey] = bytes;
          return bytes;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading artwork bytes for $cacheKey: $e');
      }
    }

    return null;
  }

  /// Decode image bytes to UI Image
  Future<ui.Image?> _decodeImage(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      if (kDebugMode) {
        print('Error decoding image: $e');
      }
      return null;
    }
  }

  /// Clear all caches
  void clearCache() {
    _memoryCache.clear();
    _bytesCache.clear();
    _cacheManager.emptyCache();
  }

  /// Clear cache for specific item
  void clearItemCache(int id, ArtworkType type) {
    final keysToRemove = <String>[];
    for (final key in _memoryCache.keys) {
      if (key.startsWith('${type.name}_${id}_')) {
        keysToRemove.add(key);
      }
    }

    for (final key in keysToRemove) {
      _memoryCache.remove(key);
      _bytesCache.remove(key);
    }
  }

  /// Get cache size
  int get cacheSize => _memoryCache.length + _bytesCache.length;

  /// Dispose resources
  void dispose() {
    clearCache();
  }
}
