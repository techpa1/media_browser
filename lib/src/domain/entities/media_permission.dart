import 'dart:io' as io;

/// Media permission entity representing different types of permissions
class MediaPermission {
  final String name;
  final String description;
  final bool isRequired;
  final PermissionType type;
  final PermissionStatus status;
  final bool canRequest;
  final bool shouldShowRationale;

  const MediaPermission({
    required this.name,
    required this.description,
    required this.isRequired,
    required this.type,
    this.status = PermissionStatus.denied,
    this.canRequest = true,
    this.shouldShowRationale = false,
  });

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MediaPermission && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;
}

/// Permission type enumeration
enum PermissionType {
  storage,
  audio,
  video,
  document,
  folder,
  mediaLibrary,
  photoLibrary,
}

/// Permission status enumeration
enum PermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  limited,
  provisional,
  notDetermined,
}

/// Permission result containing status and details
class PermissionResult {
  final PermissionStatus status;
  final String? message;
  final List<MediaPermission>? missingPermissions;

  const PermissionResult({
    required this.status,
    this.message,
    this.missingPermissions,
  });

  bool get isGranted => status == PermissionStatus.granted;
  bool get isDenied => status == PermissionStatus.denied;
  bool get isPermanentlyDenied => status == PermissionStatus.permanentlyDenied;

  @override
  String toString() {
    return 'PermissionResult(status: $status, message: $message, missingPermissions: $missingPermissions)';
  }
}

/// Predefined media permissions
class MediaPermissions {
  // Android permissions
  static const MediaPermission readExternalStorage = MediaPermission(
    name: 'android.permission.READ_EXTERNAL_STORAGE',
    description: 'Read external storage',
    isRequired: true,
    type: PermissionType.storage,
  );

  static const MediaPermission writeExternalStorage = MediaPermission(
    name: 'android.permission.WRITE_EXTERNAL_STORAGE',
    description: 'Write external storage',
    isRequired: false,
    type: PermissionType.storage,
  );

  static const MediaPermission readMediaAudio = MediaPermission(
    name: 'android.permission.READ_MEDIA_AUDIO',
    description: 'Read media audio files',
    isRequired: true,
    type: PermissionType.audio,
  );

  static const MediaPermission readMediaVideo = MediaPermission(
    name: 'android.permission.READ_MEDIA_VIDEO',
    description: 'Read media video files',
    isRequired: true,
    type: PermissionType.video,
  );

  static const MediaPermission readMediaImages = MediaPermission(
    name: 'android.permission.READ_MEDIA_IMAGES',
    description: 'Read media image files',
    isRequired: false,
    type: PermissionType.mediaLibrary,
  );

  // iOS permissions
  static const MediaPermission nsAppleMusicUsage = MediaPermission(
    name: 'NSAppleMusicUsageDescription',
    description: 'Access to music library',
    isRequired: true,
    type: PermissionType.audio,
  );

  static const MediaPermission nsPhotoLibraryUsage = MediaPermission(
    name: 'NSPhotoLibraryUsageDescription',
    description: 'Access to photo library',
    isRequired: false,
    type: PermissionType.photoLibrary,
  );

  static const MediaPermission nsMediaLibraryUsage = MediaPermission(
    name: 'NSMediaLibraryUsageDescription',
    description: 'Access to media library',
    isRequired: false,
    type: PermissionType.mediaLibrary,
  );

  /// Get all required permissions for a specific media type (platform-aware)
  static List<MediaPermission> getRequiredPermissions(MediaType mediaType) {
    switch (mediaType) {
      case MediaType.audio:
        if (io.Platform.isAndroid) {
          return [readExternalStorage, readMediaAudio];
        } else if (io.Platform.isIOS) {
          return [nsAppleMusicUsage];
        }
        return [readExternalStorage, readMediaAudio, nsAppleMusicUsage];
      case MediaType.video:
        if (io.Platform.isAndroid) {
          return [readExternalStorage, readMediaVideo];
        } else if (io.Platform.isIOS) {
          return [nsPhotoLibraryUsage];
        }
        return [readExternalStorage, readMediaVideo, nsPhotoLibraryUsage];
      case MediaType.document:
        if (io.Platform.isAndroid) {
          return [readExternalStorage];
        } else if (io.Platform.isIOS) {
          return []; // iOS doesn't need special permissions for documents
        }
        return [readExternalStorage];
      case MediaType.folder:
        if (io.Platform.isAndroid) {
          return [readExternalStorage];
        } else if (io.Platform.isIOS) {
          return []; // iOS doesn't need special permissions for folders
        }
        return [readExternalStorage];
      case MediaType.all:
        if (io.Platform.isAndroid) {
          return [
            readExternalStorage,
            readMediaAudio,
            readMediaVideo,
            readMediaImages,
          ];
        } else if (io.Platform.isIOS) {
          return [
            nsAppleMusicUsage,
            nsPhotoLibraryUsage,
          ];
        }
        return [
          readExternalStorage,
          readMediaAudio,
          readMediaVideo,
          readMediaImages,
          nsAppleMusicUsage,
          nsPhotoLibraryUsage,
        ];
    }
  }

  /// Get all permissions for a specific media type (required + optional, platform-aware)
  static List<MediaPermission> getAllPermissions(MediaType mediaType) {
    switch (mediaType) {
      case MediaType.audio:
        if (io.Platform.isAndroid) {
          return [
            readExternalStorage,
            writeExternalStorage,
            readMediaAudio,
          ];
        } else if (io.Platform.isIOS) {
          return [nsAppleMusicUsage];
        }
        return [
          readExternalStorage,
          writeExternalStorage,
          readMediaAudio,
          nsAppleMusicUsage
        ];
      case MediaType.video:
        if (io.Platform.isAndroid) {
          return [
            readExternalStorage,
            writeExternalStorage,
            readMediaVideo,
            readMediaImages,
          ];
        } else if (io.Platform.isIOS) {
          return [nsPhotoLibraryUsage, nsMediaLibraryUsage];
        }
        return [
          readExternalStorage,
          writeExternalStorage,
          readMediaVideo,
          readMediaImages,
          nsPhotoLibraryUsage,
          nsMediaLibraryUsage
        ];
      case MediaType.document:
        if (io.Platform.isAndroid) {
          return [readExternalStorage, writeExternalStorage];
        } else if (io.Platform.isIOS) {
          return []; // iOS doesn't need special permissions for documents
        }
        return [readExternalStorage, writeExternalStorage];
      case MediaType.folder:
        if (io.Platform.isAndroid) {
          return [readExternalStorage, writeExternalStorage];
        } else if (io.Platform.isIOS) {
          return []; // iOS doesn't need special permissions for folders
        }
        return [readExternalStorage, writeExternalStorage];
      case MediaType.all:
        if (io.Platform.isAndroid) {
          return [
            readExternalStorage,
            writeExternalStorage,
            readMediaAudio,
            readMediaVideo,
            readMediaImages,
          ];
        } else if (io.Platform.isIOS) {
          return [
            nsAppleMusicUsage,
            nsPhotoLibraryUsage,
            nsMediaLibraryUsage,
          ];
        }
        return [
          readExternalStorage,
          writeExternalStorage,
          readMediaAudio,
          readMediaVideo,
          readMediaImages,
          nsAppleMusicUsage,
          nsPhotoLibraryUsage,
          nsMediaLibraryUsage,
        ];
    }
  }
}

/// Media type enumeration
enum MediaType {
  audio,
  video,
  document,
  folder,
  all,
}
