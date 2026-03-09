import '../entities/media_permission.dart';
import '../entities/media_error.dart';
import '../repositories/media_repository.dart';

/// Use case for checking media permissions
class CheckPermissionsUseCase {
  final MediaRepository _repository;

  const CheckPermissionsUseCase(this._repository);

  /// Check if required permissions are granted for specific media type
  Future<PermissionResult> call(MediaType mediaType) async {
    try {
      return await _repository.checkPermissions(mediaType);
    } catch (e) {
      if (e is MediaError) {
        rethrow;
      }
      throw MediaErrorFactory.platformError(
        platform: 'unknown',
        message: 'Failed to check permissions: ${e.toString()}',
        code: 'PERMISSION_CHECK_FAILED',
      );
    }
  }

  /// Check if all required permissions are granted
  Future<bool> areAllRequiredPermissionsGranted(MediaType mediaType) async {
    final result = await call(mediaType);
    return result.isGranted;
  }

  /// Get missing required permissions
  Future<List<MediaPermission>> getMissingRequiredPermissions(
      MediaType mediaType) async {
    final result = await call(mediaType);
    return result.missingPermissions ?? [];
  }

  /// Check if specific permission is granted
  Future<bool> isPermissionGranted(MediaPermission permission) async {
    try {
      final result = await call(MediaType.all);
      if (result.isGranted) return true;

      final missingPermissions = result.missingPermissions ?? [];
      return !missingPermissions.contains(permission);
    } catch (e) {
      return false;
    }
  }
}
