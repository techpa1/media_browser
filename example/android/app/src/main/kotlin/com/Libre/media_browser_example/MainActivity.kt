package com.Libre.media_browser_example

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val PERMISSION_CHANNEL = "media_browser_permissions"
    private val PERMISSION_REQUEST_CODE = 1001

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        val permissionChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERMISSION_CHANNEL)
        permissionChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "checkPermissions" -> {
                    val mediaType = call.argument<String>("mediaType")
                    checkPermissions(mediaType, result)
                }
                "requestPermissions" -> {
                    val mediaType = call.argument<String>("mediaType")
                    requestPermissions(mediaType, result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun checkPermissions(mediaType: String?, result: MethodChannel.Result) {
        val permissions = getRequiredPermissions(mediaType)
        
        // If no permissions are required (e.g., documents/folders on Android 13+)
        if (permissions.isEmpty()) {
            result.success(mapOf(
                "status" to "granted",
                "message" to "No permissions required for this media type on this Android version",
                "missingPermissions" to emptyList<Map<String, Any>>()
            ))
            return
        }
        
        val missingPermissions = mutableListOf<Map<String, Any>>()
        var allGranted = true

        for (permission in permissions) {
            if (ContextCompat.checkSelfPermission(this, permission) != PackageManager.PERMISSION_GRANTED) {
                allGranted = false
                missingPermissions.add(mapOf(
                    "name" to permission,
                    "description" to getPermissionDescription(permission),
                    "isRequired" to isRequiredPermission(permission),
                    "type" to getPermissionType(permission)
                ))
            }
        }

        val status = if (allGranted) "granted" else "denied"
        val message = if (allGranted) {
            "All permissions granted"
        } else {
            "Some permissions are missing"
        }

        result.success(mapOf(
            "status" to status,
            "message" to message,
            "missingPermissions" to missingPermissions
        ))
    }

    private fun requestPermissions(mediaType: String?, result: MethodChannel.Result) {
        val permissions = getRequiredPermissions(mediaType)
        
        // If no permissions are required (e.g., documents/folders on Android 13+)
        if (permissions.isEmpty()) {
            result.success(mapOf(
                "status" to "granted",
                "message" to "No permissions required for this media type on this Android version",
                "missingPermissions" to emptyList<Map<String, Any>>()
            ))
            return
        }
        
        val permissionsToRequest = mutableListOf<String>()

        for (permission in permissions) {
            if (ContextCompat.checkSelfPermission(this, permission) != PackageManager.PERMISSION_GRANTED) {
                permissionsToRequest.add(permission)
            }
        }

        if (permissionsToRequest.isEmpty()) {
            // All permissions already granted
            result.success(mapOf(
                "status" to "granted",
                "message" to "All permissions already granted",
                "missingPermissions" to emptyList<Map<String, Any>>()
            ))
        } else {
            // Request permissions
            ActivityCompat.requestPermissions(this, permissionsToRequest.toTypedArray(), PERMISSION_REQUEST_CODE)
            
            // Check permissions again after request
            val stillMissing = mutableListOf<String>()
            for (permission in permissionsToRequest) {
                if (ContextCompat.checkSelfPermission(this, permission) != PackageManager.PERMISSION_GRANTED) {
                    stillMissing.add(permission)
                }
            }
            
            if (stillMissing.isEmpty()) {
                result.success(mapOf(
                    "status" to "granted",
                    "message" to "All permissions granted",
                    "missingPermissions" to emptyList<Map<String, Any>>()
                ))
            } else {
                result.success(mapOf(
                    "status" to "denied",
                    "message" to "Permission request sent to system",
                    "missingPermissions" to stillMissing.map { mapOf(
                        "name" to it,
                        "description" to getPermissionDescription(it),
                        "isRequired" to true,
                        "type" to getMediaTypeFromPermission(it)
                    ) }
                ))
            }
        }
    }

    private fun getRequiredPermissions(mediaType: String?): List<String> {
        val permissions = mutableListOf<String>()
        
        when (mediaType) {
            "audio", "MediaType.audio" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    permissions.add(Manifest.permission.READ_MEDIA_AUDIO)
                } else {
                    permissions.add(Manifest.permission.READ_EXTERNAL_STORAGE)
                }
            }
            "video", "MediaType.video" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    permissions.add(Manifest.permission.READ_MEDIA_VIDEO)
                } else {
                    permissions.add(Manifest.permission.READ_EXTERNAL_STORAGE)
                }
            }
            "document", "MediaType.document" -> {
                // Documents don't require special permissions on any Android version
                // They use file system access which is automatically granted
            }
            "folder", "MediaType.folder" -> {
                // Folders don't require special permissions on any Android version
                // They use file system access which is automatically granted
            }
            "all", "MediaType.all" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    permissions.add(Manifest.permission.READ_MEDIA_AUDIO)
                    permissions.add(Manifest.permission.READ_MEDIA_VIDEO)
                    permissions.add(Manifest.permission.READ_MEDIA_IMAGES)
                } else {
                    permissions.add(Manifest.permission.READ_EXTERNAL_STORAGE)
                }
            }
        }
        
        return permissions
    }

    private fun getPermissionDescription(permission: String): String {
        return when (permission) {
            Manifest.permission.READ_EXTERNAL_STORAGE -> "Access to external storage"
            Manifest.permission.READ_MEDIA_AUDIO -> "Access to audio files"
            Manifest.permission.READ_MEDIA_VIDEO -> "Access to video files"
            Manifest.permission.READ_MEDIA_IMAGES -> "Access to image files"
            else -> "Unknown permission"
        }
    }

    private fun getMediaTypeFromPermission(permission: String): String {
        return when (permission) {
            Manifest.permission.READ_MEDIA_AUDIO -> "audio"
            Manifest.permission.READ_MEDIA_VIDEO -> "video"
            Manifest.permission.READ_MEDIA_IMAGES -> "images"
            Manifest.permission.READ_EXTERNAL_STORAGE -> "all"
            else -> "unknown"
        }
    }

    private fun isRequiredPermission(permission: String): Boolean {
        return true // All permissions are required for media access
    }

    private fun getPermissionType(permission: String): String {
        return when (permission) {
            Manifest.permission.READ_MEDIA_AUDIO -> "audio"
            Manifest.permission.READ_MEDIA_VIDEO -> "video"
            Manifest.permission.READ_EXTERNAL_STORAGE -> "storage"
            Manifest.permission.READ_MEDIA_IMAGES -> "images"
            else -> "unknown"
        }
    }
}
