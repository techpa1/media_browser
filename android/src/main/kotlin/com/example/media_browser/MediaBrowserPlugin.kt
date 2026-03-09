package com.example.media_browser

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.content.ContextCompat
import androidx.core.app.ActivityCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.EventChannel
import kotlinx.coroutines.*
import java.util.concurrent.TimeUnit

class MediaBrowserPlugin: FlutterPlugin, MethodCallHandler, ActivityAware, EventChannel.StreamHandler {
    private lateinit var channel : MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var context: Context
    private lateinit var mediaQueryService: MediaQueryService
    private var activity: android.app.Activity? = null
    private var pendingPermissionResult: Result? = null
    
    // Permission monitoring
    private var eventSink: EventChannel.EventSink? = null
    private var permissionJob: Job? = null
    private val lastPermissionStates = mutableMapOf<String, Boolean>()
    
    // Timeout configurations
    private val defaultTimeout = 30L // 30 seconds
    private val shortTimeout = 10L // 10 seconds
    private val longTimeout = 60L // 60 seconds
    private val PERMISSION_REQUEST_CODE = 1001

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "media_browser")
        channel.setMethodCallHandler(this)
        
        // Set up event channel for permission change notifications
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "media_browser/permission_changes")
        eventChannel.setStreamHandler(this)
        
        context = flutterPluginBinding.applicationContext
        mediaQueryService = MediaQueryService(context)
        
        // Initialize permission tracking
        initializePermissionTracking()
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${Build.VERSION.RELEASE}")
            }
            "checkPermissions" -> {
                val mediaType = call.argument<String>("mediaType") ?: "all"
                checkPermissions(mediaType, result)
            }
            "requestPermissions" -> {
                val mediaType = call.argument<String>("mediaType") ?: "all"
                requestPermissions(mediaType, result)
            }
            "queryAudios" -> {
                val options = call.arguments as? Map<String, Any>
                queryAudios(options, result)
            }
            "queryAudiosFromAlbum" -> {
                val albumId = call.argument<Int>("albumId") ?: 0
                val options = call.arguments as? Map<String, Any>
                queryAudiosFromAlbum(albumId, options, result)
            }
            "queryAudiosFromArtist" -> {
                val artistId = call.argument<Int>("artistId") ?: 0
                val options = call.arguments as? Map<String, Any>
                queryAudiosFromArtist(artistId, options, result)
            }
            "queryAudiosFromGenre" -> {
                val genreId = call.argument<Int>("genreId") ?: 0
                val options = call.arguments as? Map<String, Any>
                queryAudiosFromGenre(genreId, options, result)
            }
            "queryAudiosFromPath" -> {
                val path = call.argument<String>("path") ?: ""
                val options = call.arguments as? Map<String, Any>
                queryAudiosFromPath(path, options, result)
            }
            "queryVideos" -> {
                val options = call.arguments as? Map<String, Any>
                queryVideos(options, result)
            }
            "queryVideosFromPath" -> {
                val path = call.argument<String>("path") ?: ""
                val options = call.arguments as? Map<String, Any>
                queryVideosFromPath(path, options, result)
            }
            "queryDocuments" -> {
                val options = call.arguments as? Map<String, Any>
                queryDocuments(options, result)
            }
            "queryDocumentsFromPath" -> {
                val path = call.argument<String>("path") ?: ""
                val options = call.arguments as? Map<String, Any>
                queryDocumentsFromPath(path, options, result)
            }
            "queryFolders" -> {
                val options = call.arguments as? Map<String, Any>
                queryFolders(options, result)
            }
            "queryFoldersFromPath" -> {
                val path = call.argument<String>("path") ?: ""
                val options = call.arguments as? Map<String, Any>
                val browsingMode = call.argument<String>("browsingMode") ?: "all"
                queryFoldersFromPath(path, options, browsingMode, result)
            }
            "scanDirectoryRecursively" -> {
                val path = call.argument<String>("path") ?: ""
                val fileType = call.argument<String>("fileType") ?: "all"
                scanDirectoryRecursively(path, fileType, result)
            }
            "scanCommonDirectories" -> {
                val fileType = call.argument<String>("fileType") ?: "all"
                scanCommonDirectories(fileType, result)
            }
            "getCommonDirectories" -> {
                getCommonDirectories(result)
            }
            "queryAlbums" -> {
                val options = call.arguments as? Map<String, Any>
                queryAlbums(options, result)
            }
            "queryArtists" -> {
                val options = call.arguments as? Map<String, Any>
                queryArtists(options, result)
            }
            "queryGenres" -> {
                val options = call.arguments as? Map<String, Any>
                queryGenres(options, result)
            }
            "queryArtwork" -> {
                val id = when (val idArg = call.argument<Any>("id")) {
                    is Long -> idArg.toInt()
                    is Int -> idArg
                    else -> 0
                }
                val type = call.argument<String>("type") ?: "audio"
                val size = call.argument<String>("size") ?: "medium"
                queryArtwork(id, type, size, result)
            }
            "clearCachedArtworks" -> {
                clearCachedArtworks(result)
            }
            "clearScanCache" -> {
                clearScanCache(result)
            }
            "scanMedia" -> {
                val path = call.argument<String>("path") ?: ""
                scanMedia(path, result)
            }
            "getDeviceInfo" -> {
                getDeviceInfo(result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun checkPermissions(mediaType: String, result: Result) {
        CoroutineScope(Dispatchers.Main).launch {
            try {
                withTimeout(shortTimeout * 1000L) {
                    val permissions = getRequiredPermissions(mediaType)
                    val missingPermissions = mutableListOf<Map<String, Any>>()
                    var allGranted = true

                    for (permission in permissions) {
                        val permissionState = getDetailedPermissionState(permission)
                        if (permissionState["status"] != "granted") {
                            allGranted = false
                            missingPermissions.add(mapOf(
                                "name" to permission,
                                "description" to getPermissionDescription(permission),
                                "isRequired" to isRequiredPermission(permission),
                                "type" to getPermissionType(permission),
                                "status" to (permissionState["status"] as? String ?: "unknown"),
                                "canRequest" to (permissionState["canRequest"] as? Boolean ?: false),
                                "shouldShowRationale" to (permissionState["shouldShowRationale"] as? Boolean ?: false)
                            ))
                        }
                    }

                    val status = if (allGranted) "granted" else "denied"
                    val message = if (allGranted) "All permissions granted" else "Missing required permissions"

                    result.success(mapOf(
                        "status" to status,
                        "message" to message,
                        "missingPermissions" to missingPermissions
                    ))
                }
            } catch (e: TimeoutCancellationException) {
                result.error("PERMISSION_CHECK_TIMEOUT", "Permission check timed out after ${shortTimeout} seconds", e)
            } catch (e: Exception) {
                result.error("PERMISSION_CHECK_FAILED", "Failed to check permissions: ${e.message}", e)
            }
        }
    }

    private fun requestPermissions(mediaType: String, result: Result) {
        CoroutineScope(Dispatchers.Main).launch {
            try {
                withTimeout(shortTimeout * 1000L) {
                    val permissions = getRequiredPermissions(mediaType)
                    val missingPermissions = mutableListOf<String>()
                    
                    // Check which permissions are missing
                    for (permission in permissions) {
                        if (ContextCompat.checkSelfPermission(context, permission) != PackageManager.PERMISSION_GRANTED) {
                            missingPermissions.add(permission)
                        }
                    }
                    
                    if (missingPermissions.isEmpty()) {
                        // All permissions already granted
                        result.success(mapOf(
                            "status" to "granted",
                            "message" to "All permissions already granted",
                            "missingPermissions" to emptyList<Map<String, Any>>()
                        ))
                        return@withTimeout
                    }
                    
                    // Store the result callback for later use
                    pendingPermissionResult = result
                    
                    // Request permissions
                    activity?.let { act ->
                        ActivityCompat.requestPermissions(act, missingPermissions.toTypedArray(), PERMISSION_REQUEST_CODE)
                    } ?: run {
                        result.error("NO_ACTIVITY", "No activity available to request permissions", null)
                    }
                }
            } catch (e: TimeoutCancellationException) {
                result.error("PERMISSION_REQUEST_TIMEOUT", "Permission request timed out after ${shortTimeout} seconds", e)
            } catch (e: Exception) {
                result.error("PERMISSION_REQUEST_FAILED", "Failed to request permissions: ${e.message}", e)
            }
        }
    }

    private fun queryAudios(options: Map<String, Any>?, result: Result) {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                withTimeout(defaultTimeout * 1000L) {
                    val audios = mediaQueryService.queryAudios(options)
                    withContext(Dispatchers.Main) {
                        result.success(audios)
                    }
                }
            } catch (e: TimeoutCancellationException) {
                withContext(Dispatchers.Main) {
                    result.error("QUERY_AUDIO_TIMEOUT", "Audio query timed out after ${defaultTimeout} seconds", e)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("QUERY_AUDIO_FAILED", "Failed to query audio files: ${e.message}", e)
                }
            }
        }
    }

    private fun queryAudiosFromAlbum(albumId: Int, options: Map<String, Any>?, result: Result) {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                withTimeout(defaultTimeout * 1000L) {
                    val audios = mediaQueryService.queryAudiosFromAlbum(albumId, options)
                    withContext(Dispatchers.Main) {
                        result.success(audios)
                    }
                }
            } catch (e: TimeoutCancellationException) {
                withContext(Dispatchers.Main) {
                    result.error("QUERY_AUDIO_TIMEOUT", "Audio query timed out after ${defaultTimeout} seconds", e)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("QUERY_AUDIO_FAILED", "Failed to query audio files from album: ${e.message}", e)
                }
            }
        }
    }

    private fun queryAudiosFromArtist(artistId: Int, options: Map<String, Any>?, result: Result) {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                withTimeout(defaultTimeout * 1000L) {
                    val audios = mediaQueryService.queryAudiosFromArtist(artistId, options)
                    withContext(Dispatchers.Main) {
                        result.success(audios)
                    }
                }
            } catch (e: TimeoutCancellationException) {
                withContext(Dispatchers.Main) {
                    result.error("QUERY_AUDIO_TIMEOUT", "Audio query timed out after ${defaultTimeout} seconds", e)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("QUERY_AUDIO_FAILED", "Failed to query audio files from artist: ${e.message}", e)
                }
            }
        }
    }

    private fun queryAudiosFromGenre(genreId: Int, options: Map<String, Any>?, result: Result) {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                withTimeout(defaultTimeout * 1000L) {
                    val audios = mediaQueryService.queryAudiosFromGenre(genreId, options)
                    withContext(Dispatchers.Main) {
                        result.success(audios)
                    }
                }
            } catch (e: TimeoutCancellationException) {
                withContext(Dispatchers.Main) {
                    result.error("QUERY_AUDIO_TIMEOUT", "Audio query timed out after ${defaultTimeout} seconds", e)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("QUERY_AUDIO_FAILED", "Failed to query audio files from genre: ${e.message}", e)
                }
            }
        }
    }

    private fun queryAudiosFromPath(path: String, options: Map<String, Any>?, result: Result) {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                withTimeout(defaultTimeout * 1000L) {
                    val audios = mediaQueryService.queryAudiosFromPath(path, options)
                    withContext(Dispatchers.Main) {
                        result.success(audios)
                    }
                }
            } catch (e: TimeoutCancellationException) {
                withContext(Dispatchers.Main) {
                    result.error("QUERY_AUDIO_TIMEOUT", "Audio query timed out after ${defaultTimeout} seconds", e)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("QUERY_AUDIO_FAILED", "Failed to query audio files from path: ${e.message}", e)
                }
            }
        }
    }

    private fun queryVideos(options: Map<String, Any>?, result: Result) {
        try {
            val videos = mediaQueryService.queryVideos(options)
            result.success(videos)
        } catch (e: Exception) {
            result.error("QUERY_VIDEO_FAILED", "Failed to query video files: ${e.message}", e)
        }
    }

    private fun queryVideosFromPath(path: String, options: Map<String, Any>?, result: Result) {
        try {
            val videos = mediaQueryService.queryVideosFromPath(path, options)
            result.success(videos)
        } catch (e: Exception) {
            result.error("QUERY_VIDEO_FAILED", "Failed to query video files from path: ${e.message}", e)
        }
    }

    private fun queryDocuments(options: Map<String, Any>?, result: Result) {
        try {
            val documents = mediaQueryService.queryDocuments(options)
            result.success(documents)
        } catch (e: Exception) {
            result.error("QUERY_DOCUMENT_FAILED", "Failed to query document files: ${e.message}", e)
        }
    }

    private fun queryDocumentsFromPath(path: String, options: Map<String, Any>?, result: Result) {
        try {
            val documents = mediaQueryService.queryDocumentsFromPath(path, options)
            result.success(documents)
        } catch (e: Exception) {
            result.error("QUERY_DOCUMENT_FAILED", "Failed to query document files from path: ${e.message}", e)
        }
    }

    private fun queryFolders(options: Map<String, Any>?, result: Result) {
        try {
            val folders = mediaQueryService.queryFolders(options)
            result.success(folders)
        } catch (e: Exception) {
            result.error("QUERY_FOLDER_FAILED", "Failed to query folders: ${e.message}", e)
        }
    }

    private fun queryFoldersFromPath(path: String, options: Map<String, Any>?, browsingMode: String, result: Result) {
        try {
            val folders = mediaQueryService.queryFoldersFromPath(path, options, browsingMode)
            result.success(folders)
        } catch (e: Exception) {
            result.error("QUERY_FOLDER_FAILED", "Failed to query folders from path: ${e.message}", e)
        }
    }

    private fun queryAlbums(options: Map<String, Any>?, result: Result) {
        try {
            val albums = mediaQueryService.queryAlbums(options)
            result.success(albums)
        } catch (e: Exception) {
            result.error("QUERY_ALBUM_FAILED", "Failed to query albums: ${e.message}", e)
        }
    }

    private fun queryArtists(options: Map<String, Any>?, result: Result) {
        try {
            val artists = mediaQueryService.queryArtists(options)
            result.success(artists)
        } catch (e: Exception) {
            result.error("QUERY_ARTIST_FAILED", "Failed to query artists: ${e.message}", e)
        }
    }

    private fun queryGenres(options: Map<String, Any>?, result: Result) {
        try {
            val genres = mediaQueryService.queryGenres(options)
            result.success(genres)
        } catch (e: Exception) {
            result.error("QUERY_GENRE_FAILED", "Failed to query genres: ${e.message}", e)
        }
    }

    private fun queryArtwork(id: Int, type: String, size: String, result: Result) {
        try {
            val artwork = mediaQueryService.queryArtwork(id, type, size)
            result.success(artwork)
        } catch (e: Exception) {
            result.error("QUERY_ARTWORK_FAILED", "Failed to query artwork: ${e.message ?: "Unknown error"}", e)
        }
    }

    private fun clearCachedArtworks(result: Result) {
        try {
            mediaQueryService.clearCachedArtworks()
            result.success(null)
        } catch (e: Exception) {
            result.error("CLEAR_CACHE_FAILED", "Failed to clear cached artworks: ${e.message ?: "Unknown error"}", e)
        }
    }

    private fun clearScanCache(result: Result) {
        try {
            mediaQueryService.clearScanCache()
            result.success(null)
        } catch (e: Exception) {
            result.error("CLEAR_SCAN_CACHE_FAILED", "Failed to clear scan cache: ${e.message ?: "Unknown error"}", e)
        }
    }

    private fun scanMedia(path: String, result: Result) {
        try {
            mediaQueryService.scanMedia(path)
            result.success(null)
        } catch (e: Exception) {
            result.error("SCAN_MEDIA_FAILED", "Failed to scan media: ${e.message}", e)
        }
    }

    private fun getDeviceInfo(result: Result) {
        try {
            val deviceInfo = mapOf(
                "platform" to "Android",
                "version" to Build.VERSION.RELEASE,
                "sdk" to Build.VERSION.SDK_INT,
                "model" to Build.MODEL,
                "manufacturer" to Build.MANUFACTURER,
                "brand" to Build.BRAND
            )
            result.success(deviceInfo)
        } catch (e: Exception) {
            result.error("DEVICE_INFO_FAILED", "Failed to get device info: ${e.message}", e)
        }
    }

    private fun getRequiredPermissions(mediaType: String): List<String> {
        val permissions = mutableListOf<String>()
        val isAndroid13OrHigher = Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU // API 33
        
        android.util.Log.d("MediaBrowserPlugin", "🔐 Getting permissions for mediaType: $mediaType, Android API: ${Build.VERSION.SDK_INT}, isAndroid13OrHigher: $isAndroid13OrHigher")
        
        when (mediaType) {
            "audio" -> {
                if (isAndroid13OrHigher) {
                    // Android 13+ uses granular media permissions
                    permissions.add(android.Manifest.permission.READ_MEDIA_AUDIO)
                } else {
                    // Android 12 and below use broad storage permission
                    permissions.add(android.Manifest.permission.READ_EXTERNAL_STORAGE)
                }
            }
            "video" -> {
                if (isAndroid13OrHigher) {
                    // Android 13+ uses granular media permissions
                    permissions.add(android.Manifest.permission.READ_MEDIA_VIDEO)
                } else {
                    // Android 12 and below use broad storage permission
                    permissions.add(android.Manifest.permission.READ_EXTERNAL_STORAGE)
                }
            }
            "document" -> {
                // Documents always use READ_EXTERNAL_STORAGE (no granular permission for documents)
                permissions.add(android.Manifest.permission.READ_EXTERNAL_STORAGE)
            }
            "folder" -> {
                // Folders always use READ_EXTERNAL_STORAGE (no granular permission for folders)
                permissions.add(android.Manifest.permission.READ_EXTERNAL_STORAGE)
            }
            "all" -> {
                if (isAndroid13OrHigher) {
                    // Android 13+ uses granular media permissions
                    permissions.addAll(listOf(
                        android.Manifest.permission.READ_MEDIA_AUDIO,
                        android.Manifest.permission.READ_MEDIA_VIDEO,
                        android.Manifest.permission.READ_MEDIA_IMAGES
                    ))
                    // Documents and folders still need READ_EXTERNAL_STORAGE
                    permissions.add(android.Manifest.permission.READ_EXTERNAL_STORAGE)
                } else {
                    // Android 12 and below use broad storage permission
                    permissions.add(android.Manifest.permission.READ_EXTERNAL_STORAGE)
                }
            }
        }
        
        android.util.Log.d("MediaBrowserPlugin", "🔐 Required permissions for $mediaType: $permissions")
        return permissions
    }

    private fun getPermissionDescription(permission: String): String {
        return when (permission) {
            android.Manifest.permission.READ_EXTERNAL_STORAGE -> "Read external storage"
            android.Manifest.permission.WRITE_EXTERNAL_STORAGE -> "Write external storage"
            android.Manifest.permission.READ_MEDIA_AUDIO -> "Read media audio files"
            android.Manifest.permission.READ_MEDIA_VIDEO -> "Read media video files"
            android.Manifest.permission.READ_MEDIA_IMAGES -> "Read media image files"
            else -> "Unknown permission"
        }
    }

    private fun isRequiredPermission(permission: String): Boolean {
        return when (permission) {
            // Core permissions that are always required
            android.Manifest.permission.READ_EXTERNAL_STORAGE,
            android.Manifest.permission.READ_MEDIA_AUDIO,
            android.Manifest.permission.READ_MEDIA_VIDEO -> true
            // Optional permissions (images are often not needed for basic functionality)
            android.Manifest.permission.READ_MEDIA_IMAGES -> false
            else -> false
        }
    }

    private fun getPermissionType(permission: String): String {
        return when (permission) {
            android.Manifest.permission.READ_EXTERNAL_STORAGE,
            android.Manifest.permission.WRITE_EXTERNAL_STORAGE -> "storage"
            android.Manifest.permission.READ_MEDIA_AUDIO -> "audio"
            android.Manifest.permission.READ_MEDIA_VIDEO -> "video"
            android.Manifest.permission.READ_MEDIA_IMAGES -> "media_library"
            else -> "storage"
        }
    }
    
    private fun getMediaTypeFromPermission(permission: String): String? {
        return when (permission) {
            android.Manifest.permission.READ_MEDIA_AUDIO -> "audio"
            android.Manifest.permission.READ_MEDIA_VIDEO -> "video"
            android.Manifest.permission.READ_MEDIA_IMAGES -> "image" // Images are separate from video
            android.Manifest.permission.READ_EXTERNAL_STORAGE -> "all" // Storage affects all media types
            else -> null
        }
    }
    
    private fun getDetailedPermissionState(permission: String): Map<String, Any> {
        val isGranted = ContextCompat.checkSelfPermission(context, permission) == PackageManager.PERMISSION_GRANTED
        
        if (isGranted) {
            return mapOf(
                "status" to "granted",
                "canRequest" to false,
                "shouldShowRationale" to false
            )
        }
        
        // Permission is not granted, check if we can request it
        val shouldShowRationale = ActivityCompat.shouldShowRequestPermissionRationale(activity ?: return mapOf(
            "status" to "denied",
            "canRequest" to false,
            "shouldShowRationale" to false
        ), permission)
        
        return if (shouldShowRationale) {
            // Permission denied but can be requested again
            mapOf(
                "status" to "denied",
                "canRequest" to true,
                "shouldShowRationale" to true
            )
        } else {
            // Permission permanently denied or never requested
            // Check if this is the first time by checking if we have a result for this permission
            val hasBeenRequested = lastPermissionStates.containsKey(permission)
            if (hasBeenRequested) {
                // Permission was requested before and denied permanently
                mapOf(
                    "status" to "permanently_denied",
                    "canRequest" to false,
                    "shouldShowRationale" to false
                )
            } else {
                // Permission never requested before
                mapOf(
                    "status" to "denied",
                    "canRequest" to true,
                    "shouldShowRationale" to false
                )
            }
        }
    }

    // New methods for enhanced file system scanning
    private fun scanDirectoryRecursively(path: String, fileType: String, result: Result) {
        try {
            val files = mediaQueryService.scanDirectoryRecursively(path, fileType)
            result.success(files)
        } catch (e: Exception) {
            result.error("SCAN_DIRECTORY_FAILED", "Failed to scan directory recursively: ${e.message}", e)
        }
    }
    
    private fun scanCommonDirectories(fileType: String, result: Result) {
        try {
            val files = mediaQueryService.scanCommonDirectories(fileType)
            result.success(files)
        } catch (e: Exception) {
            result.error("SCAN_COMMON_DIRECTORIES_FAILED", "Failed to scan common directories: ${e.message}", e)
        }
    }
    
    private fun getCommonDirectories(result: Result) {
        try {
            val directories = mediaQueryService.getCommonDirectories()
            result.success(directories)
        } catch (e: Exception) {
            result.error("GET_COMMON_DIRECTORIES_FAILED", "Failed to get common directories: ${e.message}", e)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
    
    // ActivityAware methods
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }
    
    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }
    
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }
    
    override fun onDetachedFromActivity() {
        activity = null
    }
    
    // Handle permission request results
    fun onRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray) {
        if (requestCode == PERMISSION_REQUEST_CODE) {
            pendingPermissionResult?.let { result ->
                val missingPermissions = mutableListOf<Map<String, Any>>()
                var allGranted = true
                
                for (i in permissions.indices) {
                    if (grantResults[i] != PackageManager.PERMISSION_GRANTED) {
                        allGranted = false
                        missingPermissions.add(mapOf(
                            "name" to permissions[i],
                            "description" to getPermissionDescription(permissions[i]),
                            "isRequired" to isRequiredPermission(permissions[i]),
                            "type" to getPermissionType(permissions[i])
                        ))
                    }
                }
                
                val status = if (allGranted) "granted" else "denied"
                val message = if (allGranted) "All permissions granted" else "Some permissions denied"
                
                result.success(mapOf(
                    "status" to status,
                    "message" to message,
                    "missingPermissions" to missingPermissions
                ))
                
                pendingPermissionResult = null
            }
        }
    }
    
    // MARK: - Permission Monitoring
    
    private fun initializePermissionTracking() {
        // Initialize with current permission statuses
        val allPermissions = listOf(
            android.Manifest.permission.READ_EXTERNAL_STORAGE,
            android.Manifest.permission.READ_MEDIA_AUDIO,
            android.Manifest.permission.READ_MEDIA_VIDEO,
            android.Manifest.permission.READ_MEDIA_IMAGES
        )
        
        for (permission in allPermissions) {
            val isGranted = ContextCompat.checkSelfPermission(context, permission) == PackageManager.PERMISSION_GRANTED
            lastPermissionStates[permission] = isGranted
        }
        
        android.util.Log.d("MediaBrowserPlugin", "🔐 Android: Initialized permission tracking - $lastPermissionStates")
    }
    
    private fun startPermissionMonitoring() {
        stopPermissionMonitoring() // Stop any existing monitoring
        
        permissionJob = CoroutineScope(Dispatchers.Main).launch {
            while (isActive) {
                try {
                    checkPermissionChanges()
                } catch (e: Exception) {
                    android.util.Log.e("MediaBrowserPlugin", "🔐 Android: Error checking permission changes: ${e.message}")
                }
                delay(5000) // Check every 5 seconds to reduce battery impact
            }
        }
        
        android.util.Log.d("MediaBrowserPlugin", "🔐 Android: Started permission monitoring")
    }
    
    private fun stopPermissionMonitoring() {
        permissionJob?.cancel()
        permissionJob = null
        android.util.Log.d("MediaBrowserPlugin", "🔐 Android: Stopped permission monitoring")
    }
    
    private fun checkPermissionChanges() {
        val allPermissions = listOf(
            android.Manifest.permission.READ_EXTERNAL_STORAGE,
            android.Manifest.permission.READ_MEDIA_AUDIO,
            android.Manifest.permission.READ_MEDIA_VIDEO,
            android.Manifest.permission.READ_MEDIA_IMAGES
        )
        
        var hasChanges = false
        val changes = mutableMapOf<String, Any>()
        
        for (permission in allPermissions) {
            val currentState = ContextCompat.checkSelfPermission(context, permission) == PackageManager.PERMISSION_GRANTED
            val lastState = lastPermissionStates[permission] ?: false
            
            if (currentState != lastState) {
                hasChanges = true
                val permissionType = getPermissionType(permission)
                changes[permissionType] = mapOf(
                    "permission" to permission,
                    "previous" to lastState,
                    "current" to currentState,
                    "granted" to currentState,
                    "denied" to !currentState
                )
                
                android.util.Log.d("MediaBrowserPlugin", "🔐 Android: $permissionType permission changed from $lastState to $currentState")
                lastPermissionStates[permission] = currentState
            }
        }
        
        // Send notification if there are changes
        if (hasChanges) {
            // Determine affected media types
            val affectedMediaTypes = mutableListOf<String>()
            
            for (change in changes.values) {
                val changeMap = change as Map<String, Any>
                val permission = changeMap["permission"] as String
                val mediaType = getMediaTypeFromPermission(permission)
                if (mediaType != null && !affectedMediaTypes.contains(mediaType)) {
                    affectedMediaTypes.add(mediaType)
                }
            }
            
            val event = mapOf(
                "type" to "permission_changed",
                "timestamp" to System.currentTimeMillis(),
                "changes" to changes,
                "affectedMediaTypes" to affectedMediaTypes
            )
            
            sendPermissionChangeEvent(event)
        }
    }
    
    private fun sendPermissionChangeEvent(event: Map<String, Any>) {
        eventSink?.let { sink ->
            CoroutineScope(Dispatchers.Main).launch {
                sink.success(event)
                android.util.Log.d("MediaBrowserPlugin", "🔐 Android: Sent permission change event: $event")
            }
        } ?: run {
            android.util.Log.d("MediaBrowserPlugin", "🔐 Android: No event sink available to send permission change")
        }
    }
    
    // MARK: - EventChannel.StreamHandler
    
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        android.util.Log.d("MediaBrowserPlugin", "🔐 Android: Permission change listener started")
        eventSink = events
        startPermissionMonitoring()
    }
    
    override fun onCancel(arguments: Any?) {
        android.util.Log.d("MediaBrowserPlugin", "🔐 Android: Permission change listener cancelled")
        eventSink = null
        stopPermissionMonitoring()
    }
}
