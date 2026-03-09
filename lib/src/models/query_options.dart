import '../enums/sort_type.dart';
import '../enums/media_filter.dart';

/// Query options for filtering and sorting media
class QueryOptions {
  /// Sort type for the query
  final dynamic sortType;

  /// Sort order (ascending/descending)
  final SortOrder sortOrder;

  /// Whether to ignore case when sorting
  final bool ignoreCase;

  /// File size range filter
  final FileSizeRange? sizeRange;

  /// Date range filter
  final DateRange? dateRange;

  /// File extensions to include
  final List<String>? includeExtensions;

  /// File extensions to exclude
  final List<String>? excludeExtensions;

  /// MIME types to include
  final List<String>? includeMimeTypes;

  /// MIME types to exclude
  final List<String>? excludeMimeTypes;

  /// Search query for filtering by name/title
  final String? searchQuery;

  /// Whether to include hidden files
  final bool includeHidden;

  /// Whether to include system files
  final bool includeSystem;

  /// Maximum number of results to return
  final int? limit;

  /// Offset for pagination
  final int? offset;

  const QueryOptions({
    this.sortType,
    this.sortOrder = SortOrder.ascending,
    this.ignoreCase = true,
    this.sizeRange,
    this.dateRange,
    this.includeExtensions,
    this.excludeExtensions,
    this.includeMimeTypes,
    this.excludeMimeTypes,
    this.searchQuery,
    this.includeHidden = false,
    this.includeSystem = false,
    this.limit,
    this.offset,
  });

  /// Create QueryOptions from Map
  factory QueryOptions.fromMap(Map<String, dynamic> map) {
    return QueryOptions(
      sortType: map['sort_type'],
      sortOrder: SortOrder.fromString(map['sort_order'] ?? 'ascending'),
      ignoreCase: map['ignore_case'] ?? true,
      sizeRange: map['size_range'] != null
          ? FileSizeRange(
              minSize: map['size_range']['min_size'] ?? 0,
              maxSize: map['size_range']['max_size'] ?? -1,
            )
          : null,
      dateRange: map['date_range'] != null
          ? DateRange(
              startDate: map['date_range']['start_date'] ?? 0,
              endDate: map['date_range']['end_date'] ?? -1,
            )
          : null,
      includeExtensions: map['include_extensions'] != null
          ? List<String>.from(map['include_extensions'])
          : null,
      excludeExtensions: map['exclude_extensions'] != null
          ? List<String>.from(map['exclude_extensions'])
          : null,
      includeMimeTypes: map['include_mime_types'] != null
          ? List<String>.from(map['include_mime_types'])
          : null,
      excludeMimeTypes: map['exclude_mime_types'] != null
          ? List<String>.from(map['exclude_mime_types'])
          : null,
      searchQuery: map['search_query'],
      includeHidden: map['include_hidden'] ?? false,
      includeSystem: map['include_system'] ?? false,
      limit: map['limit'],
      offset: map['offset'],
    );
  }

  /// Convert QueryOptions to Map
  Map<String, dynamic> toMap() {
    return {
      'sort_type': sortType?.toString(),
      'sort_order': sortOrder.toString(),
      'ignore_case': ignoreCase,
      'size_range': sizeRange != null
          ? {
              'min_size': sizeRange!.minSize,
              'max_size': sizeRange!.maxSize,
            }
          : null,
      'date_range': dateRange != null
          ? {
              'start_date': dateRange!.startDate,
              'end_date': dateRange!.endDate,
            }
          : null,
      'include_extensions': includeExtensions,
      'exclude_extensions': excludeExtensions,
      'include_mime_types': includeMimeTypes,
      'exclude_mime_types': excludeMimeTypes,
      'search_query': searchQuery,
      'include_hidden': includeHidden,
      'include_system': includeSystem,
      'limit': limit,
      'offset': offset,
    };
  }

  /// Create a copy of QueryOptions with updated values
  QueryOptions copyWith({
    dynamic sortType,
    SortOrder? sortOrder,
    bool? ignoreCase,
    FileSizeRange? sizeRange,
    DateRange? dateRange,
    List<String>? includeExtensions,
    List<String>? excludeExtensions,
    List<String>? includeMimeTypes,
    List<String>? excludeMimeTypes,
    String? searchQuery,
    bool? includeHidden,
    bool? includeSystem,
    int? limit,
    int? offset,
  }) {
    return QueryOptions(
      sortType: sortType ?? this.sortType,
      sortOrder: sortOrder ?? this.sortOrder,
      ignoreCase: ignoreCase ?? this.ignoreCase,
      sizeRange: sizeRange ?? this.sizeRange,
      dateRange: dateRange ?? this.dateRange,
      includeExtensions: includeExtensions ?? this.includeExtensions,
      excludeExtensions: excludeExtensions ?? this.excludeExtensions,
      includeMimeTypes: includeMimeTypes ?? this.includeMimeTypes,
      excludeMimeTypes: excludeMimeTypes ?? this.excludeMimeTypes,
      searchQuery: searchQuery ?? this.searchQuery,
      includeHidden: includeHidden ?? this.includeHidden,
      includeSystem: includeSystem ?? this.includeSystem,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  @override
  String toString() {
    return 'QueryOptions(sortType: $sortType, sortOrder: $sortOrder, searchQuery: $searchQuery)';
  }
}

/// Audio-specific query options
class AudioQueryOptions extends QueryOptions {
  /// Whether to include music files
  final bool includeMusic;

  /// Whether to include ringtones
  final bool includeRingtones;

  /// Whether to include alarms
  final bool includeAlarms;

  /// Whether to include notifications
  final bool includeNotifications;

  /// Whether to include podcasts
  final bool includePodcasts;

  /// Whether to include audiobooks
  final bool includeAudiobooks;

  /// Minimum duration in milliseconds
  final int? minDuration;

  /// Maximum duration in milliseconds
  final int? maxDuration;

  /// Artist filter
  final String? artistFilter;

  /// Album filter
  final String? albumFilter;

  /// Genre filter
  final String? genreFilter;

  const AudioQueryOptions({
    super.sortType,
    super.sortOrder = SortOrder.ascending,
    super.ignoreCase = true,
    super.sizeRange,
    super.dateRange,
    super.includeExtensions,
    super.excludeExtensions,
    super.includeMimeTypes,
    super.excludeMimeTypes,
    super.searchQuery,
    super.includeHidden = false,
    super.includeSystem = false,
    super.limit,
    super.offset,
    this.includeMusic = true,
    this.includeRingtones = false,
    this.includeAlarms = false,
    this.includeNotifications = false,
    this.includePodcasts = true,
    this.includeAudiobooks = true,
    this.minDuration,
    this.maxDuration,
    this.artistFilter,
    this.albumFilter,
    this.genreFilter,
  });

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'include_music': includeMusic,
      'include_ringtones': includeRingtones,
      'include_alarms': includeAlarms,
      'include_notifications': includeNotifications,
      'include_podcasts': includePodcasts,
      'include_audiobooks': includeAudiobooks,
      'min_duration': minDuration,
      'max_duration': maxDuration,
      'artist_filter': artistFilter,
      'album_filter': albumFilter,
      'genre_filter': genreFilter,
    });
    return map;
  }
}

/// Video-specific query options
class VideoQueryOptions extends QueryOptions {
  /// Whether to include movies
  final bool includeMovies;

  /// Whether to include TV shows
  final bool includeTvShows;

  /// Whether to include music videos
  final bool includeMusicVideos;

  /// Whether to include trailers
  final bool includeTrailers;

  /// Minimum duration in milliseconds
  final int? minDuration;

  /// Maximum duration in milliseconds
  final int? maxDuration;

  /// Minimum resolution width
  final int? minWidth;

  /// Maximum resolution width
  final int? maxWidth;

  /// Minimum resolution height
  final int? minHeight;

  /// Maximum resolution height
  final int? maxHeight;

  const VideoQueryOptions({
    super.sortType,
    super.sortOrder = SortOrder.ascending,
    super.ignoreCase = true,
    super.sizeRange,
    super.dateRange,
    super.includeExtensions,
    super.excludeExtensions,
    super.includeMimeTypes,
    super.excludeMimeTypes,
    super.searchQuery,
    super.includeHidden = false,
    super.includeSystem = false,
    super.limit,
    super.offset,
    this.includeMovies = true,
    this.includeTvShows = true,
    this.includeMusicVideos = true,
    this.includeTrailers = true,
    this.minDuration,
    this.maxDuration,
    this.minWidth,
    this.maxWidth,
    this.minHeight,
    this.maxHeight,
  });

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'include_movies': includeMovies,
      'include_tv_shows': includeTvShows,
      'include_music_videos': includeMusicVideos,
      'include_trailers': includeTrailers,
      'min_duration': minDuration,
      'max_duration': maxDuration,
      'min_width': minWidth,
      'max_width': maxWidth,
      'min_height': minHeight,
      'max_height': maxHeight,
    });
    return map;
  }
}
