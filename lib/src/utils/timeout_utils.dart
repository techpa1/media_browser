import 'dart:async';
import '../domain/entities/media_error.dart';

/// Utility class for handling timeouts in media operations
class TimeoutUtils {
  /// Default timeout duration for media operations (45 seconds)
  static const Duration defaultTimeout = Duration(seconds: 45);

  /// Short timeout for quick operations (10 seconds)
  static const Duration shortTimeout = Duration(seconds: 10);

  /// Long timeout for heavy operations (60 seconds)
  static const Duration longTimeout = Duration(seconds: 60);

  /// Execute a future with timeout and proper error handling
  static Future<T> executeWithTimeout<T>(
    Future<T> Function() operation, {
    Duration? timeout,
    String? operationName,
  }) async {
    final timeoutDuration = timeout ?? defaultTimeout;
    final name = operationName ?? 'operation';

    try {
      return await operation().timeout(
        timeoutDuration,
        onTimeout: () {
          throw MediaErrorFactory.platformError(
            platform: 'timeout',
            message:
                'Operation "$name" timed out after ${timeoutDuration.inSeconds} seconds',
            code: 'OPERATION_TIMEOUT',
          );
        },
      );
    } catch (e) {
      if (e is MediaError) {
        rethrow;
      }
      throw MediaErrorFactory.platformError(
        platform: 'timeout',
        message: 'Operation "$name" failed: ${e.toString()}',
        code: 'OPERATION_FAILED',
      ); 
    }
  }

  /// Execute multiple operations with individual timeouts
  static Future<List<T>> executeMultipleWithTimeout<T>(
    List<Future<T> Function()> operations, {
    Duration? timeout,
    String? operationName,
  }) async {
    final timeoutDuration = timeout ?? defaultTimeout;
    final name = operationName ?? 'batch_operation';

    final futures = operations
        .map((operation) => executeWithTimeout(operation,
            timeout: timeoutDuration, operationName: name))
        .toList();

    try {
      return await Future.wait(futures);
    } catch (e) {
      if (e is MediaError) {
        rethrow;
      }
      throw MediaErrorFactory.platformError(
        platform: 'timeout',
        message: 'Batch operation "$name" failed: ${e.toString()}',
        code: 'BATCH_OPERATION_FAILED',
      );
    }
  }

  /// Execute operation with retry logic and timeout
  static Future<T> executeWithRetryAndTimeout<T>(
    Future<T> Function() operation, {
    Duration? timeout,
    int maxRetries = 3,
    Duration? retryDelay,
    String? operationName,
  }) async {
    final timeoutDuration = timeout ?? defaultTimeout;
    final delay = retryDelay ?? const Duration(seconds: 2);
    final name = operationName ?? 'operation';

    int attempts = 0;
    Exception? lastException;

    while (attempts < maxRetries) {
      attempts++;

      try {
        return await executeWithTimeout(
          operation,
          timeout: timeoutDuration,
          operationName: '$name (attempt $attempts)',
        );
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());

        if (attempts < maxRetries) {
          await Future.delayed(delay);
        }
      }
    }

    throw MediaErrorFactory.platformError(
      platform: 'timeout',
      message:
          'Operation "$name" failed after $maxRetries attempts: ${lastException?.toString()}',
      code: 'OPERATION_MAX_RETRIES_EXCEEDED',
    );
  }

  /// Get appropriate timeout for different operation types
  static Duration getTimeoutForOperation(String operationType) {
    switch (operationType.toLowerCase()) {
      case 'permission_check':
      case 'permission_request':
      case 'platform_version':
      case 'device_info':
        return shortTimeout;
      case 'query_audios':
      case 'query_videos':
      case 'query_documents':
      case 'query_folders':
      case 'query_albums':
      case 'query_artists':
      case 'query_genres':
        return defaultTimeout;
      case 'query_artwork':
      case 'scan_media':
      case 'clear_cache':
        return longTimeout;
      default:
        return defaultTimeout;
    }
  }

  /// Create a timeout error with detailed information
  static MediaError createTimeoutError({
    required String operation,
    required Duration timeout,
    String? additionalInfo,
  }) {
    return MediaErrorFactory.platformError(
      platform: 'timeout',
      message:
          'Operation "$operation" timed out after ${timeout.inSeconds} seconds${additionalInfo != null ? ': $additionalInfo' : ''}',
      code: 'OPERATION_TIMEOUT',
    );
  }

  /// Check if an error is a timeout error
  static bool isTimeoutError(dynamic error) {
    if (error is MediaError) {
      return error.code == 'OPERATION_TIMEOUT' ||
          error.code == 'OPERATION_MAX_RETRIES_EXCEEDED';
    }
    return false;
  }

  /// Get timeout information from error
  static Map<String, dynamic>? getTimeoutInfo(dynamic error) {
    if (error is MediaError && error.details is Map<String, dynamic>) {
      final details = error.details as Map<String, dynamic>;
      if (details.containsKey('timeout') || details.containsKey('attempts')) {
        return details;
      }
    }
    return null;
  }
}
