/// Folder model containing information about directories
class FolderModel {
  /// Unique identifier for the folder
  final int id;

  /// Name of the folder
  final String name;

  /// Full path of the folder
  final String path;

  /// Parent folder path
  final String parentPath;

  /// Date created timestamp
  final int dateCreated;

  /// Date modified timestamp
  final int dateModified;

  /// Date accessed timestamp
  final int dateAccessed;

  /// Total size of folder contents in bytes
  final int totalSize;

  /// Number of files in the folder
  final int fileCount;

  /// Number of subdirectories in the folder
  final int directoryCount;

  /// Whether the folder is hidden
  final bool isHidden;

  /// Whether the folder is read-only
  final bool isReadOnly;

  /// Whether the folder is a system folder
  final bool isSystem;

  /// Folder type category
  final FolderType folderType;

  /// Storage location
  final StorageLocation storageLocation;

  const FolderModel({
    required this.id,
    required this.name,
    required this.path,
    required this.parentPath,
    required this.dateCreated,
    required this.dateModified,
    required this.dateAccessed,
    required this.totalSize,
    required this.fileCount,
    required this.directoryCount,
    required this.isHidden,
    required this.isReadOnly,
    required this.isSystem,
    required this.folderType,
    required this.storageLocation,
  });

  /// Create FolderModel from Map
  factory FolderModel.fromMap(Map<String, dynamic> map) {
    return FolderModel(
      id: map['id'] ?? 0,
      name: map['name'] ?? '',
      path: map['path'] ?? '',
      parentPath: map['parent_path'] ?? '',
      dateCreated: map['date_created'] ?? 0,
      dateModified: map['date_modified'] ?? 0,
      dateAccessed: map['date_accessed'] ?? 0,
      totalSize: map['total_size'] ?? 0,
      fileCount: map['file_count'] ?? 0,
      directoryCount: map['directory_count'] ?? 0,
      isHidden: map['is_hidden'] ?? false,
      isReadOnly: map['is_read_only'] ?? false,
      isSystem: map['is_system'] ?? false,
      folderType: FolderType.fromString(map['folder_type'] ?? ''),
      storageLocation:
          StorageLocation.fromString(map['storage_location'] ?? ''),
    );
  }

  /// Convert FolderModel to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'parent_path': parentPath,
      'date_created': dateCreated,
      'date_modified': dateModified,
      'date_accessed': dateAccessed,
      'total_size': totalSize,
      'file_count': fileCount,
      'directory_count': directoryCount,
      'is_hidden': isHidden,
      'is_read_only': isReadOnly,
      'is_system': isSystem,
      'folder_type': folderType.toString(),
      'storage_location': storageLocation.toString(),
    };
  }

  /// Get formatted size string
  String get formattedSize {
    if (totalSize < 1024) return '$totalSize B';
    if (totalSize < 1024 * 1024)
      return '${(totalSize / 1024).toStringAsFixed(1)} KB';
    if (totalSize < 1024 * 1024 * 1024)
      return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(totalSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Get total item count (files + directories)
  int get totalItemCount => fileCount + directoryCount;

  @override
  String toString() {
    return 'FolderModel(id: $id, name: $name, path: $path, folderType: $folderType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FolderModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Folder type enumeration
enum FolderType {
  music,
  video,
  documents,
  pictures,
  downloads,
  dcim,
  movies,
  podcasts,
  audiobooks,
  ringtones,
  notifications,
  alarms,
  system,
  cache,
  temp,
  other;

  /// Create FolderType from string
  factory FolderType.fromString(String type) {
    switch (type.toLowerCase()) {
      case 'music':
        return FolderType.music;
      case 'video':
        return FolderType.video;
      case 'documents':
        return FolderType.documents;
      case 'pictures':
        return FolderType.pictures;
      case 'downloads':
        return FolderType.downloads;
      case 'dcim':
        return FolderType.dcim;
      case 'movies':
        return FolderType.movies;
      case 'podcasts':
        return FolderType.podcasts;
      case 'audiobooks':
        return FolderType.audiobooks;
      case 'ringtones':
        return FolderType.ringtones;
      case 'notifications':
        return FolderType.notifications;
      case 'alarms':
        return FolderType.alarms;
      case 'system':
        return FolderType.system;
      case 'cache':
        return FolderType.cache;
      case 'temp':
        return FolderType.temp;
      default:
        return FolderType.other;
    }
  }

  @override
  String toString() {
    return name;
  }
}

/// Storage location enumeration
enum StorageLocation {
  internal,
  external,
  sdCard,
  usb,
  cloud,
  network,
  other;

  /// Create StorageLocation from string
  factory StorageLocation.fromString(String location) {
    switch (location.toLowerCase()) {
      case 'internal':
        return StorageLocation.internal;
      case 'external':
        return StorageLocation.external;
      case 'sd_card':
        return StorageLocation.sdCard;
      case 'usb':
        return StorageLocation.usb;
      case 'cloud':
        return StorageLocation.cloud;
      case 'network':
        return StorageLocation.network;
      default:
        return StorageLocation.other;
    }
  }

  @override
  String toString() {
    return name;
  }
}
