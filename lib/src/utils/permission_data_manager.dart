import 'dart:async';
import '../domain/entities/permission_change_event.dart';
import '../enums/media_filter.dart';

/// A utility class to help manage data based on permission changes
/// This class provides methods to handle permission changes and manage data accordingly
class PermissionDataManager {
  final Stream<PermissionChangeEvent> _permissionChangeStream;
  StreamSubscription<PermissionChangeEvent>? _subscription;

  // Callbacks for different media types
  final Map<MediaType, VoidCallback> _onPermissionGranted = {};
  final Map<MediaType, VoidCallback> _onPermissionDenied = {};

  PermissionDataManager(this._permissionChangeStream);

  /// Start listening to permission changes
  void startListening() {
    _subscription = _permissionChangeStream.listen(_handlePermissionChange);
  }

  /// Stop listening to permission changes
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Set callback for when permissions are granted for a specific media type
  void setOnPermissionGranted(MediaType mediaType, VoidCallback callback) {
    _onPermissionGranted[mediaType] = callback;
  }

  /// Set callback for when permissions are denied for a specific media type
  void setOnPermissionDenied(MediaType mediaType, VoidCallback callback) {
    _onPermissionDenied[mediaType] = callback;
  }

  /// Set callback for when permissions are granted for all media types
  /// Note: This uses MediaType.other internally to represent "all" media types
  void setOnAllPermissionsGranted(VoidCallback callback) {
    _onPermissionGranted[MediaType.other] =
        callback; // Use 'other' to represent 'all'
  }

  /// Set callback for when permissions are denied for all media types
  /// Note: This uses MediaType.other internally to represent "all" media types
  void setOnAllPermissionsDenied(VoidCallback callback) {
    _onPermissionDenied[MediaType.other] =
        callback; // Use 'other' to represent 'all'
  }

  /// Handle permission change events
  void _handlePermissionChange(PermissionChangeEvent event) {
    for (final mediaType in event.affectedMediaTypes) {
      _handleMediaTypePermissionChange(mediaType, event);
    }

    // Also handle "all" media type if any storage permission changed
    if (_hasStoragePermissionChange(event)) {
      _handleMediaTypePermissionChange(MediaType.other, event);
    }
  }

  /// Handle permission change for a specific media type
  void _handleMediaTypePermissionChange(
      MediaType mediaType, PermissionChangeEvent event) {
    final hasGranted = _hasPermissionGranted(mediaType, event);
    final hasDenied = _hasPermissionDenied(mediaType, event);

    if (hasGranted) {
      _onPermissionGranted[mediaType]?.call();
    }

    if (hasDenied) {
      _onPermissionDenied[mediaType]?.call();
    }
  }

  /// Check if any permission was granted for the given media type
  bool _hasPermissionGranted(MediaType mediaType, PermissionChangeEvent event) {
    for (final change in event.changes.values) {
      if (change.granted &&
          _isPermissionForMediaType(change.permission, mediaType)) {
        return true;
      }
    }
    return false;
  }

  /// Check if any permission was denied for the given media type
  bool _hasPermissionDenied(MediaType mediaType, PermissionChangeEvent event) {
    for (final change in event.changes.values) {
      if (change.denied &&
          _isPermissionForMediaType(change.permission, mediaType)) {
        return true;
      }
    }
    return false;
  }

  /// Check if a permission change affects storage (all media types)
  bool _hasStoragePermissionChange(PermissionChangeEvent event) {
    for (final change in event.changes.values) {
      if (_isStoragePermission(change.permission)) {
        return true;
      }
    }
    return false;
  }

  /// Check if a permission is for a specific media type
  bool _isPermissionForMediaType(String permission, MediaType mediaType) {
    final lowerPermission = permission.toLowerCase();

    switch (mediaType) {
      case MediaType.audio:
        return lowerPermission.contains('audio') ||
            lowerPermission.contains('music') ||
            lowerPermission.contains('apple');
      case MediaType.video:
        return lowerPermission.contains('video') ||
            lowerPermission.contains('photo') ||
            lowerPermission.contains('library');
      case MediaType.document:
      case MediaType.folder:
        return lowerPermission.contains('storage') ||
            lowerPermission.contains('external');
      case MediaType.image:
        return lowerPermission.contains('photo') ||
            lowerPermission.contains('image') ||
            lowerPermission.contains('library');
      case MediaType.archive:
        return lowerPermission.contains('storage') ||
            lowerPermission.contains('external');
      case MediaType.other:
        return _isStoragePermission(permission);
    }
  }

  /// Check if a permission is a storage permission
  bool _isStoragePermission(String permission) {
    final lowerPermission = permission.toLowerCase();
    return lowerPermission.contains('storage') ||
        lowerPermission.contains('external');
  }
}

/// A typedef for void callbacks
typedef VoidCallback = void Function();
