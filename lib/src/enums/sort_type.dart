/// Sort order enumeration
enum SortOrder {
  ascending,
  descending;

  /// Create SortOrder from string
  factory SortOrder.fromString(String order) {
    switch (order.toLowerCase()) {
      case 'asc':
      case 'ascending':
        return SortOrder.ascending;
      case 'desc':
      case 'descending':
        return SortOrder.descending;
      default:
        return SortOrder.ascending;
    }
  }

  @override
  String toString() {
    return name.toString();
  }
}

/// Audio sort type enumeration
enum AudioSortType {
  title,
  artist,
  album,
  genre,
  duration,
  size,
  dateAdded,
  dateModified,
  track,
  year,
  albumArtist,
  composer,
  fileExtension,
  displayName;

  /// Create AudioSortType from string
  factory AudioSortType.fromString(String type) {
    switch (type.toLowerCase()) {
      case 'title':
        return AudioSortType.title;
      case 'artist':
        return AudioSortType.artist;
      case 'album':
        return AudioSortType.album;
      case 'genre':
        return AudioSortType.genre;
      case 'duration':
        return AudioSortType.duration;
      case 'size':
        return AudioSortType.size;
      case 'date_added':
        return AudioSortType.dateAdded;
      case 'date_modified':
        return AudioSortType.dateModified;
      case 'track':
        return AudioSortType.track;
      case 'year':
        return AudioSortType.year;
      case 'album_artist':
        return AudioSortType.albumArtist;
      case 'composer':
        return AudioSortType.composer;
      case 'file_extension':
        return AudioSortType.fileExtension;
      case 'display_name':
        return AudioSortType.displayName;
      default:
        return AudioSortType.title;
    }
  }

  @override
  String toString() {
    return name.toString();
  }
}

/// Video sort type enumeration
enum VideoSortType {
  title,
  artist,
  album,
  genre,
  duration,
  size,
  dateAdded,
  dateModified,
  width,
  height,
  year,
  fileExtension,
  displayName,
  codec,
  bitrate,
  frameRate;

  /// Create VideoSortType from string
  factory VideoSortType.fromString(String type) {
    switch (type.toLowerCase()) {
      case 'title':
        return VideoSortType.title;
      case 'artist':
        return VideoSortType.artist;
      case 'album':
        return VideoSortType.album;
      case 'genre':
        return VideoSortType.genre;
      case 'duration':
        return VideoSortType.duration;
      case 'size':
        return VideoSortType.size;
      case 'date_added':
        return VideoSortType.dateAdded;
      case 'date_modified':
        return VideoSortType.dateModified;
      case 'width':
        return VideoSortType.width;
      case 'height':
        return VideoSortType.height;
      case 'year':
        return VideoSortType.year;
      case 'file_extension':
        return VideoSortType.fileExtension;
      case 'display_name':
        return VideoSortType.displayName;
      case 'codec':
        return VideoSortType.codec;
      case 'bitrate':
        return VideoSortType.bitrate;
      case 'frame_rate':
        return VideoSortType.frameRate;
      default:
        return VideoSortType.title;
    }
  }

  @override
  String toString() {
    return name.toString();
  }
}

/// Document sort type enumeration
enum DocumentSortType {
  title,
  size,
  dateAdded,
  dateModified,
  fileExtension,
  displayName,
  author,
  subject,
  pageCount,
  wordCount,
  language;

  /// Create DocumentSortType from string
  factory DocumentSortType.fromString(String type) {
    switch (type.toLowerCase()) {
      case 'title':
        return DocumentSortType.title;
      case 'size':
        return DocumentSortType.size;
      case 'date_added':
        return DocumentSortType.dateAdded;
      case 'date_modified':
        return DocumentSortType.dateModified;
      case 'file_extension':
        return DocumentSortType.fileExtension;
      case 'display_name':
        return DocumentSortType.displayName;
      case 'author':
        return DocumentSortType.author;
      case 'subject':
        return DocumentSortType.subject;
      case 'page_count':
        return DocumentSortType.pageCount;
      case 'word_count':
        return DocumentSortType.wordCount;
      case 'language':
        return DocumentSortType.language;
      default:
        return DocumentSortType.title;
    }
  }

  @override
  String toString() {
    return name.toString();
  }
}

/// Folder sort type enumeration
enum FolderSortType {
  name,
  path,
  dateCreated,
  dateModified,
  dateAccessed,
  totalSize,
  fileCount,
  directoryCount;

  /// Create FolderSortType from string
  factory FolderSortType.fromString(String type) {
    switch (type.toLowerCase()) {
      case 'name':
        return FolderSortType.name;
      case 'path':
        return FolderSortType.path;
      case 'date_created':
        return FolderSortType.dateCreated;
      case 'date_modified':
        return FolderSortType.dateModified;
      case 'date_accessed':
        return FolderSortType.dateAccessed;
      case 'total_size':
        return FolderSortType.totalSize;
      case 'file_count':
        return FolderSortType.fileCount;
      case 'directory_count':
        return FolderSortType.directoryCount;
      default:
        return FolderSortType.name;
    }
  }

  @override
  String toString() {
    return name.toString();
  }
}

/// Generic sort type for all media types
enum MediaSortType {
  title,
  size,
  dateAdded,
  dateModified,
  fileExtension,
  displayName,
  mimeType;

  /// Create MediaSortType from string
  factory MediaSortType.fromString(String type) {
    switch (type.toLowerCase()) {
      case 'title':
        return MediaSortType.title;
      case 'size':
        return MediaSortType.size;
      case 'date_added':
        return MediaSortType.dateAdded;
      case 'date_modified':
        return MediaSortType.dateModified;
      case 'file_extension':
        return MediaSortType.fileExtension;
      case 'display_name':
        return MediaSortType.displayName;
      case 'mime_type':
        return MediaSortType.mimeType;
      default:
        return MediaSortType.title;
    }
  }

  @override
  String toString() {
    return name.toString();
  }
}
