package com.example.media_browser

import android.content.ContentResolver
import android.content.Context
import android.database.Cursor
import android.net.Uri
import android.provider.MediaStore
import java.io.File
import java.io.FileInputStream

class MediaQueryService(private val context: Context) {
    private val contentResolver: ContentResolver = context.contentResolver

    // Cache for file system scan results to avoid multiple scans
    private var cachedScanResults: Map<String, List<Map<String, Any>>>? = null
    private var lastScanTime: Long = 0
    private val scanCacheTimeout = 5 * 60 * 1000L // 5 minutes cache timeout


    private fun createArtworkMap(
        id: Any,
        filePath: String,
        format: String,
        size: String,
        isAvailable: Boolean,
        error: String
    ): Map<String, Any> {
        val result = mutableMapOf<String, Any>()
        result["id"] = id
        
        // For album/artist/genre artwork, copy to app's external files directory and return that path
        // For track/video artwork, return original file path
        if (isAvailable && filePath.isNotEmpty()) {
            try {
                val sourceFile = java.io.File(filePath)
                if (sourceFile.exists()) {
                    // Try to copy to external files directory (more accessible)
                    val externalFilesDir = context.getExternalFilesDir(null)
                    if (externalFilesDir != null) {
                        val artworkDir = java.io.File(externalFilesDir, "artwork")
                        if (!artworkDir.exists()) {
                            artworkDir.mkdirs()
                        }
                        
                        val tempFile = java.io.File(artworkDir, "artwork_${id}_${System.currentTimeMillis()}.${getFileExtension(sourceFile.name)}")
                        
                        // Copy the file to external files directory
                        sourceFile.copyTo(tempFile, overwrite = true)
                        
                        // Return the external file path
                        result["data"] = tempFile.absolutePath
                        android.util.Log.d("MediaQueryService", "🎨 Copied artwork to external files: ${sourceFile.absolutePath} -> ${tempFile.absolutePath}")
                    } else {
                        // Fallback to cache directory
                        val cacheDir = context.cacheDir
                        val tempFile = java.io.File(cacheDir, "artwork_${id}_${System.currentTimeMillis()}.${getFileExtension(sourceFile.name)}")
                        
                        // Copy the file to cache directory
                        sourceFile.copyTo(tempFile, overwrite = true)
                        
                        // Return the cache file path
                        result["data"] = tempFile.absolutePath
                        android.util.Log.d("MediaQueryService", "🎨 Copied artwork to cache: ${sourceFile.absolutePath} -> ${tempFile.absolutePath}")
                    }
                } else {
                    result["data"] = filePath  // Fallback to file path
                    android.util.Log.w("MediaQueryService", "🎨 Artwork file does not exist: $filePath")
                }
            } catch (e: Exception) {
                result["data"] = filePath  // Fallback to file path
                android.util.Log.w("MediaQueryService", "🎨 Error copying artwork file, using file path: ${e.message}")
            }
        } else {
            result["data"] = filePath
        }
        
        result["format"] = format
        result["size"] = size
        result["is_available"] = isAvailable
        result["error"] = error
        
        return result
    }

    /**
     * Get cached scan results or perform a new scan if cache is expired
     */
    private fun getCachedScanResults(): Map<String, List<Map<String, Any>>> {
        val currentTime = System.currentTimeMillis()
        
        if (cachedScanResults == null || (currentTime - lastScanTime) > scanCacheTimeout) {
            android.util.Log.d("MediaQueryService", "Performing new file system scan...")
            cachedScanResults = scanCommonDirectoriesOptimized()
            lastScanTime = currentTime
            android.util.Log.d("MediaQueryService", "File system scan completed and cached")
        } else {
            android.util.Log.d("MediaQueryService", "Using cached file system scan results")
        }
        
        return cachedScanResults ?: emptyMap()
    }

    /**
     * Clear the scan cache (call this when user refreshes)
     */
    fun clearScanCache() {
        cachedScanResults = null
        lastScanTime = 0
        android.util.Log.d("MediaQueryService", "File system scan cache cleared")
    }

    /**
     * Smart decision on whether to perform file system scanning
     * Based on MediaStore results and user preferences
     */
    private fun shouldPerformFileSystemScan(mediaStoreCount: Int, mediaType: String): Boolean {
        // If MediaStore has good results, skip file system scan
        val threshold = when (mediaType) {
            "audio" -> 50  // If MediaStore has 50+ audio files, likely comprehensive
            "video" -> 20  // If MediaStore has 20+ video files, likely comprehensive
            "document" -> 100 // If MediaStore has 100+ documents, likely comprehensive
            "folder" -> 10 // If MediaStore has 10+ folders, likely comprehensive
            else -> 50
        }
        
        val shouldScan = mediaStoreCount < threshold
        android.util.Log.d("MediaQueryService", "Smart scan decision for $mediaType: MediaStore=$mediaStoreCount, threshold=$threshold, shouldScan=$shouldScan")
        return shouldScan
    }

    fun queryAudios(options: Map<String, Any>?): List<Map<String, Any>> {
        val audios = mutableListOf<Map<String, Any>>()
        
        // Debug logging
        android.util.Log.d("MediaQueryService", "Starting optimized audio query (MediaStore-first approach)...")
        android.util.Log.d("MediaQueryService", "Context: $context")
        android.util.Log.d("MediaQueryService", "ContentResolver: $contentResolver")
        
        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.GENRE,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.DATA,
            MediaStore.Audio.Media.SIZE,
            MediaStore.Audio.Media.DATE_ADDED,
            MediaStore.Audio.Media.DATE_MODIFIED,
            MediaStore.Audio.Media.TRACK,
            MediaStore.Audio.Media.YEAR,
            MediaStore.Audio.Media.ALBUM_ARTIST,
            MediaStore.Audio.Media.COMPOSER,
            MediaStore.Audio.Media.MIME_TYPE,
            MediaStore.Audio.Media.IS_MUSIC,
            MediaStore.Audio.Media.IS_RINGTONE,
            MediaStore.Audio.Media.IS_ALARM,
            MediaStore.Audio.Media.IS_NOTIFICATION,
            MediaStore.Audio.Media.IS_PODCAST,
            MediaStore.Audio.Media.IS_AUDIOBOOK
        )

        val selection = buildAudioSelection(options)
        val selectionArgs = buildAudioSelectionArgs(options)
        val sortOrder = buildSortOrder(options, "audio")

        android.util.Log.d("MediaQueryService", "Querying MediaStore with URI: ${MediaStore.Audio.Media.EXTERNAL_CONTENT_URI}")
        android.util.Log.d("MediaQueryService", "Selection: $selection")
        android.util.Log.d("MediaQueryService", "SelectionArgs: ${selectionArgs?.contentToString()}")
        android.util.Log.d("MediaQueryService", "SortOrder: $sortOrder")
        android.util.Log.d("MediaQueryService", "Android API Level: ${android.os.Build.VERSION.SDK_INT}")

        val cursor: Cursor? = contentResolver.query(
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
            projection,
            selection,
            selectionArgs,
            sortOrder
        )

        if (cursor == null) {
            android.util.Log.e("MediaQueryService", "Cursor is null - query failed")
        } else {
            cursor.use {
            android.util.Log.d("MediaQueryService", "Found ${it.count} audio files")
            while (it.moveToNext()) {
                val audio = mapOf(
                    "id" to it.getLong(it.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)),
                    "title" to (it.getString(it.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)) ?: ""),
                    "artist" to (it.getString(it.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)) ?: ""),
                    "album" to (it.getString(it.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM)) ?: ""),
                    "genre" to (it.getString(it.getColumnIndexOrThrow(MediaStore.Audio.Media.GENRE)) ?: ""),
                    "duration" to it.getLong(it.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)),
                    "data" to (it.getString(it.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)) ?: ""),
                    "size" to it.getLong(it.getColumnIndexOrThrow(MediaStore.Audio.Media.SIZE)),
                    "date_added" to it.getLong(it.getColumnIndexOrThrow(MediaStore.Audio.Media.DATE_ADDED)),
                    "date_modified" to it.getLong(it.getColumnIndexOrThrow(MediaStore.Audio.Media.DATE_MODIFIED)),
                    "track" to it.getInt(it.getColumnIndexOrThrow(MediaStore.Audio.Media.TRACK)),
                    "year" to it.getInt(it.getColumnIndexOrThrow(MediaStore.Audio.Media.YEAR)),
                    "album_artist" to (it.getString(it.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM_ARTIST)) ?: ""),
                    "composer" to (it.getString(it.getColumnIndexOrThrow(MediaStore.Audio.Media.COMPOSER)) ?: ""),
                    "file_extension" to getFileExtension(it.getString(it.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)) ?: ""),
                    "display_name" to getDisplayName(it.getString(it.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)) ?: ""),
                    "mime_type" to (it.getString(it.getColumnIndexOrThrow(MediaStore.Audio.Media.MIME_TYPE)) ?: ""),
                    "is_music" to (it.getInt(it.getColumnIndexOrThrow(MediaStore.Audio.Media.IS_MUSIC)) == 1),
                    "is_ringtone" to (it.getInt(it.getColumnIndexOrThrow(MediaStore.Audio.Media.IS_RINGTONE)) == 1),
                    "is_alarm" to (it.getInt(it.getColumnIndexOrThrow(MediaStore.Audio.Media.IS_ALARM)) == 1),
                    "is_notification" to (it.getInt(it.getColumnIndexOrThrow(MediaStore.Audio.Media.IS_NOTIFICATION)) == 1),
                    "is_podcast" to (it.getInt(it.getColumnIndexOrThrow(MediaStore.Audio.Media.IS_PODCAST)) == 1),
                    "is_audiobook" to (it.getInt(it.getColumnIndexOrThrow(MediaStore.Audio.Media.IS_AUDIOBOOK)) == 1)
                )
                audios.add(audio)
                }
            }
        }

        // Smart file system scanning: only if MediaStore results are insufficient
        val mediaStoreCount = audios.size
        val shouldScanFileSystem = shouldPerformFileSystemScan(mediaStoreCount, "audio")
        
        if (shouldScanFileSystem) {
            android.util.Log.d("MediaQueryService", "MediaStore found ${audios.size} audio files, performing smart file system scan...")
            
            try {
                val scanResults = getCachedScanResults()
                val scannedFiles = scanResults["audio"] ?: emptyList()
                android.util.Log.d("MediaQueryService", "File system scan found ${scannedFiles.size} audio files")
                
                // Combine results, avoiding duplicates
                val seenPaths = mutableSetOf<String>()
                
                // Add existing MediaStore results
                for (audio in audios) {
                    val path = audio["data"] as? String
                    if (path != null && path.isNotEmpty()) {
                        seenPaths.add(path)
                    }
                }
                
                // Add scanned files that aren't already in MediaStore
                for (scannedFile in scannedFiles) {
                    val path = scannedFile["data"] as? String
                    if (path != null && path.isNotEmpty() && !seenPaths.contains(path)) {
                        seenPaths.add(path)
                        audios.add(scannedFile)
                    }
                }
                
                android.util.Log.d("MediaQueryService", "Combined total: ${audios.size} audio files (${audios.size - mediaStoreCount} from file system)")
            } catch (e: Exception) {
                android.util.Log.e("MediaQueryService", "Error during file system scan: ${e.message}")
            }
        } else {
            android.util.Log.d("MediaQueryService", "Skipping file system scan - MediaStore results sufficient (${audios.size} files)")
        }

        android.util.Log.d("MediaQueryService", "Returning ${audios.size} audio files")
        return audios
    }

    fun queryVideos(options: Map<String, Any>?): List<Map<String, Any>> {
        val videos = mutableListOf<Map<String, Any>>()
        
        val projection = arrayOf(
            MediaStore.Video.Media._ID,
            MediaStore.Video.Media.TITLE,
            MediaStore.Video.Media.ARTIST,
            MediaStore.Video.Media.ALBUM,
            MediaStore.Video.Media.DURATION,
            MediaStore.Video.Media.DATA,
            MediaStore.Video.Media.SIZE,
            MediaStore.Video.Media.DATE_ADDED,
            MediaStore.Video.Media.DATE_MODIFIED,
            MediaStore.Video.Media.WIDTH,
            MediaStore.Video.Media.HEIGHT,
            MediaStore.Video.Media.YEAR,
            MediaStore.Video.Media.MIME_TYPE
        )

        val selection = buildVideoSelection(options)
        val selectionArgs = buildVideoSelectionArgs(options)
        val sortOrder = buildSortOrder(options, "video")

        val cursor: Cursor? = contentResolver.query(
            MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
            projection,
            selection,
            selectionArgs,
            sortOrder
        )

        cursor?.use {
            while (it.moveToNext()) {
                val video = mapOf(
                    "id" to it.getLong(it.getColumnIndexOrThrow(MediaStore.Video.Media._ID)),
                    "title" to (it.getString(it.getColumnIndexOrThrow(MediaStore.Video.Media.TITLE)) ?: ""),
                    "artist" to (it.getString(it.getColumnIndexOrThrow(MediaStore.Video.Media.ARTIST)) ?: ""),
                    "album" to (it.getString(it.getColumnIndexOrThrow(MediaStore.Video.Media.ALBUM)) ?: ""),
                    "genre" to "",
                    "duration" to it.getLong(it.getColumnIndexOrThrow(MediaStore.Video.Media.DURATION)),
                    "data" to (it.getString(it.getColumnIndexOrThrow(MediaStore.Video.Media.DATA)) ?: ""),
                    "size" to it.getLong(it.getColumnIndexOrThrow(MediaStore.Video.Media.SIZE)),
                    "date_added" to it.getLong(it.getColumnIndexOrThrow(MediaStore.Video.Media.DATE_ADDED)),
                    "date_modified" to it.getLong(it.getColumnIndexOrThrow(MediaStore.Video.Media.DATE_MODIFIED)),
                    "width" to it.getInt(it.getColumnIndexOrThrow(MediaStore.Video.Media.WIDTH)),
                    "height" to it.getInt(it.getColumnIndexOrThrow(MediaStore.Video.Media.HEIGHT)),
                    "year" to it.getInt(it.getColumnIndexOrThrow(MediaStore.Video.Media.YEAR)),
                    "file_extension" to getFileExtension(it.getString(it.getColumnIndexOrThrow(MediaStore.Video.Media.DATA)) ?: ""),
                    "display_name" to getDisplayName(it.getString(it.getColumnIndexOrThrow(MediaStore.Video.Media.DATA)) ?: ""),
                    "mime_type" to (it.getString(it.getColumnIndexOrThrow(MediaStore.Video.Media.MIME_TYPE)) ?: ""),
                    "codec" to "",
                    "bitrate" to 0,
                    "frame_rate" to 0.0,
                    "is_movie" to true,
                    "is_tv_show" to false,
                    "is_music_video" to false,
                    "is_trailer" to false
                )
                videos.add(video)
            }
        }

        // Now add file system scan results to get files not in MediaStore
        android.util.Log.d("MediaQueryService", "MediaStore found ${videos.size} video files, now adding file system scan results...")
        
        try {
            val scanResults = getCachedScanResults()
            val scannedFiles = scanResults["video"] ?: emptyList()
            android.util.Log.d("MediaQueryService", "File system scan found ${scannedFiles.size} video files")
            
            // Combine results, avoiding duplicates
            val seenPaths = mutableSetOf<String>()
            
            // Add existing MediaStore results
            for (video in videos) {
                val path = video["data"] as? String
                if (path != null && path.isNotEmpty()) {
                    seenPaths.add(path)
                }
            }
            
            // Add scanned files that aren't already in MediaStore
            for (scannedFile in scannedFiles) {
                val path = scannedFile["data"] as? String
                if (path != null && path.isNotEmpty() && !seenPaths.contains(path)) {
                    seenPaths.add(path)
                    videos.add(scannedFile)
                }
            }
            
            android.util.Log.d("MediaQueryService", "Combined total: ${videos.size} video files")
        } catch (e: Exception) {
            android.util.Log.e("MediaQueryService", "Error during file system scan: ${e.message}")
        }

        return videos
    }

    fun queryDocuments(options: Map<String, Any>?): List<Map<String, Any>> {
        val documents = mutableListOf<Map<String, Any>>()
        
        val projection = arrayOf(
            MediaStore.Files.FileColumns._ID,
            MediaStore.Files.FileColumns.DISPLAY_NAME,
            MediaStore.Files.FileColumns.DATA,
            MediaStore.Files.FileColumns.SIZE,
            MediaStore.Files.FileColumns.DATE_ADDED,
            MediaStore.Files.FileColumns.DATE_MODIFIED,
            MediaStore.Files.FileColumns.MIME_TYPE
        )

        val selection = buildDocumentSelection(options)
        val selectionArgs = buildDocumentSelectionArgs(options)
        val sortOrder = buildSortOrder(options, "document")

        val cursor: Cursor? = contentResolver.query(
            MediaStore.Files.getContentUri("external"),
            projection,
            selection,
            selectionArgs,
            sortOrder
        )

        cursor?.use {
            while (it.moveToNext()) {
                val data = it.getString(it.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DATA)) ?: ""
                val mimeType = it.getString(it.getColumnIndexOrThrow(MediaStore.Files.FileColumns.MIME_TYPE)) ?: ""
                
                val document = mapOf(
                    "id" to it.getLong(it.getColumnIndexOrThrow(MediaStore.Files.FileColumns._ID)),
                    "title" to (it.getString(it.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DISPLAY_NAME)) ?: ""),
                    "data" to data,
                    "size" to it.getLong(it.getColumnIndexOrThrow(MediaStore.Files.FileColumns.SIZE)),
                    "date_added" to it.getLong(it.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DATE_ADDED)),
                    "date_modified" to it.getLong(it.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DATE_MODIFIED)),
                    "file_extension" to getFileExtension(data),
                    "display_name" to getDisplayName(data),
                    "mime_type" to mimeType,
                    "document_type" to getDocumentType(mimeType),
                    "author" to "",
                    "subject" to "",
                    "keywords" to "",
                    "page_count" to 0,
                    "word_count" to 0,
                    "language" to "",
                    "is_encrypted" to false,
                    "is_compressed" to false
                )
                documents.add(document)
            }
        }

        // Now add file system scan results to get files not in MediaStore
        android.util.Log.d("MediaQueryService", "MediaStore found ${documents.size} document files, now adding file system scan results...")
        
        try {
            val scanResults = getCachedScanResults()
            val scannedFiles = scanResults["document"] ?: emptyList()
            android.util.Log.d("MediaQueryService", "File system scan found ${scannedFiles.size} document files")
            
            // Combine results, avoiding duplicates
            val seenPaths = mutableSetOf<String>()
            
            // Add existing MediaStore results
            for (document in documents) {
                val path = document["data"] as? String
                if (path != null && path.isNotEmpty()) {
                    seenPaths.add(path)
                }
            }
            
            // Add scanned files that aren't already in MediaStore
            for (scannedFile in scannedFiles) {
                val path = scannedFile["data"] as? String
                if (path != null && path.isNotEmpty() && !seenPaths.contains(path)) {
                    seenPaths.add(path)
                    documents.add(scannedFile)
                }
            }
            
            android.util.Log.d("MediaQueryService", "Combined total: ${documents.size} document files")
        } catch (e: Exception) {
            android.util.Log.e("MediaQueryService", "Error during file system scan: ${e.message}")
        }

        return documents
    }

    fun queryFolders(options: Map<String, Any>?): List<Map<String, Any>> {
        val folders = mutableListOf<Map<String, Any>>()
        
        // For simplicity, we'll query common media directories
        val commonPaths = listOf(
            "/storage/emulated/0/Music",
            "/storage/emulated/0/Movies",
            "/storage/emulated/0/Documents",
            "/storage/emulated/0/Download",
            "/storage/emulated/0/Pictures"
        )

        for (path in commonPaths) {
            val folder = File(path)
            if (folder.exists() && folder.isDirectory) {
                val folderInfo = mapOf(
                    "id" to folder.hashCode().toLong(),
                    "name" to folder.name,
                    "path" to folder.absolutePath,
                    "parent_path" to (folder.parent ?: ""),
                    "date_created" to folder.lastModified(),
                    "date_modified" to folder.lastModified(),
                    "date_accessed" to folder.lastModified(),
                    "total_size" to getFolderSize(folder),
                    "file_count" to getFileCount(folder),
                    "directory_count" to getDirectoryCount(folder),
                    "is_hidden" to folder.isHidden,
                    "is_read_only" to !folder.canWrite(),
                    "is_system" to false,
                    "folder_type" to getFolderType(path),
                    "storage_location" to "internal"
                )
                folders.add(folderInfo)
            }
        }

        // Now add file system scan results to get folders not in MediaStore
        android.util.Log.d("MediaQueryService", "MediaStore found ${folders.size} folders, now adding file system scan results...")
        
        try {
            val scanResults = getCachedScanResults()
            val scannedFiles = scanResults["folder"] ?: emptyList()
            android.util.Log.d("MediaQueryService", "File system scan found ${scannedFiles.size} folders")
            
            // Filter for folders only and combine results, avoiding duplicates
            val seenPaths = mutableSetOf<String>()
            
            // Add existing MediaStore results
            for (folder in folders) {
                val path = folder["path"] as? String
                if (path != null && path.isNotEmpty()) {
                    seenPaths.add(path)
                }
            }
            
            // Add scanned folders that aren't already in MediaStore
            for (scannedFile in scannedFiles) {
                val path = scannedFile["path"] as? String
                val isDirectory = scannedFile["isDirectory"] as? Boolean ?: false
                val type = scannedFile["type"] as? String
                
                if (path != null && path.isNotEmpty() && 
                    (isDirectory || type == "folder") && 
                    !seenPaths.contains(path)) {
                    seenPaths.add(path)
                    folders.add(scannedFile)
                }
            }
            
            android.util.Log.d("MediaQueryService", "Combined total: ${folders.size} folders")
        } catch (e: Exception) {
            android.util.Log.e("MediaQueryService", "Error during file system scan: ${e.message}")
        }

        return folders
    }

    fun queryAlbums(options: Map<String, Any>?): List<Map<String, Any>> {
        val albums = mutableListOf<Map<String, Any>>()
        
        val projection = arrayOf(
            MediaStore.Audio.Albums._ID,
            MediaStore.Audio.Albums.ALBUM,
            MediaStore.Audio.Albums.ARTIST,
            MediaStore.Audio.Albums.NUMBER_OF_SONGS,
            MediaStore.Audio.Albums.FIRST_YEAR,
            MediaStore.Audio.Albums.LAST_YEAR
        )

        val sortOrder = buildSortOrder(options, "album")

        val cursor: Cursor? = contentResolver.query(
            MediaStore.Audio.Albums.EXTERNAL_CONTENT_URI,
            projection,
            null,
            null,
            sortOrder
        )

        cursor?.use {
            while (it.moveToNext()) {
                val album = mapOf(
                    "id" to it.getLong(it.getColumnIndexOrThrow(MediaStore.Audio.Albums._ID)),
                    "album" to (it.getString(it.getColumnIndexOrThrow(MediaStore.Audio.Albums.ALBUM)) ?: ""),
                    "artist" to (it.getString(it.getColumnIndexOrThrow(MediaStore.Audio.Albums.ARTIST)) ?: ""),
                    "num_of_songs" to it.getInt(it.getColumnIndexOrThrow(MediaStore.Audio.Albums.NUMBER_OF_SONGS)),
                    "year" to it.getInt(it.getColumnIndexOrThrow(MediaStore.Audio.Albums.FIRST_YEAR))
                )
                albums.add(album)
            }
        }

        return albums
    }

    fun queryArtists(options: Map<String, Any>?): List<Map<String, Any>> {
        val artists = mutableListOf<Map<String, Any>>()
        
        val projection = arrayOf(
            MediaStore.Audio.Artists._ID,
            MediaStore.Audio.Artists.ARTIST,
            MediaStore.Audio.Artists.NUMBER_OF_ALBUMS,
            MediaStore.Audio.Artists.NUMBER_OF_TRACKS
        )

        val sortOrder = buildSortOrder(options, "artist")

        val cursor: Cursor? = contentResolver.query(
            MediaStore.Audio.Artists.EXTERNAL_CONTENT_URI,
            projection,
            null,
            null,
            sortOrder
        )

        cursor?.use {
            while (it.moveToNext()) {
                val artist = mapOf(
                    "id" to it.getLong(it.getColumnIndexOrThrow(MediaStore.Audio.Artists._ID)),
                    "artist" to (it.getString(it.getColumnIndexOrThrow(MediaStore.Audio.Artists.ARTIST)) ?: ""),
                    "num_of_albums" to it.getInt(it.getColumnIndexOrThrow(MediaStore.Audio.Artists.NUMBER_OF_ALBUMS)),
                    "num_of_songs" to it.getInt(it.getColumnIndexOrThrow(MediaStore.Audio.Artists.NUMBER_OF_TRACKS))
                )
                artists.add(artist)
            }
        }

        return artists
    }

    fun queryGenres(options: Map<String, Any>?): List<Map<String, Any>> {
        val genres = mutableListOf<Map<String, Any>>()
        
        val projection = arrayOf(
            MediaStore.Audio.Genres._ID,
            MediaStore.Audio.Genres.NAME
        )

        val sortOrder = buildSortOrder(options, "genre")

        val cursor: Cursor? = contentResolver.query(
            MediaStore.Audio.Genres.EXTERNAL_CONTENT_URI,
            projection,
            null,
            null,
            sortOrder
        )

        cursor?.use {
            while (it.moveToNext()) {
                val genre = mapOf(
                    "id" to it.getLong(it.getColumnIndexOrThrow(MediaStore.Audio.Genres._ID)),
                    "genre" to (it.getString(it.getColumnIndexOrThrow(MediaStore.Audio.Genres.NAME)) ?: ""),
                    "num_of_songs" to 0 // Would need additional query to get this
                )
                genres.add(genre)
            }
        }

        return genres
    }

    fun queryArtwork(id: Int, type: String, size: String): Map<String, Any> {
        try {
            android.util.Log.d("MediaQueryService", "🎨 Querying artwork for id=$id, type=$type, size=$size")
            val result = when (type) {
                "audio" -> {
                    android.util.Log.d("MediaQueryService", "🎨 Routing to queryAudioArtwork for id: $id")
                    queryAudioArtwork(id, size)
                }
                "album" -> {
                    android.util.Log.d("MediaQueryService", "🎨 Routing to queryAlbumArtwork for id: $id")
                    queryAlbumArtwork(id.toLong(), size)
                }
                "artist" -> {
                    android.util.Log.d("MediaQueryService", "🎨 Routing to queryArtistArtwork for id: $id")
                    queryArtistArtwork(id, size)
                }
                "genre" -> {
                    android.util.Log.d("MediaQueryService", "🎨 Routing to queryGenreArtwork for id: $id")
                    queryGenreArtwork(id, size)
                }
                "video" -> {
                    android.util.Log.d("MediaQueryService", "🎨 Routing to queryVideoArtwork for id: $id")
                    queryVideoArtwork(id, size)
                }
                else -> {
                    android.util.Log.d("MediaQueryService", "🎨 Unsupported artwork type: $type")
                    createArtworkMap(
                        id = id,
                        filePath = "",
                        format = "jpeg",
                        size = size,
                        isAvailable = false,
                        error = "Unsupported artwork type: $type"
                    )
                }
            }
            android.util.Log.d("MediaQueryService", "🎨 Artwork result: isAvailable=${result["is_available"]}, data=${result["data"]}, error=${result["error"]}")
            return result
        } catch (e: Exception) {
            android.util.Log.e("MediaQueryService", "🎨 Error querying artwork: ${e.message ?: "Unknown error"}")
            return createArtworkMap(
                id = id,
                filePath = "",
                format = "jpeg",
                size = size,
                isAvailable = false,
                error = "Error loading artwork: ${e.message ?: "Unknown error"}"
            )
        }
    }

    private fun queryAudioArtwork(id: Int, size: String): Map<String, Any> {
        try {
            android.util.Log.d("MediaQueryService", "🎨 Querying audio artwork for id: $id")
            
            // Try multiple approaches for audio artwork extraction
            
            // 1. Try built-in thumbnail generation first (fastest)
            val builtInThumbnail = getBuiltInThumbnail(id.toLong(), "audio")
            if (builtInThumbnail != null) {
                android.util.Log.d("MediaQueryService", "🎨 Found built-in audio thumbnail: $builtInThumbnail")
                return createArtworkMap(
                    id = id,
                    filePath = builtInThumbnail,
                    format = "jpeg",
                    size = size,
                    isAvailable = true,
                    error = ""
                )
            }
            
            // 2. Try album artwork
            val projection = arrayOf(
                MediaStore.Audio.Media._ID,
                MediaStore.Audio.Media.ALBUM_ID,
                MediaStore.Audio.Media.DATA
            )

            val selection = "${MediaStore.Audio.Media._ID} = ?"
            val selectionArgs = arrayOf(id.toString())

            val cursor: Cursor? = contentResolver.query(
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                projection,
                selection,
                selectionArgs,
                null
            )

            cursor?.use {
                if (it.moveToFirst()) {
                    val albumId = it.getLong(it.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM_ID))
                    val filePath = it.getString(it.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA))
                    
                    android.util.Log.d("MediaQueryService", "🎨 Audio file: $filePath, albumId: $albumId")
                    
                    // Try album artwork
                    if (albumId > 0) {
                        val albumArtwork = queryAlbumArtwork(albumId, size)
                        if (albumArtwork["is_available"] == true) {
                            android.util.Log.d("MediaQueryService", "🎨 Found album artwork: ${albumArtwork["data"]}")
                            return albumArtwork
                        }
                    }
                    
                    // Try folder artwork (folder.jpg, cover.jpg, etc.)
                    if (filePath != null && filePath.isNotEmpty()) {
                        val folderArtwork = findFolderArtwork(filePath, size)
                    if (folderArtwork["is_available"] == true) {
                        android.util.Log.d("MediaQueryService", "🎨 Found folder artwork: ${folderArtwork["data"]}")
                        val artworkPath = folderArtwork["data"] as String
                        return createArtworkMap(
                            id = id,
                            filePath = artworkPath,
                            format = folderArtwork["format"] as String,
                            size = size,
                            isAvailable = true,
                            error = ""
                        )
                    }
                    }
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("MediaQueryService", "Error loading audio artwork: ${e.message ?: "Unknown error"}")
        }

        return createArtworkMap(
            id = id,
            filePath = "",
            format = "jpeg",
            size = size,
            isAvailable = false,
            error = "No artwork found"
        )
    }

    private fun queryAlbumArtwork(albumId: Long, size: String): Map<String, Any> {
        try {
            android.util.Log.d("MediaQueryService", "🎨 Querying album artwork for albumId: $albumId")
            
            // Try multiple approaches for album artwork extraction
            
            // 1. Try MediaStore album artwork first
            val mediaStoreArtwork = getMediaStoreAlbumArtwork(albumId, size)
            if (mediaStoreArtwork["is_available"] == true) {
                android.util.Log.d("MediaQueryService", "🎨 Found MediaStore album artwork: ${mediaStoreArtwork["data"]}")
                return mediaStoreArtwork
            }
            
            // 2. Try Android's built-in album artwork extraction
            val builtInArtwork = getBuiltInAlbumArtwork(albumId, size)
            if (builtInArtwork["is_available"] == true) {
                android.util.Log.d("MediaQueryService", "🎨 Found built-in album artwork: ${builtInArtwork["data"]}")
                return builtInArtwork
            }
            
            // 3. Try folder artwork from any track in the album
            val folderArtwork = getAlbumFolderArtwork(albumId, size)
            if (folderArtwork["is_available"] == true) {
                android.util.Log.d("MediaQueryService", "🎨 Found album folder artwork: ${folderArtwork["data"]}")
                return folderArtwork
            }
            
        } catch (e: Exception) {
            android.util.Log.e("MediaQueryService", "Error loading album artwork: ${e.message ?: "Unknown error"}")
        }

        return createArtworkMap(
            id = albumId,
            filePath = "",
            format = "jpeg",
            size = size,
            isAvailable = false,
            error = "No album artwork found"
        )
    }

    private fun getAlbumArtworkFromAnyTrack(albumId: Long, size: String): Map<String, Any> {
        try {
            android.util.Log.d("MediaQueryService", "🎨 Alternative approach: Getting any track for albumId: $albumId")
            
            // Get any track from the album (without ordering by track number)
            val projection = arrayOf(
                MediaStore.Audio.Media._ID,
                MediaStore.Audio.Media.DATA
            )

            val selection = "${MediaStore.Audio.Media.ALBUM_ID} = ?"
            val selectionArgs = arrayOf(albumId.toString())

            val cursor: Cursor? = contentResolver.query(
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                projection,
                selection,
                selectionArgs,
                null
            )

            cursor?.use {
                android.util.Log.d("MediaQueryService", "🎨 Alternative query returned ${it.count} tracks for albumId: $albumId")
                if (it.moveToFirst()) {
                    val filePath = it.getString(it.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA))
                    android.util.Log.d("MediaQueryService", "🎨 Alternative track file path: $filePath")
                    
                    if (filePath != null && filePath.isNotEmpty()) {
                        // Try embedded artwork from this track
                        android.util.Log.d("MediaQueryService", "🎨 Trying embedded artwork from alternative track: $filePath")
                        val embeddedArtwork = extractEmbeddedArtwork(filePath, size)
                        if (embeddedArtwork["is_available"] == true) {
                            android.util.Log.d("MediaQueryService", "🎨 Found embedded artwork from alternative track: ${embeddedArtwork["data"]}")
                            return embeddedArtwork
                        }
                        
                        // Try folder artwork from the track's directory
                        android.util.Log.d("MediaQueryService", "🎨 Trying folder artwork from alternative track directory")
                        val folderArtwork = findFolderArtwork(filePath, size)
                        if (folderArtwork["is_available"] == true) {
                            android.util.Log.d("MediaQueryService", "🎨 Found folder artwork from alternative track: ${folderArtwork["data"]}")
                            return folderArtwork
                        }
                    }
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("MediaQueryService", "Error getting album artwork from any track: ${e.message ?: "Unknown error"}")
        }
        
        return createArtworkMap(
            id = albumId,
            filePath = "",
            format = "jpeg",
            size = size,
            isAvailable = false,
            error = "No alternative track artwork found"
        )
    }

    private fun getMediaStoreAlbumArtwork(albumId: Long, size: String): Map<String, Any> {
        try {
            android.util.Log.d("MediaQueryService", "🎨 Trying MediaStore album artwork for albumId: $albumId")
            
            val projection = arrayOf(
                MediaStore.Audio.Albums._ID,
                MediaStore.Audio.Albums.ALBUM_ART
            )

            val selection = "${MediaStore.Audio.Albums._ID} = ?"
            val selectionArgs = arrayOf(albumId.toString())

            val cursor: Cursor? = contentResolver.query(
                MediaStore.Audio.Albums.EXTERNAL_CONTENT_URI,
                projection,
                selection,
                selectionArgs,
                null
            )

            cursor?.use {
                android.util.Log.d("MediaQueryService", "🎨 MediaStore album query returned ${it.count} rows")
                if (it.moveToFirst()) {
                    val albumArt = it.getString(it.getColumnIndexOrThrow(MediaStore.Audio.Albums.ALBUM_ART))
                    android.util.Log.d("MediaQueryService", "🎨 MediaStore album art path: $albumArt")
                    
                    if (albumArt != null && albumArt.isNotEmpty()) {
                        val file = java.io.File(albumArt)
                        if (file.exists()) {
                            android.util.Log.d("MediaQueryService", "🎨 Found MediaStore album artwork: $albumArt")
                            return createArtworkMap(
                                id = albumId,
                                filePath = albumArt,
                                format = "jpeg",
                                size = size,
                                isAvailable = true,
                                error = ""
                            )
                        }
                    }
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("MediaQueryService", "Error getting MediaStore album artwork: ${e.message ?: "Unknown error"}")
        }
        
        return createArtworkMap(
            id = albumId,
            filePath = "",
            format = "jpeg",
            size = size,
            isAvailable = false,
            error = "No MediaStore album artwork found"
        )
    }

    private fun getBuiltInAlbumArtwork(albumId: Long, size: String): Map<String, Any> {
        try {
            android.util.Log.d("MediaQueryService", "🎨 Trying built-in album artwork for albumId: $albumId")
            
            // First try MediaStore
            val projection = arrayOf(
                MediaStore.Audio.Media._ID,
                MediaStore.Audio.Media.DATA,
                MediaStore.Audio.Media.ALBUM_ID
            )

            val selection = "${MediaStore.Audio.Media.ALBUM_ID} = ?"
            val selectionArgs = arrayOf(albumId.toString())

            val cursor: Cursor? = contentResolver.query(
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                projection,
                selection,
                selectionArgs,
                null
            )

            cursor?.use {
                if (it.moveToFirst()) {
                    val trackId = it.getLong(it.getColumnIndexOrThrow(MediaStore.Audio.Media._ID))
                    android.util.Log.d("MediaQueryService", "🎨 Found MediaStore track for album, trying built-in artwork extraction for trackId: $trackId")
                    
                    // Try to get artwork using Android's built-in thumbnail generation
                    val thumbnail = getBuiltInThumbnail(trackId, "audio")
                    if (thumbnail != null) {
                        android.util.Log.d("MediaQueryService", "🎨 Found built-in thumbnail for album from MediaStore")
                        return createArtworkMap(
                            id = albumId,
                            filePath = thumbnail,
                            format = "jpeg",
                            size = size,
                            isAvailable = true,
                            error = ""
                        )
                    }
                }
            }
            
            // If MediaStore doesn't have the track, try to find it in our cached scan results
            android.util.Log.d("MediaQueryService", "🎨 MediaStore didn't find track for albumId: $albumId, checking cached scan results")
            val cachedResults = getCachedScanResults()
            val audioFiles = cachedResults["audio"] as? List<Map<String, Any>> ?: emptyList()
            
            // Look for any audio file that has this album ID
            for (audioFile in audioFiles) {
                val fileAlbumId = audioFile["album_id"] as? Long
                if (fileAlbumId == albumId) {
                    val filePath = audioFile["data"] as? String
                    if (filePath != null && filePath.isNotEmpty()) {
                        android.util.Log.d("MediaQueryService", "🎨 Found cached track for album built-in artwork: $filePath")
                        
                        // Try to get built-in thumbnail for this file path
                        // Since we don't have a MediaStore ID, we'll try to generate a thumbnail from the file
                        val thumbnail = generateThumbnailFromFile(filePath, size)
                        if (thumbnail != null) {
                            android.util.Log.d("MediaQueryService", "🎨 Generated thumbnail from cached file: $thumbnail")
                            return createArtworkMap(
                                id = albumId,
                                filePath = thumbnail,
                                format = "jpeg",
                                size = size,
                                isAvailable = true,
                                error = ""
                            )
                        }
                    }
                }
            }
            
        } catch (e: Exception) {
            android.util.Log.e("MediaQueryService", "Error getting built-in album artwork: ${e.message ?: "Unknown error"}")
        }
        
        return createArtworkMap(
            id = albumId,
            filePath = "",
            format = "jpeg",
            size = size,
            isAvailable = false,
            error = "No built-in album artwork found"
        )
    }

    private fun getAlbumFolderArtwork(albumId: Long, size: String): Map<String, Any> {
        try {
            android.util.Log.d("MediaQueryService", "🎨 Trying album folder artwork for albumId: $albumId")
            
            // First try to get file path from MediaStore
            val projection = arrayOf(
                MediaStore.Audio.Media._ID,
                MediaStore.Audio.Media.DATA
            )

            val selection = "${MediaStore.Audio.Media.ALBUM_ID} = ?"
            val selectionArgs = arrayOf(albumId.toString())

            val cursor: Cursor? = contentResolver.query(
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                projection,
                selection,
                selectionArgs,
                null
            )

            cursor?.use {
                if (it.moveToFirst()) {
                    val filePath = it.getString(it.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA))
                    if (filePath != null && filePath.isNotEmpty()) {
                        android.util.Log.d("MediaQueryService", "🎨 Found MediaStore track for album folder artwork: $filePath")
                        
                        // Try folder artwork first
                        val folderArtwork = findFolderArtwork(filePath, size)
                        if (folderArtwork["is_available"] == true) {
                            val artworkPath = folderArtwork["data"] as String
                            return createArtworkMap(
                                id = albumId,
                                filePath = artworkPath,
                                format = folderArtwork["format"] as String,
                                size = size,
                                isAvailable = true,
                                error = ""
                            )
                        }
                        
                        // Try embedded artwork
                        val embeddedArtwork = extractEmbeddedArtwork(filePath, size)
                        if (embeddedArtwork["is_available"] == true) {
                            android.util.Log.d("MediaQueryService", "🎨 Found embedded artwork in track: ${embeddedArtwork["data"]}")
                            return createArtworkMap(
                                id = albumId,
                                filePath = embeddedArtwork["data"] as String,
                                format = embeddedArtwork["format"] as String,
                                size = size,
                                isAvailable = true,
                                error = ""
                            )
                        }
                        
                        return folderArtwork
                    }
                }
            }
            
            // If MediaStore doesn't have the track, try to find it in our cached scan results
            android.util.Log.d("MediaQueryService", "🎨 MediaStore didn't find track for albumId: $albumId, checking cached scan results")
            val cachedResults = getCachedScanResults()
            val audioFiles = cachedResults["audio"] as? List<Map<String, Any>> ?: emptyList()
            
            // Look for any audio file that has this album ID
            for (audioFile in audioFiles) {
                val fileAlbumId = audioFile["album_id"] as? Long
                if (fileAlbumId == albumId) {
                    val filePath = audioFile["data"] as? String
                    if (filePath != null && filePath.isNotEmpty()) {
                        android.util.Log.d("MediaQueryService", "🎨 Found cached track for album folder artwork: $filePath")
                        
                        // Try folder artwork first
                        val folderArtwork = findFolderArtwork(filePath, size)
                        if (folderArtwork["is_available"] == true) {
                            val artworkPath = folderArtwork["data"] as String
                            return createArtworkMap(
                                id = albumId,
                                filePath = artworkPath,
                                format = folderArtwork["format"] as String,
                                size = size,
                                isAvailable = true,
                                error = ""
                            )
                        }
                        
                        // Try embedded artwork
                        val embeddedArtwork = extractEmbeddedArtwork(filePath, size)
                        if (embeddedArtwork["is_available"] == true) {
                            android.util.Log.d("MediaQueryService", "🎨 Found embedded artwork in cached track: ${embeddedArtwork["data"]}")
                            return createArtworkMap(
                                id = albumId,
                                filePath = embeddedArtwork["data"] as String,
                                format = embeddedArtwork["format"] as String,
                                size = size,
                                isAvailable = true,
                                error = ""
                            )
                        }
                        
                        return folderArtwork
                    }
                }
            }
            
            // If still no match, try to find any audio file in the same directory structure
            android.util.Log.d("MediaQueryService", "🎨 No exact album match found, trying directory-based search")
            val albumArtwork = findAlbumArtworkInDirectories(albumId, audioFiles, size)
            if (albumArtwork["is_available"] == true) {
                android.util.Log.d("MediaQueryService", "🎨 Found album artwork in directories: ${albumArtwork["data"]}")
                return albumArtwork
            }
            
        } catch (e: Exception) {
            android.util.Log.e("MediaQueryService", "Error getting album folder artwork: ${e.message ?: "Unknown error"}")
        }
        
        return createArtworkMap(
            id = albumId,
            filePath = "",
            format = "jpeg",
            size = size,
            isAvailable = false,
            error = "No album folder artwork found"
        )
    }

    private fun getBuiltInThumbnail(id: Long, type: String): String? {
        try {
            android.util.Log.d("MediaQueryService", "🎨 Getting built-in thumbnail for id: $id, type: $type")
            
            // Use Android's built-in thumbnail generation
            val uri = when (type) {
                "audio" -> MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
                "video" -> MediaStore.Video.Media.EXTERNAL_CONTENT_URI
                else -> return null
            }
            
            val fullUri = android.net.Uri.withAppendedPath(uri, id.toString())
            
            // Try to get thumbnail using ContentResolver
            val thumbnail = contentResolver.loadThumbnail(fullUri, android.util.Size(200, 200), null)
            
            if (thumbnail != null) {
                // Save thumbnail to cache
                val tempDir = File(context.cacheDir, "thumbnails")
                if (!tempDir.exists()) {
                    tempDir.mkdirs()
                }
                
                val tempFile = File(tempDir, "builtin_${type}_${id}_${System.currentTimeMillis()}.jpg")
                val outputStream = java.io.FileOutputStream(tempFile)
                thumbnail.compress(android.graphics.Bitmap.CompressFormat.JPEG, 80, outputStream)
                outputStream.close()
                
                android.util.Log.d("MediaQueryService", "🎨 Generated built-in thumbnail: ${tempFile.absolutePath}")
                // Return the file path - the caller will handle the bytes conversion
                return tempFile.absolutePath
            }
        } catch (e: Exception) {
            android.util.Log.e("MediaQueryService", "Error getting built-in thumbnail: ${e.message ?: "Unknown error"}")
        }
        
        return null
    }

    private fun generateThumbnailFromFile(filePath: String, size: String): String? {
        try {
            android.util.Log.d("MediaQueryService", "🎨 Generating thumbnail from file: $filePath")
            
            // For audio files, we can't generate thumbnails directly, but we can check if there's a folder artwork
            val audioFile = java.io.File(filePath)
            val parentDir = audioFile.parentFile
            
            if (parentDir != null && parentDir.exists() && parentDir.isDirectory) {
                // Look for artwork files in the same directory
                val artworkFile = findArtworkInDirectory(parentDir.absolutePath)
                if (artworkFile != null) {
                    android.util.Log.d("MediaQueryService", "🎨 Found artwork file in same directory: $artworkFile")
                    // Return the file path - the caller will handle the bytes conversion
                    return artworkFile
                }
            }
            
        } catch (e: Exception) {
            android.util.Log.e("MediaQueryService", "Error generating thumbnail from file: ${e.message ?: "Unknown error"}")
        }
        
        return null
    }

    private fun findAlbumArtworkInDirectories(albumId: Long, audioFiles: List<Map<String, Any>>, size: String): Map<String, Any> {
        try {
            android.util.Log.d("MediaQueryService", "🎨 Searching for album artwork in directories for albumId: $albumId")
            
            // First, get the actual file paths of tracks in this album from MediaStore
            val albumTrackPaths = getAlbumTrackPaths(albumId)
            if (albumTrackPaths.isNotEmpty()) {
                android.util.Log.d("MediaQueryService", "🎨 Found ${albumTrackPaths.size} tracks in album $albumId")
                
                // Get unique directories from these track paths
                val albumDirectories = albumTrackPaths.mapNotNull { path ->
                    java.io.File(path).parent
                }.distinct()
                
                android.util.Log.d("MediaQueryService", "🎨 Album directories: $albumDirectories")
                
                // Look for artwork in these specific directories
                for (directory in albumDirectories) {
                    val artworkFile = findArtworkInDirectory(directory)
                    if (artworkFile != null) {
                        android.util.Log.d("MediaQueryService", "🎨 Found artwork file in album directory: $artworkFile")
                        return createArtworkMap(
                            id = albumId,
                            filePath = artworkFile,
                            format = if (artworkFile.endsWith(".png")) "png" else "jpeg",
                            size = size,
                            isAvailable = true,
                            error = ""
                        )
                    }
                }
            }
            
            // Fallback: if we can't get album tracks from MediaStore, try to match by directory structure
            android.util.Log.d("MediaQueryService", "🎨 Fallback: trying to match by directory structure")
            
            // Group audio files by directory
            val directoryGroups = mutableMapOf<String, MutableList<Map<String, Any>>>()
            
            for (audioFile in audioFiles) {
                val filePath = audioFile["data"] as? String
                if (filePath != null && filePath.isNotEmpty()) {
                    val parentDir = java.io.File(filePath).parent
                    if (parentDir != null) {
                        if (!directoryGroups.containsKey(parentDir)) {
                            directoryGroups[parentDir] = mutableListOf()
                        }
                        directoryGroups[parentDir]?.add(audioFile)
                    }
                }
            }
            
            android.util.Log.d("MediaQueryService", "🎨 Found ${directoryGroups.size} directories with audio files")
            
            // Look for directories that might contain this album's tracks
            // This is a heuristic approach - look for directories with multiple audio files
            for ((directory, files) in directoryGroups) {
                if (files.size > 1) { // Directory with multiple audio files (likely an album)
                    android.util.Log.d("MediaQueryService", "🎨 Checking directory with ${files.size} audio files: $directory")
                    
                    val artworkFile = findArtworkInDirectory(directory)
                    if (artworkFile != null) {
                        android.util.Log.d("MediaQueryService", "🎨 Found artwork file in multi-file directory: $artworkFile")
                        return createArtworkMap(
                            id = albumId,
                            filePath = artworkFile,
                            format = if (artworkFile.endsWith(".png")) "png" else "jpeg",
                            size = size,
                            isAvailable = true,
                            error = ""
                        )
                    }
                }
            }
            
        } catch (e: Exception) {
            android.util.Log.e("MediaQueryService", "Error finding album artwork in directories: ${e.message ?: "Unknown error"}")
        }
        
        return createArtworkMap(
            id = albumId,
            filePath = "",
            format = "jpeg",
            size = size,
            isAvailable = false,
            error = "No album artwork found in directories"
        )
    }

    private fun getAlbumTrackPaths(albumId: Long): List<String> {
        try {
            android.util.Log.d("MediaQueryService", "🎨 Getting track paths for album: $albumId")
            
            val projection = arrayOf(
                MediaStore.Audio.Media.DATA
            )
            
            val selection = "${MediaStore.Audio.Media.ALBUM_ID} = ?"
            val selectionArgs = arrayOf(albumId.toString())
            
            val cursor: Cursor? = contentResolver.query(
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                projection,
                selection,
                selectionArgs,
                null
            )
            
            val trackPaths = mutableListOf<String>()
            cursor?.use {
                while (it.moveToNext()) {
                    val data = it.getString(it.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA))
                    if (data != null && data.isNotEmpty()) {
                        trackPaths.add(data)
                    }
                }
            }
            
            android.util.Log.d("MediaQueryService", "🎨 Found ${trackPaths.size} track paths for album $albumId")
            return trackPaths
            
        } catch (e: Exception) {
            android.util.Log.e("MediaQueryService", "Error getting album track paths: ${e.message ?: "Unknown error"}")
            return emptyList()
        }
    }

    private fun findArtworkInDirectory(directory: String): String? {
        try {
            val dir = java.io.File(directory)
            if (!dir.exists() || !dir.isDirectory) {
                return null
            }
            
            // Common artwork file names
            val artworkNames = listOf(
                "folder.jpg", "cover.jpg", "album.jpg", "artwork.jpg", "front.jpg",
                "folder.png", "cover.png", "album.png", "artwork.png", "front.png",
                "Folder.jpg", "Cover.jpg", "Album.jpg", "Artwork.jpg", "Front.jpg",
                "Folder.png", "Cover.png", "Album.png", "Artwork.png", "Front.png"
            )
            
            for (artworkName in artworkNames) {
                val artworkFile = java.io.File(dir, artworkName)
                if (artworkFile.exists() && artworkFile.isFile) {
                    android.util.Log.d("MediaQueryService", "🎨 Found artwork file: ${artworkFile.absolutePath}")
                    return artworkFile.absolutePath
                }
            }
            
        } catch (e: Exception) {
            android.util.Log.e("MediaQueryService", "Error finding artwork in directory: ${e.message ?: "Unknown error"}")
        }
        
        return null
    }


    private fun findFolderArtwork(filePath: String, size: String): Map<String, Any> {
        try {
            val audioFile = File(filePath)
            val parentDir = audioFile.parentFile
            
            if (parentDir != null && parentDir.exists()) {
                // Common artwork file names
                val artworkNames = listOf("folder.jpg", "cover.jpg", "album.jpg", "artwork.jpg", "front.jpg", "folder.png", "cover.png", "album.png", "artwork.png", "front.png")
                
                for (artworkName in artworkNames) {
                    val artworkFile = File(parentDir, artworkName)
                    if (artworkFile.exists() && artworkFile.isFile) {
                        android.util.Log.d("MediaQueryService", "🎨 Found folder artwork file: ${artworkFile.absolutePath}")
                        return createArtworkMap(
                            id = 0,
                            filePath = artworkFile.absolutePath,
                            format = if (artworkName.endsWith(".png")) "png" else "jpeg",
                            size = size,
                            isAvailable = true,
                            error = ""
                        )
                    }
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("MediaQueryService", "Error finding folder artwork: ${e.message ?: "Unknown error"}")
        }
        
        return createArtworkMap(
            id = 0,
            filePath = "",
            format = "jpeg",
            size = size,
            isAvailable = false,
            error = "No folder artwork found"
        )
    }

    private fun extractEmbeddedArtwork(filePath: String, size: String): Map<String, Any> {
        try {
            android.util.Log.d("MediaQueryService", "🎨 Extracting embedded artwork from: $filePath")
            
            val mediaMetadataRetriever = android.media.MediaMetadataRetriever()
            mediaMetadataRetriever.setDataSource(filePath)
            
            // Try to get embedded artwork
            val artwork = mediaMetadataRetriever.embeddedPicture
            mediaMetadataRetriever.release()
            
            if (artwork != null && artwork.size > 0) {
                // Save artwork to cache
                val tempDir = File(context.cacheDir, "thumbnails")
                if (!tempDir.exists()) {
                    tempDir.mkdirs()
                }
                
                val tempFile = File(tempDir, "embedded_${System.currentTimeMillis()}.jpg")
                val outputStream = java.io.FileOutputStream(tempFile)
                outputStream.write(artwork)
                outputStream.close()
                
                android.util.Log.d("MediaQueryService", "🎨 Extracted embedded artwork: ${tempFile.absolutePath}")
                return createArtworkMap(
                    id = 0,
                    filePath = tempFile.absolutePath,
                    format = "jpeg",
                    size = size,
                    isAvailable = true,
                    error = ""
                )
            }
        } catch (e: Exception) {
            android.util.Log.e("MediaQueryService", "Error extracting embedded artwork: ${e.message ?: "Unknown error"}")
        }
        
        return createArtworkMap(
            id = 0,
            filePath = "",
            format = "jpeg",
            size = size,
            isAvailable = false,
            error = "No embedded artwork found"
        )
    }

    private fun getAlbumArtworkFromFirstTrack(albumId: Long, size: String): Map<String, Any> {
        try {
            // Get the first track from the album
            val projection = arrayOf(
                MediaStore.Audio.Media._ID,
                MediaStore.Audio.Media.DATA
            )

            val selection = "${MediaStore.Audio.Media.ALBUM_ID} = ?"
            val selectionArgs = arrayOf(albumId.toString())

            val cursor: Cursor? = contentResolver.query(
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                projection,
                selection,
                selectionArgs,
                "${MediaStore.Audio.Media.TRACK} ASC"
            )

            cursor?.use {
                if (it.moveToFirst()) {
                    val filePath = it.getString(it.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA))
                    
                    if (filePath != null && filePath.isNotEmpty()) {
                        // Try embedded artwork from the first track
                        android.util.Log.d("MediaQueryService", "🎨 Trying embedded artwork from first track: $filePath")
                        val embeddedArtwork = extractEmbeddedArtwork(filePath, size)
                        if (embeddedArtwork["is_available"] == true) {
                            android.util.Log.d("MediaQueryService", "🎨 Found embedded artwork from first track: ${embeddedArtwork["data"]}")
                            return embeddedArtwork
                        }
                        
                        // Try folder artwork from the track's directory
                        android.util.Log.d("MediaQueryService", "🎨 Trying folder artwork from first track directory")
                        val folderArtwork = findFolderArtwork(filePath, size)
                        if (folderArtwork["is_available"] == true) {
                            android.util.Log.d("MediaQueryService", "🎨 Found folder artwork from first track: ${folderArtwork["data"]}")
                            return folderArtwork
                        }
                    }
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("MediaQueryService", "Error getting album artwork from first track: ${e.message ?: "Unknown error"}")
        }
        
        return createArtworkMap(
            id = albumId,
            filePath = "",
            format = "jpeg",
            size = size,
            isAvailable = false,
            error = "No artwork found in first track"
        )
    }

    private fun getAlbumArtworkFromFolder(albumId: Long, size: String): Map<String, Any> {
        try {
            // Get album name and artist to construct folder path
            val projection = arrayOf(
                MediaStore.Audio.Albums._ID,
                MediaStore.Audio.Albums.ALBUM,
                MediaStore.Audio.Albums.ARTIST
            )

            val selection = "${MediaStore.Audio.Albums._ID} = ?"
            val selectionArgs = arrayOf(albumId.toString())

            val cursor: Cursor? = contentResolver.query(
                MediaStore.Audio.Albums.EXTERNAL_CONTENT_URI,
                projection,
                selection,
                selectionArgs,
                null
            )

            cursor?.use {
                if (it.moveToFirst()) {
                    val albumName = it.getString(it.getColumnIndexOrThrow(MediaStore.Audio.Albums.ALBUM))
                    val artistName = it.getString(it.getColumnIndexOrThrow(MediaStore.Audio.Albums.ARTIST))
                    
                    // Try to find album folder in common music directories
                    val commonMusicDirs = listOf(
                        "/storage/emulated/0/Music",
                        "/storage/emulated/0/Download",
                        "/storage/emulated/0/DCIM",
                        "/storage/emulated/0/Pictures"
                    )
                    
                    for (musicDir in commonMusicDirs) {
                        val musicDirFile = File(musicDir)
                        if (musicDirFile.exists()) {
                            // Look for album folder
                            val albumFolders = musicDirFile.listFiles { file ->
                                file.isDirectory && (
                                    file.name.contains(albumName ?: "", ignoreCase = true) ||
                                    file.name.contains(artistName ?: "", ignoreCase = true)
                                )
                            }
                            
                            for (albumFolder in albumFolders ?: emptyArray()) {
                                val artworkNames = listOf("folder.jpg", "cover.jpg", "album.jpg", "artwork.jpg", "front.jpg", "folder.png", "cover.png", "album.png", "artwork.png", "front.png")
                                
                                for (artworkName in artworkNames) {
                                    val artworkFile = File(albumFolder, artworkName)
                                    if (artworkFile.exists() && artworkFile.isFile) {
                                        return createArtworkMap(
                                            id = albumId,
                                            filePath = artworkFile.absolutePath,
                                            format = if (artworkName.endsWith(".png")) "png" else "jpeg",
                                            size = size,
                                            isAvailable = true,
                                            error = ""
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("MediaQueryService", "Error getting album artwork from folder: ${e.message ?: "Unknown error"}")
        }
        
        return createArtworkMap(
            id = albumId,
            filePath = "",
            format = "jpeg",
            size = size,
            isAvailable = false,
            error = "No artwork found in album folder"
        )
    }

    private fun queryVideoArtwork(id: Int, size: String): Map<String, Any> {
        try {
            android.util.Log.d("MediaQueryService", "🎨 Querying video artwork for id: $id")
            
            // For videos, we can try to get thumbnail from MediaStore
            val projection = arrayOf(
                MediaStore.Video.Media._ID,
                MediaStore.Video.Media.DATA
            )

            val selection = "${MediaStore.Video.Media._ID} = ?"
            val selectionArgs = arrayOf(id.toString())

            val cursor: Cursor? = contentResolver.query(
                MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
                projection,
                selection,
                selectionArgs,
                null
            )

            cursor?.use {
                if (it.moveToFirst()) {
                    val videoPath = it.getString(it.getColumnIndexOrThrow(MediaStore.Video.Media.DATA))
                    
                    if (videoPath != null && videoPath.isNotEmpty()) {
                        android.util.Log.d("MediaQueryService", "🎨 Video file: $videoPath")
                        
                        // Try built-in thumbnail generation first (fastest and most reliable)
                        val builtInThumbnail = getBuiltInThumbnail(id.toLong(), "video")
                        if (builtInThumbnail != null) {
                            android.util.Log.d("MediaQueryService", "🎨 Found built-in video thumbnail: $builtInThumbnail")
                            return createArtworkMap(
                                id = id,
                                filePath = builtInThumbnail,
                                format = "jpeg",
                                size = size,
                                isAvailable = true,
                                error = ""
                            )
                        }
                        
                        // Fallback: return video file path for now
                        return createArtworkMap(
                            id = id,
                            filePath = videoPath,
                            format = "video",
                            size = size,
                            isAvailable = true,
                            error = ""
                        )
                    }
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("MediaQueryService", "Error loading video artwork: ${e.message ?: "Unknown error"}")
        }

        return createArtworkMap(
            id = id,
            filePath = "",
            format = "jpeg",
            size = size,
            isAvailable = false,
            error = "No video artwork found"
        )
    }

    private fun generateVideoThumbnail(videoPath: String, size: String): Map<String, Any> {
        try {
            // Use a background thread for heavy operations to avoid blocking UI
            val result = java.util.concurrent.CompletableFuture.supplyAsync {
                try {
                    val mediaMetadataRetriever = android.media.MediaMetadataRetriever()
                    mediaMetadataRetriever.setDataSource(videoPath)
                    
                    // Get thumbnail at 1 second into the video
                    val thumbnail = mediaMetadataRetriever.getFrameAtTime(1000000, android.media.MediaMetadataRetriever.OPTION_CLOSEST_SYNC)
                    mediaMetadataRetriever.release()
                    
                    if (thumbnail != null) {
                        // Save thumbnail to a temporary file
                        val tempDir = File(context.cacheDir, "thumbnails")
                        if (!tempDir.exists()) {
                            tempDir.mkdirs()
                        }
                        
                        val tempFile = File(tempDir, "video_${System.currentTimeMillis()}.jpg")
                        val outputStream = java.io.FileOutputStream(tempFile)
                        thumbnail.compress(android.graphics.Bitmap.CompressFormat.JPEG, 80, outputStream)
                        outputStream.close()
                        
                        android.util.Log.d("MediaQueryService", "🎨 Generated video thumbnail: ${tempFile.absolutePath}")
                        return@supplyAsync createArtworkMap(
                            id = 0,
                            filePath = tempFile.absolutePath,
                            format = "jpeg",
                            size = size,
                            isAvailable = true,
                            error = ""
                        )
                    }
                } catch (e: Exception) {
                    android.util.Log.e("MediaQueryService", "Error generating video thumbnail: ${e.message ?: "Unknown error"}")
                }
                
                return@supplyAsync createArtworkMap(
                    id = 0,
                    filePath = "",
                    format = "jpeg",
                    size = size,
                    isAvailable = false,
                    error = "No video thumbnail found"
                )
            }.get(3, java.util.concurrent.TimeUnit.SECONDS) // 3 second timeout to avoid blocking too long
            
            return result
        } catch (e: Exception) {
            android.util.Log.e("MediaQueryService", "Error in video thumbnail generation: ${e.message ?: "Unknown error"}")
            return createArtworkMap(
                id = 0,
                filePath = "",
                format = "jpeg",
                size = size,
                isAvailable = false,
                error = "Video thumbnail generation failed: ${e.message ?: "Unknown error"}"
            )
        }
    }

    private fun queryArtistArtwork(artistId: Int, size: String): Map<String, Any> {
        try {
            android.util.Log.d("MediaQueryService", "🎨 Querying artist artwork for artistId: $artistId")
            
            // For artist artwork, we'll try to get artwork from the artist's most popular album
            // or from any album by this artist
            
            // First, get the artist name from the artist ID
            val artistProjection = arrayOf(MediaStore.Audio.Artists.ARTIST)
            val artistSelection = "${MediaStore.Audio.Artists._ID} = ?"
            val artistSelectionArgs = arrayOf(artistId.toString())
            
            val artistCursor: Cursor? = contentResolver.query(
                MediaStore.Audio.Artists.EXTERNAL_CONTENT_URI,
                artistProjection,
                artistSelection,
                artistSelectionArgs,
                null
            )
            
            var artistName: String? = null
            artistCursor?.use {
                if (it.moveToFirst()) {
                    artistName = it.getString(it.getColumnIndexOrThrow(MediaStore.Audio.Artists.ARTIST))
                    android.util.Log.d("MediaQueryService", "🎨 Found artist name: $artistName")
                }
            }
            
            if (artistName == null) {
                android.util.Log.d("MediaQueryService", "🎨 Could not find artist name for artistId: $artistId")
                return createArtworkMap(
                    id = artistId,
                    filePath = "",
                    format = "jpeg",
                    size = size,
                    isAvailable = false,
                    error = "Artist not found"
                )
            }
            
            // 1. Try to get the most popular album by this artist
            val projection = arrayOf(
                MediaStore.Audio.Albums._ID,
                MediaStore.Audio.Albums.ALBUM,
                MediaStore.Audio.Albums.ARTIST,
                MediaStore.Audio.Albums.NUMBER_OF_SONGS
            )

            val selection = "${MediaStore.Audio.Albums.ARTIST} = ?"
            val selectionArgs = arrayOf(artistName)

            val cursor: Cursor? = contentResolver.query(
                MediaStore.Audio.Albums.EXTERNAL_CONTENT_URI,
                projection,
                selection,
                selectionArgs,
                "${MediaStore.Audio.Albums.NUMBER_OF_SONGS} DESC" // Order by number of songs (popularity)
            )

            cursor?.use {
                if (it.moveToFirst()) {
                    val albumId = it.getLong(it.getColumnIndexOrThrow(MediaStore.Audio.Albums._ID))
                    val albumName = it.getString(it.getColumnIndexOrThrow(MediaStore.Audio.Albums.ALBUM))
                    
                    android.util.Log.d("MediaQueryService", "🎨 Found album for artist: $albumName (id: $albumId)")
                    
                    // Try to get artwork from this album
                    val albumArtwork = queryAlbumArtwork(albumId, size)
                    if (albumArtwork["is_available"] == true) {
                        android.util.Log.d("MediaQueryService", "🎨 Found artist artwork from album: ${albumArtwork["data"]}")
                        return createArtworkMap(
                            id = artistId,
                            filePath = albumArtwork["data"] as String,
                            format = albumArtwork["format"] as String,
                            size = size,
                            isAvailable = true,
                            error = ""
                        )
                    }
                }
            }
            
            // 2. If no album artwork found, try to get artwork from any track by this artist
            val trackProjection = arrayOf(
                MediaStore.Audio.Media._ID,
                MediaStore.Audio.Media.ALBUM_ID,
                MediaStore.Audio.Media.DATA
            )

            val trackSelection = "${MediaStore.Audio.Media.ARTIST} = ?"
            val trackSelectionArgs = arrayOf(artistName)

            val trackCursor: Cursor? = contentResolver.query(
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                trackProjection,
                trackSelection,
                trackSelectionArgs,
                null
            )

            trackCursor?.use {
                if (it.moveToFirst()) {
                    val trackId = it.getInt(it.getColumnIndexOrThrow(MediaStore.Audio.Media._ID))
                    val filePath = it.getString(it.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA))
                    
                    android.util.Log.d("MediaQueryService", "🎨 Found track for artist: $filePath (id: $trackId)")
                    
                    // Try to get artwork from this track
                    val trackArtwork = queryAudioArtwork(trackId, size)
                    if (trackArtwork["is_available"] == true) {
                        android.util.Log.d("MediaQueryService", "🎨 Found artist artwork from track: ${trackArtwork["data"]}")
                        return createArtworkMap(
                            id = artistId,
                            filePath = trackArtwork["data"] as String,
                            format = trackArtwork["format"] as String,
                            size = size,
                            isAvailable = true,
                            error = ""
                        )
                    }
                }
            }
            
        } catch (e: Exception) {
            android.util.Log.e("MediaQueryService", "Error loading artist artwork: ${e.message ?: "Unknown error"}")
        }

        return createArtworkMap(
            id = artistId,
            filePath = "",
            format = "jpeg",
            size = size,
            isAvailable = false,
            error = "No artist artwork found"
        )
    }

    private fun queryGenreArtwork(genreId: Int, size: String): Map<String, Any> {
        try {
            android.util.Log.d("MediaQueryService", "🎨 Querying genre artwork for genreId: $genreId")
            
            // For genre artwork, we'll try to get artwork from a representative album in this genre
            // or from any track in this genre
            
            // First, get the genre name from the genre ID
            val genreProjection = arrayOf(MediaStore.Audio.Genres.NAME)
            val genreSelection = "${MediaStore.Audio.Genres._ID} = ?"
            val genreSelectionArgs = arrayOf(genreId.toString())
            
            val genreCursor: Cursor? = contentResolver.query(
                MediaStore.Audio.Genres.EXTERNAL_CONTENT_URI,
                genreProjection,
                genreSelection,
                genreSelectionArgs,
                null
            )
            
            var genreName: String? = null
            genreCursor?.use {
                if (it.moveToFirst()) {
                    genreName = it.getString(it.getColumnIndexOrThrow(MediaStore.Audio.Genres.NAME))
                    android.util.Log.d("MediaQueryService", "🎨 Found genre name: $genreName")
                }
            }
            
            if (genreName == null) {
                android.util.Log.d("MediaQueryService", "🎨 Could not find genre name for genreId: $genreId")
                return createArtworkMap(
                    id = genreId,
                    filePath = "",
                    format = "jpeg",
                    size = size,
                    isAvailable = false,
                    error = "Genre not found"
                )
            }
            
            // 1. Try to get an album from this genre
            val projection = arrayOf(
                MediaStore.Audio.Albums._ID,
                MediaStore.Audio.Albums.ALBUM,
                MediaStore.Audio.Albums.ARTIST
            )

            val selection = "${MediaStore.Audio.Albums._ID} IN (SELECT DISTINCT ${MediaStore.Audio.Media.ALBUM_ID} FROM ${MediaStore.Audio.Media.EXTERNAL_CONTENT_URI} WHERE ${MediaStore.Audio.Media.GENRE} = ?)"
            val selectionArgs = arrayOf(genreName)

            val cursor: Cursor? = contentResolver.query(
                MediaStore.Audio.Albums.EXTERNAL_CONTENT_URI,
                projection,
                selection,
                selectionArgs,
                null
            )

            cursor?.use {
                if (it.moveToFirst()) {
                    val albumId = it.getLong(it.getColumnIndexOrThrow(MediaStore.Audio.Albums._ID))
                    val albumName = it.getString(it.getColumnIndexOrThrow(MediaStore.Audio.Albums.ALBUM))
                    
                    android.util.Log.d("MediaQueryService", "🎨 Found album for genre: $albumName (id: $albumId)")
                    
                    // Try to get artwork from this album
                    val albumArtwork = queryAlbumArtwork(albumId, size)
                    if (albumArtwork["is_available"] == true) {
                        android.util.Log.d("MediaQueryService", "🎨 Found genre artwork from album: ${albumArtwork["data"]}")
                        return createArtworkMap(
                            id = genreId,
                            filePath = albumArtwork["data"] as String,
                            format = albumArtwork["format"] as String,
                            size = size,
                            isAvailable = true,
                            error = ""
                        )
                    }
                }
            }
            
            // 2. If no album artwork found, try to get artwork from any track in this genre
            val trackProjection = arrayOf(
                MediaStore.Audio.Media._ID,
                MediaStore.Audio.Media.ALBUM_ID,
                MediaStore.Audio.Media.DATA
            )

            val trackSelection = "${MediaStore.Audio.Media.GENRE} = ?"
            val trackSelectionArgs = arrayOf(genreName)

            val trackCursor: Cursor? = contentResolver.query(
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                trackProjection,
                trackSelection,
                trackSelectionArgs,
                null
            )

            trackCursor?.use {
                if (it.moveToFirst()) {
                    val trackId = it.getInt(it.getColumnIndexOrThrow(MediaStore.Audio.Media._ID))
                    val filePath = it.getString(it.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA))
                    
                    android.util.Log.d("MediaQueryService", "🎨 Found track for genre: $filePath (id: $trackId)")
                    
                    // Try to get artwork from this track
                    val trackArtwork = queryAudioArtwork(trackId, size)
                    if (trackArtwork["is_available"] == true) {
                        android.util.Log.d("MediaQueryService", "🎨 Found genre artwork from track: ${trackArtwork["data"]}")
                        return createArtworkMap(
                            id = genreId,
                            filePath = trackArtwork["data"] as String,
                            format = trackArtwork["format"] as String,
                            size = size,
                            isAvailable = true,
                            error = ""
                        )
                    }
                }
            }
            
        } catch (e: Exception) {
            android.util.Log.e("MediaQueryService", "Error loading genre artwork: ${e.message ?: "Unknown error"}")
        }

        return createArtworkMap(
            id = genreId,
            filePath = "",
            format = "jpeg",
            size = size,
            isAvailable = false,
            error = "No genre artwork found"
        )
    }

    fun clearCachedArtworks() {
        // Implementation for clearing cached artworks
    }

    fun scanMedia(path: String) {
        // Implementation for scanning media files
    }

    // Helper methods
    private fun buildAudioSelection(options: Map<String, Any>?): String? {
        val conditions = mutableListOf<String>()
        
        // Add basic conditions to ensure we get actual audio files
        conditions.add("${MediaStore.Audio.Media.DATA} IS NOT NULL")
        conditions.add("${MediaStore.Audio.Media.DATA} != ''")
        
        options?.let {
            if (it.containsKey("includeMusic") && it["includeMusic"] == false) {
                conditions.add("${MediaStore.Audio.Media.IS_MUSIC} = 0")
            }
            if (it.containsKey("includePodcasts") && it["includePodcasts"] == false) {
                conditions.add("${MediaStore.Audio.Media.IS_PODCAST} = 0")
            }
            if (it.containsKey("includeAudiobooks") && it["includeAudiobooks"] == false) {
                conditions.add("${MediaStore.Audio.Media.IS_AUDIOBOOK} = 0")
            }
        }
        
        return conditions.joinToString(" AND ")
    }

    private fun buildAudioSelectionArgs(options: Map<String, Any>?): Array<String>? {
        return null // No args needed for current implementation
    }

    private fun buildVideoSelection(options: Map<String, Any>?): String? {
        return null // No specific selection for now
    }

    private fun buildVideoSelectionArgs(options: Map<String, Any>?): Array<String>? {
        return null
    }

    private fun buildDocumentSelection(options: Map<String, Any>?): String? {
        val conditions = mutableListOf<String>()
        conditions.add("${MediaStore.Files.FileColumns.MEDIA_TYPE} = ${MediaStore.Files.FileColumns.MEDIA_TYPE_NONE}")
        
        // Add document MIME type filter
        val documentMimeTypes = listOf(
            "application/pdf",
            "application/msword",
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            "text/plain",
            "application/vnd.ms-excel",
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        )
        
        val mimeTypeCondition = documentMimeTypes.joinToString(" OR ") { "MIME_TYPE LIKE '$it%'" }
        conditions.add("($mimeTypeCondition)")
        
        return conditions.joinToString(" AND ")
    }

    private fun buildDocumentSelectionArgs(options: Map<String, Any>?): Array<String>? {
        return null
    }

    private fun buildSortOrder(options: Map<String, Any>?, type: String): String? {
        val sortType = options?.get("sortType") as? String ?: "title"
        val sortOrder = options?.get("sortOrder") as? String ?: "ascending"
        
        val column = when (sortType) {
            "title" -> when (type) {
                "audio" -> MediaStore.Audio.Media.TITLE
                "video" -> MediaStore.Video.Media.TITLE
                "document" -> MediaStore.Files.FileColumns.DISPLAY_NAME
                "album" -> MediaStore.Audio.Albums.ALBUM
                "artist" -> MediaStore.Audio.Artists.ARTIST
                "genre" -> MediaStore.Audio.Genres.NAME
                else -> "title"
            }
            "dateAdded" -> when (type) {
                "audio" -> MediaStore.Audio.Media.DATE_ADDED
                "video" -> MediaStore.Video.Media.DATE_ADDED
                "document" -> MediaStore.Files.FileColumns.DATE_ADDED
                else -> "date_added"
            }
            "size" -> when (type) {
                "audio" -> MediaStore.Audio.Media.SIZE
                "video" -> MediaStore.Video.Media.SIZE
                "document" -> MediaStore.Files.FileColumns.SIZE
                else -> "size"
            }
            else -> "title"
        }
        
        val order = if (sortOrder == "descending") "DESC" else "ASC"
        return "$column $order"
    }

    private fun getFileExtension(path: String): String {
        return if (path.contains(".")) {
            path.substringAfterLast(".")
        } else {
            ""
        }
    }

    private fun getDisplayName(path: String): String {
        val fileName = path.substringAfterLast("/")
        return if (fileName.contains(".")) {
            fileName.substringBeforeLast(".")
        } else {
            fileName
        }
    }

    private fun getDocumentType(mimeType: String): String {
        return when {
            mimeType.startsWith("application/pdf") -> "pdf"
            mimeType.startsWith("application/msword") -> "doc"
            mimeType.startsWith("application/vnd.openxmlformats-officedocument.wordprocessingml") -> "docx"
            mimeType.startsWith("text/plain") -> "txt"
            mimeType.startsWith("application/vnd.ms-excel") -> "xls"
            mimeType.startsWith("application/vnd.openxmlformats-officedocument.spreadsheetml") -> "xlsx"
            else -> "other"
        }
    }

    private fun getFolderType(path: String): String {
        return when {
            path.contains("Music") -> "music"
            path.contains("Movies") -> "video"
            path.contains("Documents") -> "documents"
            path.contains("Download") -> "downloads"
            path.contains("Pictures") -> "pictures"
            else -> "other"
        }
    }

    private fun getFolderSize(folder: File): Long {
        var size = 0L
        folder.listFiles()?.forEach { file ->
            size += if (file.isDirectory) {
                getFolderSize(file)
            } else {
                file.length()
            }
        }
        return size
    }

    private fun getFileCount(folder: File): Int {
        var count = 0
        folder.listFiles()?.forEach { file ->
            if (file.isFile) {
                count++
            } else if (file.isDirectory) {
                count += getFileCount(file)
            }
        }
        return count
    }

    private fun getDirectoryCount(folder: File): Int {
        var count = 0
        folder.listFiles()?.forEach { file ->
            if (file.isDirectory) {
                count++
                count += getDirectoryCount(file)
            }
        }
        return count
    }

    fun queryAudiosFromAlbum(albumId: Int, options: Map<String, Any>?): List<Map<String, Any>> {
        val audios = mutableListOf<Map<String, Any>>()
        
        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.GENRE,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.DATA,
            MediaStore.Audio.Media.SIZE,
            MediaStore.Audio.Media.DATE_ADDED,
            MediaStore.Audio.Media.DATE_MODIFIED,
            MediaStore.Audio.Media.TRACK,
            MediaStore.Audio.Media.YEAR,
            MediaStore.Audio.Media.ALBUM_ARTIST,
            MediaStore.Audio.Media.COMPOSER,
            MediaStore.Audio.Media.MIME_TYPE,
            MediaStore.Audio.Media.IS_MUSIC,
            MediaStore.Audio.Media.IS_RINGTONE,
            MediaStore.Audio.Media.IS_ALARM,
            MediaStore.Audio.Media.IS_NOTIFICATION,
            MediaStore.Audio.Media.IS_PODCAST,
            MediaStore.Audio.Media.IS_AUDIOBOOK
        )

        val selection = "${MediaStore.Audio.Media.ALBUM_ID} = ?"
        val selectionArgs = arrayOf(albumId.toString())
        val sortOrder = buildSortOrder(options, "audio")

        val cursor: Cursor? = contentResolver.query(
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
            projection,
            selection,
            selectionArgs,
            sortOrder
        )

        cursor?.use {
            while (it.moveToNext()) {
                val audio = mapOf(
                    "id" to it.getLong(it.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)),
                    "title" to (it.getString(it.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)) ?: ""),
                    "artist" to (it.getString(it.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)) ?: ""),
                    "album" to (it.getString(it.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM)) ?: ""),
                    "genre" to (it.getString(it.getColumnIndexOrThrow(MediaStore.Audio.Media.GENRE)) ?: ""),
                    "duration" to it.getLong(it.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)),
                    "data" to (it.getString(it.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)) ?: ""),
                    "size" to it.getLong(it.getColumnIndexOrThrow(MediaStore.Audio.Media.SIZE)),
                    "date_added" to it.getLong(it.getColumnIndexOrThrow(MediaStore.Audio.Media.DATE_ADDED)),
                    "date_modified" to it.getLong(it.getColumnIndexOrThrow(MediaStore.Audio.Media.DATE_MODIFIED)),
                    "track" to it.getInt(it.getColumnIndexOrThrow(MediaStore.Audio.Media.TRACK)),
                    "year" to it.getInt(it.getColumnIndexOrThrow(MediaStore.Audio.Media.YEAR)),
                    "album_artist" to (it.getString(it.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM_ARTIST)) ?: ""),
                    "composer" to (it.getString(it.getColumnIndexOrThrow(MediaStore.Audio.Media.COMPOSER)) ?: ""),
                    "file_extension" to getFileExtension(it.getString(it.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)) ?: ""),
                    "display_name" to getDisplayName(it.getString(it.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)) ?: ""),
                    "mime_type" to (it.getString(it.getColumnIndexOrThrow(MediaStore.Audio.Media.MIME_TYPE)) ?: ""),
                    "is_music" to (it.getInt(it.getColumnIndexOrThrow(MediaStore.Audio.Media.IS_MUSIC)) == 1),
                    "is_ringtone" to (it.getInt(it.getColumnIndexOrThrow(MediaStore.Audio.Media.IS_RINGTONE)) == 1),
                    "is_alarm" to (it.getInt(it.getColumnIndexOrThrow(MediaStore.Audio.Media.IS_ALARM)) == 1),
                    "is_notification" to (it.getInt(it.getColumnIndexOrThrow(MediaStore.Audio.Media.IS_NOTIFICATION)) == 1),
                    "is_podcast" to (it.getInt(it.getColumnIndexOrThrow(MediaStore.Audio.Media.IS_PODCAST)) == 1),
                    "is_audiobook" to (it.getInt(it.getColumnIndexOrThrow(MediaStore.Audio.Media.IS_AUDIOBOOK)) == 1)
                )
                audios.add(audio)
            }
        }

        return audios
    }

    fun queryAudiosFromArtist(artistId: Int, options: Map<String, Any>?): List<Map<String, Any>> {
        // For now, return all audios - would need proper artist filtering
        return queryAudios(options)
    }

    fun queryAudiosFromGenre(genreId: Int, options: Map<String, Any>?): List<Map<String, Any>> {
        // For now, return all audios - would need proper genre filtering
        return queryAudios(options)
    }

    fun queryAudiosFromPath(path: String, options: Map<String, Any>?): List<Map<String, Any>> {
        val audios = mutableListOf<Map<String, Any>>()
        
        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.GENRE,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.DATA,
            MediaStore.Audio.Media.SIZE,
            MediaStore.Audio.Media.DATE_ADDED,
            MediaStore.Audio.Media.DATE_MODIFIED,
            MediaStore.Audio.Media.TRACK,
            MediaStore.Audio.Media.YEAR,
            MediaStore.Audio.Media.ALBUM_ARTIST,
            MediaStore.Audio.Media.COMPOSER,
            MediaStore.Audio.Media.MIME_TYPE,
            MediaStore.Audio.Media.IS_MUSIC,
            MediaStore.Audio.Media.IS_RINGTONE,
            MediaStore.Audio.Media.IS_ALARM,
            MediaStore.Audio.Media.IS_NOTIFICATION,
            MediaStore.Audio.Media.IS_PODCAST,
            MediaStore.Audio.Media.IS_AUDIOBOOK
        )

        val selection = "${MediaStore.Audio.Media.DATA} LIKE ?"
        val selectionArgs = arrayOf("$path%")
        val sortOrder = buildSortOrder(options, "audio")

        val cursor: Cursor? = contentResolver.query(
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
            projection,
            selection,
            selectionArgs,
            sortOrder
        )

        cursor?.use {
            while (it.moveToNext()) {
                val audio = mapOf(
                    "id" to it.getLong(it.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)),
                    "title" to (it.getString(it.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)) ?: ""),
                    "artist" to (it.getString(it.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)) ?: ""),
                    "album" to (it.getString(it.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM)) ?: ""),
                    "genre" to (it.getString(it.getColumnIndexOrThrow(MediaStore.Audio.Media.GENRE)) ?: ""),
                    "duration" to it.getLong(it.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)),
                    "data" to (it.getString(it.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)) ?: ""),
                    "size" to it.getLong(it.getColumnIndexOrThrow(MediaStore.Audio.Media.SIZE)),
                    "date_added" to it.getLong(it.getColumnIndexOrThrow(MediaStore.Audio.Media.DATE_ADDED)),
                    "date_modified" to it.getLong(it.getColumnIndexOrThrow(MediaStore.Audio.Media.DATE_MODIFIED)),
                    "track" to it.getInt(it.getColumnIndexOrThrow(MediaStore.Audio.Media.TRACK)),
                    "year" to it.getInt(it.getColumnIndexOrThrow(MediaStore.Audio.Media.YEAR)),
                    "album_artist" to (it.getString(it.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM_ARTIST)) ?: ""),
                    "composer" to (it.getString(it.getColumnIndexOrThrow(MediaStore.Audio.Media.COMPOSER)) ?: ""),
                    "file_extension" to getFileExtension(it.getString(it.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)) ?: ""),
                    "display_name" to getDisplayName(it.getString(it.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)) ?: ""),
                    "mime_type" to (it.getString(it.getColumnIndexOrThrow(MediaStore.Audio.Media.MIME_TYPE)) ?: ""),
                    "is_music" to (it.getInt(it.getColumnIndexOrThrow(MediaStore.Audio.Media.IS_MUSIC)) == 1),
                    "is_ringtone" to (it.getInt(it.getColumnIndexOrThrow(MediaStore.Audio.Media.IS_RINGTONE)) == 1),
                    "is_alarm" to (it.getInt(it.getColumnIndexOrThrow(MediaStore.Audio.Media.IS_ALARM)) == 1),
                    "is_notification" to (it.getInt(it.getColumnIndexOrThrow(MediaStore.Audio.Media.IS_NOTIFICATION)) == 1),
                    "is_podcast" to (it.getInt(it.getColumnIndexOrThrow(MediaStore.Audio.Media.IS_PODCAST)) == 1),
                    "is_audiobook" to (it.getInt(it.getColumnIndexOrThrow(MediaStore.Audio.Media.IS_AUDIOBOOK)) == 1)
                )
                audios.add(audio)
            }
        }

        return audios
    }

    fun queryVideosFromPath(path: String, options: Map<String, Any>?): List<Map<String, Any>> {
        val videos = mutableListOf<Map<String, Any>>()
        
        try {
            val directory = File(path)
            if (directory.exists() && directory.isDirectory) {
                val videoFiles = directory.listFiles { file -> 
                    file.isFile && isVideoFile(file.name)
                }
                videoFiles?.forEach { videoFile ->
                    val videoMap = mapOf(
                        "id" to videoFile.absolutePath.hashCode(),
                        "title" to videoFile.nameWithoutExtension,
                        "display_name" to videoFile.name,
                        "data" to videoFile.absolutePath,
                        "size" to videoFile.length(),
                        "date_added" to videoFile.lastModified(),
                        "date_modified" to videoFile.lastModified(),
                        "mime_type" to getMimeType(videoFile.name),
                        "duration" to 0L, // Would need MediaMetadataRetriever to get actual duration
                        "width" to 0,
                        "height" to 0,
                        "resolution" to "Unknown"
                    )
                    videos.add(videoMap)
                }
            }
        } catch (e: Exception) {
            // If there's an error accessing the directory, return empty list
        }
        
        return videos
    }

    fun queryDocumentsFromPath(path: String, options: Map<String, Any>?): List<Map<String, Any>> {
        val documents = mutableListOf<Map<String, Any>>()
        
        try {
            val directory = File(path)
            if (directory.exists() && directory.isDirectory) {
                val documentFiles = directory.listFiles { file -> 
                    file.isFile && isDocumentFile(file.name)
                }
                documentFiles?.forEach { docFile ->
                    val docMap = mapOf(
                        "id" to docFile.absolutePath.hashCode(),
                        "title" to docFile.nameWithoutExtension,
                        "display_name" to docFile.name,
                        "data" to docFile.absolutePath,
                        "size" to docFile.length(),
                        "date_added" to docFile.lastModified(),
                        "date_modified" to docFile.lastModified(),
                        "mime_type" to getMimeType(docFile.name),
                        "file_extension" to getFileExtension(docFile.name)
                    )
                    documents.add(docMap)
                }
            }
        } catch (e: Exception) {
            // If there's an error accessing the directory, return empty list
        }
        
        return documents
    }

    fun queryFoldersFromPath(path: String, options: Map<String, Any>?, browsingMode: String): List<Map<String, Any>> {
        val result = mutableListOf<Map<String, Any>>()
        
        when (browsingMode) {
            "audio" -> {
                // Query audio files and subfolders from this path
                val audioFiles = queryAudiosFromPath(path, options)
                val subFolders = queryFoldersFromPathRecursive(path, options)
                result.addAll(audioFiles) // audioFiles is already List<Map<String, Any>>
                result.addAll(subFolders)
            }
            "video" -> {
                // Query video files and subfolders from this path
                val videoFiles = queryVideosFromPath(path, options)
                val subFolders = queryFoldersFromPathRecursive(path, options)
                result.addAll(videoFiles) // videoFiles is already List<Map<String, Any>>
                result.addAll(subFolders)
            }
            "document" -> {
                // Query document files and subfolders from this path
                val documentFiles = queryDocumentsFromPath(path, options)
                val subFolders = queryFoldersFromPathRecursive(path, options)
                result.addAll(documentFiles) // documentFiles is already List<Map<String, Any>>
                result.addAll(subFolders)
            }
            "foldersOnly" -> {
                // Query only subfolders from this path
                result.addAll(queryFoldersFromPathRecursive(path, options))
            }
            else -> {
                // Default: return all folders (legacy behavior)
                result.addAll(queryFolders(options))
            }
        }
        
        return result
    }
    
    private fun queryFoldersFromPathRecursive(path: String, options: Map<String, Any>?): List<Map<String, Any>> {
        val folders = mutableListOf<Map<String, Any>>()
        
        try {
            val directory = File(path)
            if (directory.exists() && directory.isDirectory) {
                val subDirectories = directory.listFiles { file -> file.isDirectory }
                subDirectories?.forEach { subDir ->
                    val folderMap = mapOf(
                        "id" to subDir.absolutePath.hashCode(),
                        "name" to subDir.name,
                        "path" to subDir.absolutePath,
                        "file_count" to (subDir.listFiles()?.size ?: 0),
                        "directory_count" to (subDir.listFiles { file -> file.isDirectory }?.size ?: 0),
                        "size" to subDir.length(),
                        "date_added" to subDir.lastModified(),
                        "date_modified" to subDir.lastModified()
                    )
                    folders.add(folderMap)
                }
            }
        } catch (e: Exception) {
            // If there's an error accessing the directory, return empty list
            // This handles permission issues or invalid paths gracefully
        }
        
        return folders
    }
    
    private fun isVideoFile(fileName: String): Boolean {
        val videoExtensions = listOf("mp4", "avi", "mkv", "mov", "wmv", "flv", "webm", "m4v", "3gp", "mpg", "mpeg", "ts", "mts", "m2ts", "vob", "ogv", "divx", "xvid", "asf", "rm", "rmvb")
        val extension = getFileExtension(fileName).lowercase()
        return videoExtensions.contains(extension)
    }
    
    private fun isDocumentFile(fileName: String): Boolean {
        val documentExtensions = listOf(
            "pdf", "doc", "docx", "txt", "rtf", "odt", "xls", "xlsx", "ppt", "pptx", "odp", "ods",
            "csv", "xml", "json", "html", "htm", "css", "js", "py", "java", "cpp", "c", "h", "hpp",
            "md", "tex", "log", "ini", "cfg", "conf", "properties", "yaml", "yml", "sql", "db", "sqlite",
            "png", "jpg", "jpeg", "gif", "bmp", "tiff", "tif", "svg", "webp", "ico", "psd", "ai", "eps"
        )
        val extension = getFileExtension(fileName).lowercase()
        return documentExtensions.contains(extension)
    }
    
    private fun isAudioFile(fileName: String): Boolean {
        val audioExtensions = listOf("mp3", "wav", "flac", "aac", "m4a", "ogg", "wma", "opus", "amr", "3gp", "aiff", "aif", "alac", "ape", "dsd", "dff", "dsf")
        val extension = getFileExtension(fileName).lowercase()
        return audioExtensions.contains(extension)
    }
    
    // Enhanced recursive file system scanning
    fun scanDirectoryRecursively(path: String, fileType: String = "all"): List<Map<String, Any>> {
        val result = mutableListOf<Map<String, Any>>()
        
        try {
            val directory = File(path)
            if (directory.exists() && directory.isDirectory) {
                scanDirectoryRecursivelyInternal(directory, fileType, result)
            }
        } catch (e: Exception) {
            // Handle permission issues or invalid paths gracefully
        }
        
        return result
    }
    
    private fun scanDirectoryRecursivelyInternal(
        directory: File, 
        fileType: String, 
        result: MutableList<Map<String, Any>>
    ) {
        try {
            android.util.Log.d("MediaQueryService", "Scanning directory: ${directory.absolutePath} for fileType: $fileType")
            val files = directory.listFiles()
            android.util.Log.d("MediaQueryService", "Found ${files?.size ?: 0} items in ${directory.absolutePath}")
            
            // Also try to list all files including hidden ones
            val allFiles = directory.listFiles { file -> true }
            android.util.Log.d("MediaQueryService", "All files (including hidden): ${allFiles?.size ?: 0} items")
            
            // Try with different methods
            val listResult = directory.list()
            android.util.Log.d("MediaQueryService", "Directory.list() result: ${listResult?.size ?: "null"} items")
            
            if (listResult != null && listResult.isNotEmpty()) {
                android.util.Log.d("MediaQueryService", "Directory.list() items: ${listResult.joinToString(", ")}")
            }
            
            if (files == null) {
                android.util.Log.w("MediaQueryService", "Cannot list files in directory: ${directory.absolutePath} - permission denied or not accessible")
                return
            }
            
            // Use allFiles if regular files is empty but allFiles has items
            val filesToProcess = if (files.isEmpty() && allFiles != null && allFiles.isNotEmpty()) {
                android.util.Log.d("MediaQueryService", "Using allFiles instead of files - found ${allFiles.size} items")
                allFiles
            } else {
                files
            }
            
            if (filesToProcess.isEmpty()) {
                android.util.Log.d("MediaQueryService", "Directory is empty: ${directory.absolutePath}")
                // Try to get more information about why the directory appears empty
                android.util.Log.d("MediaQueryService", "Directory exists: ${directory.exists()}, isDirectory: ${directory.isDirectory}, canRead: ${directory.canRead()}, canExecute: ${directory.canExecute()}")
                android.util.Log.d("MediaQueryService", "Directory permissions: ${directory.list()?.size ?: "null"} items via list()")
                return
            }
            
            filesToProcess.forEach { file ->
                android.util.Log.d("MediaQueryService", "Processing item: ${file.name}, isDirectory: ${file.isDirectory}, isFile: ${file.isFile}, absolutePath: ${file.absolutePath}")
                
                // Check if this might be a file that's being incorrectly identified as a directory
                val extension = getFileExtension(file.name)
                val hasExtension = extension.isNotEmpty()
                val isAudioByExtension = isAudioFile(file.name)
                val isVideoByExtension = isVideoFile(file.name)
                val isDocumentByExtension = isDocumentFile(file.name)
                
                android.util.Log.d("MediaQueryService", "File analysis: name=${file.name}, extension=$extension, hasExtension=$hasExtension, isAudio=$isAudioByExtension, isVideo=$isVideoByExtension, isDocument=$isDocumentByExtension")
                
                if (file.isDirectory) {
                    // Check if this "directory" might actually be a file that should be processed as media
                    if (hasExtension && (isAudioByExtension || isVideoByExtension || isDocumentByExtension)) {
                        android.util.Log.w("MediaQueryService", "WARNING: Found file with media extension that's being reported as directory: ${file.name}")
                        // Treat it as a file instead of a directory
                        val shouldInclude = when (fileType) {
                            "audio" -> isAudioByExtension
                            "video" -> isVideoByExtension
                            "document" -> isDocumentByExtension
                            "all" -> true
                            else -> true
                        }
                        
                        if (shouldInclude) {
                            android.util.Log.d("MediaQueryService", "Processing as media file: ${file.name}")
                            val fileMap = mapOf(
                                "id" to file.absolutePath.hashCode(),
                                "title" to file.nameWithoutExtension,
                                "display_name" to file.name,
                                "data" to file.absolutePath,
                                "size" to file.length(),
                                "date_modified" to file.lastModified(),
                                "date_added" to file.lastModified(),
                                "mime_type" to getMimeType(file.name),
                                "is_directory" to false
                            )
                            result.add(fileMap)
                        }
                    } else {
                        // It's a real directory, add it to result
                        val dirMap = mapOf(
                            "id" to file.absolutePath.hashCode(),
                            "name" to file.name,
                            "path" to file.absolutePath,
                            "file_count" to (file.listFiles()?.size ?: 0),
                            "directory_count" to (file.listFiles { f -> f.isDirectory }?.size ?: 0),
                            "size" to file.length(),
                            "date_added" to file.lastModified(),
                            "date_modified" to file.lastModified(),
                            "is_directory" to true,
                            "is_hidden" to file.isHidden,
                            "can_read" to file.canRead(),
                            "can_write" to file.canWrite()
                        )
                        result.add(dirMap)
                        
                        // Recursively scan subdirectories
                        scanDirectoryRecursivelyInternal(file, fileType, result)
                    }
                } else if (file.isFile) {
                    // Check if file matches the requested type
                    val shouldInclude = when (fileType) {
                        "audio" -> {
                            val isAudio = isAudioFile(file.name)
                            android.util.Log.d("MediaQueryService", "Found audio file: ${file.name}, path: ${file.absolutePath}, isAudio: $isAudio")
                            isAudio
                        }
                        "video" -> {
                            val isVideo = isVideoFile(file.name)
                            android.util.Log.d("MediaQueryService", "Found video file: ${file.name}, path: ${file.absolutePath}, isVideo: $isVideo")
                            isVideo
                        }
                        "document" -> {
                            val isDoc = isDocumentFile(file.name)
                            android.util.Log.d("MediaQueryService", "Found document file: ${file.name}, path: ${file.absolutePath}, isDocument: $isDoc")
                            isDoc
                        }
                        "all" -> {
                            android.util.Log.d("MediaQueryService", "Found file: ${file.name}, path: ${file.absolutePath}")
                            true
                        }
                        else -> true
                    }
                    
                    if (shouldInclude) {
                        val fileMap = mapOf(
                            "id" to file.absolutePath.hashCode(),
                            "title" to file.nameWithoutExtension,
                            "display_name" to file.name,
                            "data" to file.absolutePath,
                            "path" to file.absolutePath,
                            "size" to file.length(),
                            "date_added" to file.lastModified(),
                            "date_modified" to file.lastModified(),
                            "file_extension" to getFileExtension(file.name),
                            "mime_type" to getMimeType(file.name),
                            "is_directory" to false,
                            "is_hidden" to file.isHidden,
                            "can_read" to file.canRead(),
                            "can_write" to file.canWrite(),
                            "parent_directory" to file.parent
                        )
                        result.add(fileMap)
                    }
                }
            }
        } catch (e: Exception) {
            // Handle permission issues gracefully
        }
    }
    
    // Get optimized directories for scanning (excludes system/cache directories)
    fun getCommonDirectories(): List<String> {
        return listOf(
            "/storage/emulated/0/Music",
            "/storage/emulated/0/Download",
            "/storage/emulated/0/Documents",
            "/storage/emulated/0/Pictures",
            "/storage/emulated/0/DCIM"
            // Excluded: Android/data, Android/obb (system directories that slow down scanning)
        )
    }

    // Get directories to exclude from scanning (system/cache directories)
    private fun getExcludedDirectories(): Set<String> {
        return setOf(
            "/storage/emulated/0/Android/data",
            "/storage/emulated/0/Android/obb",
            "/storage/emulated/0/Android/media",
            "/storage/emulated/0/.android_secure",
            "/storage/emulated/0/.thumbnails",
            "/storage/emulated/0/.cache",
            "/storage/emulated/0/.temp",
            "/storage/emulated/0/Android/system_ext",
            "/storage/emulated/0/Android/vendor"
        )
    }
    
    // Scan common directories for specific file types
    fun scanCommonDirectories(fileType: String = "all"): List<Map<String, Any>> {
        val result = mutableListOf<Map<String, Any>>()
        val commonDirs = getCommonDirectories()
        
        commonDirs.forEach { dirPath ->
            try {
                val directory = File(dirPath)
                if (directory.exists() && directory.isDirectory) {
                    val files = scanDirectoryRecursively(dirPath, fileType)
                    result.addAll(files)
                }
            } catch (e: Exception) {
                // Handle permission issues gracefully
            }
        }
        
        return result
    }

    // Optimized method to scan once and return all media types
    fun scanCommonDirectoriesOptimized(): Map<String, List<Map<String, Any>>> {
        val audioResult = mutableListOf<Map<String, Any>>()
        val videoResult = mutableListOf<Map<String, Any>>()
        val documentResult = mutableListOf<Map<String, Any>>()
        val folderResult = mutableListOf<Map<String, Any>>()
        
        val commonDirs = getCommonDirectories()
        val excludedDirs = getExcludedDirectories()
        
        android.util.Log.d("MediaQueryService", "Starting optimized directory scan...")
        android.util.Log.d("MediaQueryService", "Scanning directories: $commonDirs")
        android.util.Log.d("MediaQueryService", "Excluding directories: $excludedDirs")
        
        commonDirs.forEach { dirPath ->
            try {
                // Skip excluded directories
                if (excludedDirs.any { excluded -> dirPath.startsWith(excluded) }) {
                    android.util.Log.d("MediaQueryService", "Skipping excluded directory: $dirPath")
                    return@forEach
                }
                
                val directory = File(dirPath)
                if (directory.exists() && directory.isDirectory) {
                    android.util.Log.d("MediaQueryService", "Scanning directory: $dirPath")
                    scanDirectoryRecursivelyOptimized(directory, audioResult, videoResult, documentResult, folderResult)
                }
            } catch (e: Exception) {
                android.util.Log.e("MediaQueryService", "Error scanning directory $dirPath: ${e.message}")
            }
        }
        
        android.util.Log.d("MediaQueryService", "Optimized scan completed - Audio: ${audioResult.size}, Video: ${videoResult.size}, Document: ${documentResult.size}, Folder: ${folderResult.size}")
        
        return mapOf(
            "audio" to audioResult,
            "video" to videoResult,
            "document" to documentResult,
            "folder" to folderResult
        )
    }

    // Optimized recursive scanning that categorizes files by type in one pass
    private fun scanDirectoryRecursivelyOptimized(
        directory: File,
        audioResult: MutableList<Map<String, Any>>,
        videoResult: MutableList<Map<String, Any>>,
        documentResult: MutableList<Map<String, Any>>,
        folderResult: MutableList<Map<String, Any>>
    ) {
        try {
            val files = directory.listFiles()

            if (files == null) {
                return
            }

            if (files.isEmpty()) {
                return
            }
                
            files.forEach { file ->
                if (file.isDirectory) {
                    // Add directory to folder result
                    val dirMap = mapOf(
                        "id" to file.absolutePath.hashCode(),
                        "name" to file.name,
                        "path" to file.absolutePath,
                        "file_count" to (file.listFiles()?.size ?: 0),
                        "directory_count" to (file.listFiles { f -> f.isDirectory }?.size ?: 0),
                        "size" to file.length(),
                        "date_added" to file.lastModified(),
                        "date_modified" to file.lastModified(),
                        "is_directory" to true,
                        "is_hidden" to file.isHidden,
                        "can_read" to file.canRead(),
                        "can_write" to file.canWrite()
                    )
                    folderResult.add(dirMap)

                    // Recursively scan subdirectories
                    scanDirectoryRecursivelyOptimized(file, audioResult, videoResult, documentResult, folderResult)
                } else if (file.isFile) {
                    // Categorize file by type
                    val fileName = file.name
                    val extension = getFileExtension(fileName).lowercase()

                    val fileMap = mapOf(
                        "id" to file.absolutePath.hashCode(),
                        "title" to file.nameWithoutExtension,
                        "display_name" to file.name,
                        "data" to file.absolutePath,
                        "size" to file.length(),
                        "date_modified" to file.lastModified(),
                        "date_added" to file.lastModified(),
                        "mime_type" to getMimeType(fileName),
                        "is_directory" to false
                    )

                    when {
                        isAudioFile(fileName) -> {
                            audioResult.add(fileMap)
                        }
                        isVideoFile(fileName) -> {
                            videoResult.add(fileMap)
                        }
                        isDocumentFile(fileName) -> {
                            documentResult.add(fileMap)
                        }
                    }
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("MediaQueryService", "Error scanning directory ${directory.absolutePath}: ${e.message}")
        }
    }
    
    // Enhanced MIME type detection
    private fun getMimeType(fileName: String): String {
        val extension = getFileExtension(fileName).lowercase()
        return when (extension) {
            // Audio
            "mp3" -> "audio/mpeg"
            "wav" -> "audio/wav"
            "flac" -> "audio/flac"
            "aac" -> "audio/aac"
            "m4a" -> "audio/mp4"
            "ogg" -> "audio/ogg"
            "wma" -> "audio/x-ms-wma"
            "opus" -> "audio/opus"
            "amr" -> "audio/amr"
            "3gp" -> "audio/3gpp"
            
            // Video
            "mp4" -> "video/mp4"
            "avi" -> "video/x-msvideo"
            "mkv" -> "video/x-matroska"
            "mov" -> "video/quicktime"
            "wmv" -> "video/x-ms-wmv"
            "flv" -> "video/x-flv"
            "webm" -> "video/webm"
            "m4v" -> "video/x-m4v"
            "3gp" -> "video/3gpp"
            "mpg", "mpeg" -> "video/mpeg"
            
            // Documents
            "pdf" -> "application/pdf"
            "doc" -> "application/msword"
            "docx" -> "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
            "txt" -> "text/plain"
            "rtf" -> "application/rtf"
            "odt" -> "application/vnd.oasis.opendocument.text"
            "xls" -> "application/vnd.ms-excel"
            "xlsx" -> "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
            "ppt" -> "application/vnd.ms-powerpoint"
            "pptx" -> "application/vnd.openxmlformats-officedocument.presentationml.presentation"
            "odp" -> "application/vnd.oasis.opendocument.presentation"
            "ods" -> "application/vnd.oasis.opendocument.spreadsheet"
            "csv" -> "text/csv"
            "xml" -> "application/xml"
            "json" -> "application/json"
            "html", "htm" -> "text/html"
            "css" -> "text/css"
            "js" -> "application/javascript"
            "py" -> "text/x-python"
            "java" -> "text/x-java-source"
            "cpp", "c", "h", "hpp" -> "text/x-c"
            "md" -> "text/markdown"
            "tex" -> "application/x-tex"
            "log" -> "text/plain"
            "ini", "cfg", "conf" -> "text/plain"
            "properties" -> "text/plain"
            "yaml", "yml" -> "application/x-yaml"
            "sql" -> "application/sql"
            "db", "sqlite" -> "application/x-sqlite3"
            
            else -> "application/octet-stream"
        }
    }
}
