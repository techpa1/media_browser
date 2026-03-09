/// Import the required types
import 'media_permission.dart';
import '../../models/artwork_model.dart';

/// Base class for all media-related errors
abstract class MediaError implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const MediaError({
    required this.message,
    this.code,
    this.details,
  });

  @override
  String toString() =>
      'MediaError: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Permission-related errors
class PermissionError extends MediaError {
  final List<MediaPermission> missingPermissions;
  final PermissionStatus status;

  const PermissionError({
    required String message,
    required this.missingPermissions,
    required this.status,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);

  @override
  String toString() =>
      'PermissionError: $message (Status: $status, Missing: ${missingPermissions.map((p) => p.name).join(', ')})';
}

/// Platform-specific errors
class PlatformError extends MediaError {
  final String platform;
  final String? nativeError;

  const PlatformError({
    required String message,
    required this.platform,
    this.nativeError,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);

  @override
  String toString() =>
      'PlatformError ($platform): $message${nativeError != null ? ' (Native: $nativeError)' : ''}';
}

/// Query-related errors
class QueryError extends MediaError {
  final String queryType;
  final String? queryPath;

  const QueryError({
    required String message,
    required this.queryType,
    this.queryPath,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);

  @override
  String toString() =>
      'QueryError ($queryType): $message${queryPath != null ? ' (Path: $queryPath)' : ''}';
}

/// Artwork-related errors
class ArtworkError extends MediaError {
  final int mediaId;
  final ArtworkType artworkType;

  const ArtworkError({
    required String message,
    required this.mediaId,
    required this.artworkType,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);

  @override
  String toString() =>
      'ArtworkError (ID: $mediaId, Type: $artworkType): $message';
}

/// Validation errors
class ValidationError extends MediaError {
  final String field;
  final dynamic value;

  const ValidationError({
    required String message,
    required this.field,
    this.value,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);

  @override
  String toString() =>
      'ValidationError ($field): $message${value != null ? ' (Value: $value)' : ''}';
}

/// Network-related errors (for future cloud storage support)
class NetworkError extends MediaError {
  final int? statusCode;
  final String? url;

  const NetworkError({
    required String message,
    this.statusCode,
    this.url,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);

  @override
  String toString() =>
      'NetworkError: $message${statusCode != null ? ' (Status: $statusCode)' : ''}${url != null ? ' (URL: $url)' : ''}';
}

/// Storage-related errors
class StorageError extends MediaError {
  final String? path;
  final String? operation;

  const StorageError({
    required String message,
    this.path,
    this.operation,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);

  @override
  String toString() =>
      'StorageError${operation != null ? ' ($operation)' : ''}: $message${path != null ? ' (Path: $path)' : ''}';
}

/// Common error factory
class MediaErrorFactory {
  /// Create permission error
  static PermissionError permissionDenied({
    required List<MediaPermission> missingPermissions,
    required PermissionStatus status,
    String? message,
  }) {
    return PermissionError(
      message: message ?? 'Required permissions are not granted',
      missingPermissions: missingPermissions,
      status: status,
      code: 'PERMISSION_DENIED',
    );
  }

  /// Create platform error
  static PlatformError platformError({
    required String platform,
    required String message,
    String? nativeError,
    String? code,
  }) {
    return PlatformError(
      message: message,
      platform: platform,
      nativeError: nativeError,
      code: code ?? 'PLATFORM_ERROR',
    );
  }

  /// Create query error
  static QueryError queryError({
    required String queryType,
    required String message,
    String? queryPath,
    String? code,
  }) {
    return QueryError(
      message: message,
      queryType: queryType,
      queryPath: queryPath,
      code: code ?? 'QUERY_ERROR',
    );
  }

  /// Create artwork error
  static ArtworkError artworkError({
    required int mediaId,
    required ArtworkType artworkType,
    required String message,
    String? code,
  }) {
    return ArtworkError(
      message: message,
      mediaId: mediaId,
      artworkType: artworkType,
      code: code ?? 'ARTWORK_ERROR',
    );
  }

  /// Create validation error
  static ValidationError validationError({
    required String field,
    required String message,
    dynamic value,
    String? code,
  }) {
    return ValidationError(
      message: message,
      field: field,
      value: value,
      code: code ?? 'VALIDATION_ERROR',
    );
  }

  /// Create storage error
  static StorageError storageError({
    required String message,
    String? path,
    String? operation,
    String? code,
  }) {
    return StorageError(
      message: message,
      path: path,
      operation: operation,
      code: code ?? 'STORAGE_ERROR',
    );
  }
}
