import '../../enums/media_filter.dart';

/// Represents a permission change event
class PermissionChangeEvent {
  /// The type of event (e.g., "permission_changed")
  final String type;

  /// Timestamp when the event occurred
  final int timestamp;

  /// The changes that occurred
  final Map<String, PermissionChange> changes;

  /// Media types that are affected by these permission changes
  final List<MediaType> affectedMediaTypes;

  const PermissionChangeEvent({
    required this.type,
    required this.timestamp,
    required this.changes,
    required this.affectedMediaTypes,
  });

  /// Create from platform data
  factory PermissionChangeEvent.fromMap(Map<String, dynamic> map) {
    final changes = <String, PermissionChange>{};

    if (map['changes'] != null) {
      final changesMap = map['changes'] as Map<String, dynamic>;
      changesMap.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          changes[key] = PermissionChange.fromMap(value);
        }
      });
    }

    // Parse affected media types
    final affectedMediaTypes = <MediaType>[];
    if (map['affectedMediaTypes'] != null) {
      final typesList = map['affectedMediaTypes'] as List<dynamic>? ?? [];
      for (final type in typesList) {
        if (type is String) {
          final mediaType = _parseMediaType(type);
          if (mediaType != null) {
            affectedMediaTypes.add(mediaType);
          }
        }
      }
    } else {
      // Fallback: determine affected media types from changes
      for (final change in changes.values) {
        final mediaType = _parseMediaTypeFromPermission(change.permission);
        if (mediaType != null && !affectedMediaTypes.contains(mediaType)) {
          affectedMediaTypes.add(mediaType);
        }
      }
    }

    return PermissionChangeEvent(
      type: map['type'] ?? 'unknown',
      timestamp: map['timestamp'] ?? 0,
      changes: changes,
      affectedMediaTypes: affectedMediaTypes,
    );
  }

  /// Convert to map for debugging
  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'timestamp': timestamp,
      'changes': changes.map((key, value) => MapEntry(key, value.toMap())),
      'affectedMediaTypes':
          affectedMediaTypes.map((type) => type.toString()).toList(),
    };
  }

  @override
  String toString() {
    return 'PermissionChangeEvent(type: $type, timestamp: $timestamp, changes: $changes, affectedMediaTypes: $affectedMediaTypes)';
  }

  /// Parse media type from string
  static MediaType? _parseMediaType(String type) {
    switch (type.toLowerCase()) {
      case 'audio':
        return MediaType.audio;
      case 'video':
        return MediaType.video;
      case 'document':
        return MediaType.document;
      case 'folder':
        return MediaType.folder;
      case 'all':
        return MediaType.other; // Use 'other' to represent 'all' media types
      default:
        return null;
    }
  }

  /// Parse media type from permission name
  static MediaType? _parseMediaTypeFromPermission(String permission) {
    final lowerPermission = permission.toLowerCase();

    // Android permissions
    if (lowerPermission.contains('audio') ||
        lowerPermission.contains('music')) {
      return MediaType.audio;
    } else if (lowerPermission.contains('video') ||
        lowerPermission.contains('photo')) {
      return MediaType.video;
    } else if (lowerPermission.contains('storage') ||
        lowerPermission.contains('external')) {
      return MediaType.other; // Storage permission affects all media types
    }

    // iOS permissions
    if (lowerPermission.contains('music') ||
        lowerPermission.contains('apple')) {
      return MediaType.audio;
    } else if (lowerPermission.contains('photo') ||
        lowerPermission.contains('library')) {
      return MediaType.video;
    }

    return null;
  }
}

/// Represents a change in a specific permission
class PermissionChange {
  /// The permission name (Android) or type (iOS)
  final String permission;

  /// Previous state of the permission
  final bool previous;

  /// Current state of the permission
  final bool current;

  /// Whether the permission is currently granted
  final bool granted;

  /// Whether the permission is currently denied
  final bool denied;

  const PermissionChange({
    required this.permission,
    required this.previous,
    required this.current,
    required this.granted,
    required this.denied,
  });

  /// Create from platform data
  factory PermissionChange.fromMap(Map<String, dynamic> map) {
    return PermissionChange(
      permission: map['permission'] ?? map['type'] ?? 'unknown',
      previous: map['previous'] ?? false,
      current: map['current'] ?? false,
      granted: map['granted'] ?? false,
      denied: map['denied'] ?? false,
    );
  }

  /// Convert to map for debugging
  Map<String, dynamic> toMap() {
    return {
      'permission': permission,
      'previous': previous,
      'current': current,
      'granted': granted,
      'denied': denied,
    };
  }

  @override
  String toString() {
    return 'PermissionChange(permission: $permission, previous: $previous, current: $current, granted: $granted, denied: $denied)';
  }
}
