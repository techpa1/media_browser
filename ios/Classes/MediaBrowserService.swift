import Foundation
import MediaPlayer
import Photos
import AVFoundation

class MediaBrowserService {
    
    func queryAudios(options: [String: Any]?) throws -> [[String: Any]] {
        guard MPMediaLibrary.authorizationStatus() == .authorized else {
            throw MediaQueryError.permissionDenied("Music library access not granted")
        }
        
        var audios: [[String: Any]] = []
        
        let query = MPMediaQuery.songs()
        let sortType = options?["sortType"] as? String ?? "title"
        let sortOrder = options?["sortOrder"] as? String ?? "ascending"
        
        // Apply sorting
        if let sortDescriptor = createSortDescriptor(for: sortType, order: sortOrder, mediaType: "audio") {
            query.groupingType = .title
            query.addFilterPredicate(MPMediaPropertyPredicate(value: false, forProperty: MPMediaItemPropertyIsCloudItem))
        }
        
        if let items = query.items {
            for item in items {
                let audio: [String: Any] = [
                    "id": item.persistentID,
                    "title": item.title ?? "",
                    "artist": item.artist ?? "",
                    "album": item.albumTitle ?? "",
                    "genre": item.genre ?? "",
                    "duration": Int(item.playbackDuration * 1000), // Convert to milliseconds
                    "data": item.assetURL?.absoluteString ?? "",
                    "size": 0, // Not available in iOS
                    "date_added": Int(item.dateAdded.timeIntervalSince1970),
                    "date_modified": Int(item.lastPlayedDate?.timeIntervalSince1970 ?? 0),
                    "track": item.albumTrackNumber,
                    "year": 0, // Not available in iOS
                    "album_artist": item.albumArtist ?? "",
                    "composer": item.composer ?? "",
                    "file_extension": getFileExtension(from: item.assetURL?.absoluteString ?? ""),
                    "display_name": item.title ?? "",
                    "mime_type": getMimeType(from: item.assetURL?.absoluteString ?? ""),
                    "is_music": true,
                    "is_ringtone": false,
                    "is_alarm": false,
                    "is_notification": false,
                    "is_podcast": item.mediaType == .podcast,
                    "is_audiobook": false // Not available in iOS
                ]
                audios.append(audio)
            }
        }
        
        return audios
    }
    
    func queryAudiosFromAlbum(albumId: Int, options: [String: Any]?) throws -> [[String: Any]] {
        guard MPMediaLibrary.authorizationStatus() == .authorized else {
            throw MediaQueryError.permissionDenied("Music library access not granted")
        }
        
        var audios: [[String: Any]] = []
        
        // Create a predicate to find tracks from specific album
        let predicate = MPMediaPropertyPredicate(value: UInt64(albumId), forProperty: MPMediaItemPropertyAlbumPersistentID)
        let query = MPMediaQuery.songs()
        query.addFilterPredicate(predicate)
        
        if let items = query.items {
            for item in items {
                let audio: [String: Any] = [
                    "id": item.persistentID,
                    "title": item.title ?? "",
                    "artist": item.artist ?? "",
                    "album": item.albumTitle ?? "",
                    "genre": item.genre ?? "",
                    "duration": Int(item.playbackDuration * 1000),
                    "data": item.assetURL?.absoluteString ?? "",
                    "size": 0,
                    "date_added": Int(item.dateAdded.timeIntervalSince1970),
                    "date_modified": Int(item.lastPlayedDate?.timeIntervalSince1970 ?? 0),
                    "track": item.albumTrackNumber,
                    "year": 0,
                    "album_artist": item.albumArtist ?? "",
                    "composer": item.composer ?? "",
                    "file_extension": getFileExtension(from: item.assetURL?.absoluteString ?? ""),
                    "display_name": item.title ?? "",
                    "mime_type": getMimeType(from: item.assetURL?.absoluteString ?? ""),
                    "is_audiobook": false
                ]
                audios.append(audio)
            }
        }
        
        return audios
    }
    
    func queryAudiosFromArtist(artistId: Int, options: [String: Any]?) throws -> [[String: Any]] {
        guard MPMediaLibrary.authorizationStatus() == .authorized else {
            throw MediaQueryError.permissionDenied("Music library access not granted")
        }
        
        var audios: [[String: Any]] = []
        
        // Create a predicate to find tracks from specific artist
        let predicate = MPMediaPropertyPredicate(value: UInt64(artistId), forProperty: MPMediaItemPropertyArtistPersistentID)
        let query = MPMediaQuery.songs()
        query.addFilterPredicate(predicate)
        
        if let items = query.items {
            for item in items {
                let audio: [String: Any] = [
                    "id": item.persistentID,
                    "title": item.title ?? "",
                    "artist": item.artist ?? "",
                    "album": item.albumTitle ?? "",
                    "genre": item.genre ?? "",
                    "duration": Int(item.playbackDuration * 1000),
                    "data": item.assetURL?.absoluteString ?? "",
                    "size": 0,
                    "date_added": Int(item.dateAdded.timeIntervalSince1970),
                    "date_modified": Int(item.lastPlayedDate?.timeIntervalSince1970 ?? 0),
                    "track": item.albumTrackNumber,
                    "year": 0,
                    "album_artist": item.albumArtist ?? "",
                    "composer": item.composer ?? "",
                    "file_extension": getFileExtension(from: item.assetURL?.absoluteString ?? ""),
                    "display_name": item.title ?? "",
                    "mime_type": getMimeType(from: item.assetURL?.absoluteString ?? ""),
                    "is_audiobook": false
                ]
                audios.append(audio)
            }
        }
        
        return audios
    }
    
    func queryAudiosFromGenre(genreId: Int, options: [String: Any]?) throws -> [[String: Any]] {
        guard MPMediaLibrary.authorizationStatus() == .authorized else {
            throw MediaQueryError.permissionDenied("Music library access not granted")
        }
        
        var audios: [[String: Any]] = []
        
        // Create a predicate to find tracks from specific genre
        let predicate = MPMediaPropertyPredicate(value: UInt64(genreId), forProperty: MPMediaItemPropertyGenrePersistentID)
        let query = MPMediaQuery.songs()
        query.addFilterPredicate(predicate)
        
        if let items = query.items {
            for item in items {
                let audio: [String: Any] = [
                    "id": item.persistentID,
                    "title": item.title ?? "",
                    "artist": item.artist ?? "",
                    "album": item.albumTitle ?? "",
                    "genre": item.genre ?? "",
                    "duration": Int(item.playbackDuration * 1000),
                    "data": item.assetURL?.absoluteString ?? "",
                    "size": 0,
                    "date_added": Int(item.dateAdded.timeIntervalSince1970),
                    "date_modified": Int(item.lastPlayedDate?.timeIntervalSince1970 ?? 0),
                    "track": item.albumTrackNumber,
                    "year": 0,
                    "album_artist": item.albumArtist ?? "",
                    "composer": item.composer ?? "",
                    "file_extension": getFileExtension(from: item.assetURL?.absoluteString ?? ""),
                    "display_name": item.title ?? "",
                    "mime_type": getMimeType(from: item.assetURL?.absoluteString ?? ""),
                    "is_audiobook": false
                ]
                audios.append(audio)
            }
        }
        
        return audios
    }
    
    func queryAudiosFromPath(path: String, options: [String: Any]?) throws -> [[String: Any]] {
        // For iOS, we can't easily query by file path since MPMediaLibrary doesn't support it
        // Return empty array for now - this would need a different approach using file system APIs
        return []
    }
    
    func queryVideos(options: [String: Any]?) throws -> [[String: Any]] {
        guard PHPhotoLibrary.authorizationStatus() == .authorized else {
            throw MediaQueryError.permissionDenied("Photo library access not granted")
        }
        
        var videos: [[String: Any]] = []
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.includeHiddenAssets = false
        
        // Apply sorting
        let sortType = options?["sortType"] as? String ?? "title"
        let sortOrder = options?["sortOrder"] as? String ?? "ascending"
        
        if sortType == "dateAdded" {
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: sortOrder == "ascending")]
        } else if sortType == "title" {
            // Note: PHAsset doesn't support filename sorting directly
            // We'll sort by creation date instead and handle title sorting in post-processing
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: sortOrder == "ascending")]
        }
        
        let assets = PHAsset.fetchAssets(with: .video, options: fetchOptions)
        
        assets.enumerateObjects { asset, _, _ in
            let video: [String: Any] = [
                "id": abs(asset.localIdentifier.hash),
                "title": "Video \(asset.localIdentifier)",
                "artist": "",
                "album": "",
                "genre": "",
                "duration": Int(asset.duration * 1000), // Convert to milliseconds
                "data": "", // Not directly accessible
                "size": 0, // Not available
                "date_added": Int(asset.creationDate?.timeIntervalSince1970 ?? 0),
                "date_modified": Int(asset.modificationDate?.timeIntervalSince1970 ?? 0),
                "width": asset.pixelWidth,
                "height": asset.pixelHeight,
                "year": Calendar.current.component(.year, from: asset.creationDate ?? Date()),
                "file_extension": ".mp4", // Default
                "display_name": "Video \(asset.localIdentifier)",
                "mime_type": "video/mp4", // Default
                "codec": "",
                "bitrate": 0,
                "frame_rate": 0.0,
                "is_movie": true,
                "is_tv_show": false,
                "is_music_video": false,
                "is_trailer": false
            ]
            videos.append(video)
        }
        
        return videos
    }
    
    func queryVideosFromPath(path: String, options: [String: Any]?) throws -> [[String: Any]] {
        // For iOS, we can't easily query by file path since PHPhotoLibrary doesn't support it
        // Return empty array for now - this would need a different approach using file system APIs
        return []
    }
    
    func queryDocuments(options: [String: Any]?) throws -> [[String: Any]] {
        var documents: [[String: Any]] = []
        
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let downloadsPath = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first ?? documentsPath
        
        let paths = [documentsPath, downloadsPath]
        
        for path in paths {
            do {
                let contents = try fileManager.contentsOfDirectory(at: path, includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey, .creationDateKey, .contentModificationDateKey], options: [.skipsHiddenFiles])
                
                for url in contents {
                    let resourceValues = try url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey, .creationDateKey, .contentModificationDateKey])
                    
                    if resourceValues.isRegularFile == true {
                        let document: [String: Any] = [
                            "id": abs(url.path.hash),
                            "title": url.lastPathComponent,
                            "data": url.path,
                            "size": resourceValues.fileSize ?? 0,
                            "date_added": Int(resourceValues.creationDate?.timeIntervalSince1970 ?? 0),
                            "date_modified": Int(resourceValues.contentModificationDate?.timeIntervalSince1970 ?? 0),
                            "file_extension": url.pathExtension,
                            "display_name": url.deletingPathExtension().lastPathComponent,
                            "mime_type": getMimeType(from: url.pathExtension),
                            "document_type": getDocumentType(from: url.pathExtension),
                            "author": "",
                            "subject": "",
                            "keywords": "",
                            "page_count": 0,
                            "word_count": 0,
                            "language": "",
                            "is_encrypted": false,
                            "is_compressed": false
                        ]
                        documents.append(document)
                    }
                }
            } catch {
                // Continue with other paths
            }
        }
        
        return documents
    }
    
    func queryDocumentsFromPath(path: String, options: [String: Any]?) throws -> [[String: Any]] {
        var documents: [[String: Any]] = []
        
        let fileManager = FileManager.default
        let targetPath = URL(fileURLWithPath: path)
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: targetPath, includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey, .creationDateKey], options: [.skipsHiddenFiles])
            
            for url in contents {
                do {
                    let resourceValues = try url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey, .creationDateKey])
                    
                    if resourceValues.isRegularFile == true {
                        let pathExtension = url.pathExtension.lowercased()
                        let supportedExtensions = ["pdf", "doc", "docx", "txt", "rtf", "pages", "xls", "xlsx", "ppt", "pptx", "key", "numbers", "csv"]
                        
                        if supportedExtensions.contains(pathExtension) {
                            let document: [String: Any] = [
                                "id": url.path.hash,
                                "title": url.lastPathComponent,
                                "display_name": url.lastPathComponent,
                                "data": url.path,
                                "size": resourceValues.fileSize ?? 0,
                                "date_added": Int(resourceValues.creationDate?.timeIntervalSince1970 ?? 0),
                                "date_modified": Int(resourceValues.creationDate?.timeIntervalSince1970 ?? 0),
                                "mime_type": getMimeType(from: url.path),
                                "file_extension": pathExtension
                            ]
                            documents.append(document)
                        }
                    }
                } catch {
                    // Continue with other files
                }
            }
        } catch {
            // Path doesn't exist or can't be accessed
        }
        
        return documents
    }
    
    func queryFolders(options: [String: Any]?) throws -> [[String: Any]] {
        var folders: [[String: Any]] = []
        
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let downloadsPath = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first ?? documentsPath
        let musicPath = fileManager.urls(for: .musicDirectory, in: .userDomainMask).first ?? documentsPath
        let moviesPath = fileManager.urls(for: .moviesDirectory, in: .userDomainMask).first ?? documentsPath
        let picturesPath = fileManager.urls(for: .picturesDirectory, in: .userDomainMask).first ?? documentsPath
        
        let paths = [
            ("Documents", documentsPath, "documents"),
            ("Downloads", downloadsPath, "downloads"),
            ("Music", musicPath, "music"),
            ("Movies", moviesPath, "video"),
            ("Pictures", picturesPath, "pictures")
        ]
        
        for (name, url, type) in paths {
            do {
                let resourceValues = try url.resourceValues(forKeys: [.isDirectoryKey, .creationDateKey, .contentModificationDateKey])
                
                if resourceValues.isDirectory == true {
                    let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
                    let fileCount = contents.filter { $0.hasDirectoryPath == false }.count
                    let directoryCount = contents.filter { $0.hasDirectoryPath == true }.count
                    
                    let folder: [String: Any] = [
                        "id": abs(url.path.hash),
                        "name": name,
                        "path": url.path,
                        "parent_path": url.deletingLastPathComponent().path,
                        "date_created": Int(resourceValues.creationDate?.timeIntervalSince1970 ?? 0),
                        "date_modified": Int(resourceValues.contentModificationDate?.timeIntervalSince1970 ?? 0),
                        "date_accessed": Int(resourceValues.contentModificationDate?.timeIntervalSince1970 ?? 0),
                        "total_size": 0, // Would need to calculate
                        "file_count": fileCount,
                        "directory_count": directoryCount,
                        "is_hidden": false,
                        "is_read_only": false,
                        "is_system": false,
                        "folder_type": type,
                        "storage_location": "internal"
                    ]
                    folders.append(folder)
                }
            } catch {
                // Continue with other paths
            }
        }
        
        return folders
    }
    
    func queryFoldersFromPath(path: String, options: [String: Any]?, browsingMode: String) throws -> [[String: Any]] {
        var result: [[String: Any]] = []
        
        switch browsingMode {
        case "audio":
            // Query audio files and subfolders from this path
            let audioFiles = try queryAudiosFromPath(path: path, options: options)
            let subFolders = try queryFoldersFromPathRecursive(path: path, options: options)
            result.append(contentsOf: audioFiles)
            result.append(contentsOf: subFolders)
        case "video":
            // Query video files and subfolders from this path
            let videoFiles = try queryVideosFromPath(path: path, options: options)
            let subFolders = try queryFoldersFromPathRecursive(path: path, options: options)
            result.append(contentsOf: videoFiles)
            result.append(contentsOf: subFolders)
        case "document":
            // Query document files and subfolders from this path
            let documentFiles = try queryDocumentsFromPath(path: path, options: options)
            let subFolders = try queryFoldersFromPathRecursive(path: path, options: options)
            result.append(contentsOf: documentFiles)
            result.append(contentsOf: subFolders)
        case "audioAndVideo":
            // Query audio an   d video files and subfolders from this path
            let audioFiles = try queryAudiosFromPath(path: path, options: options)
            let videoFiles = try queryVideosFromPath(path: path, options: options)
            let subFolders = try queryFoldersFromPathRecursive(path: path, options: options)
            result.append(contentsOf: audioFiles)
            result.append(contentsOf: videoFiles)
            result.append(contentsOf: subFolders)
        case "videoAndDocument":
            // Query video and document files and subfolders from this path
            let videoFiles = try queryVideosFromPath(path: path, options: options)
            let documentFiles = try queryDocumentsFromPath(path: path, options: options)
            let subFolders = try queryFoldersFromPathRecursive(path: path, options: options)
            result.append(contentsOf: videoFiles)
            result.append(contentsOf: documentFiles)
            result.append(contentsOf: subFolders)
        case "audioAndDocument":
            // Query audio and document files and subfolders from this path
            let audioFiles = try queryAudiosFromPath(path: path, options: options)
            let documentFiles = try queryDocumentsFromPath(path: path, options: options)
            let subFolders = try queryFoldersFromPathRecursive(path: path, options: options)
            result.append(contentsOf: audioFiles)
            result.append(contentsOf: documentFiles)
            result.append(contentsOf: subFolders)
        case "audioAndVideoAndDocument":
            // Query audio, video and document files and subfolders from this path
            let audioFiles = try queryAudiosFromPath(path: path, options: options)
            let videoFiles = try queryVideosFromPath(path: path, options: options)
            let documentFiles = try queryDocumentsFromPath(path: path, options: options)
            let subFolders = try queryFoldersFromPathRecursive(path: path, options: options)
            result.append(contentsOf: audioFiles)
            result.append(contentsOf: videoFiles)
            result.append(contentsOf: documentFiles)
            result.append(contentsOf: subFolders)
        case "foldersOnly":
            // Query only subfolders from this path
            result.append(contentsOf: try queryFoldersFromPathRecursive(path: path, options: options))
        default:
            // Default: return all folders (legacy behavior)
            result.append(contentsOf: try queryFolders(options: options))
        }
        
        return result
    }
    
    private func queryFoldersFromPathRecursive(path: String, options: [String: Any]?) throws -> [[String: Any]] {
        var folders: [[String: Any]] = []
        
        let fileManager = FileManager.default
        let targetPath = URL(fileURLWithPath: path)
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: targetPath, includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .creationDateKey], options: [.skipsHiddenFiles])
            
            for url in contents {
                do {
                    let resourceValues = try url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .creationDateKey])
                    
                    if resourceValues.isDirectory == true {
                        let folder: [String: Any] = [
                            "id": url.path.hash,
                            "name": url.lastPathComponent,
                            "path": url.path,
                            "file_count": 0, // Would need to count files
                            "directory_count": 0, // Would need to count subdirectories
                            "date_created": Int(resourceValues.creationDate?.timeIntervalSince1970 ?? 0),
                            "date_modified": Int(resourceValues.creationDate?.timeIntervalSince1970 ?? 0),
                            "is_hidden": false,
                            "is_read_only": false,
                            "is_system": false,
                            "folder_type": "user",
                            "storage_location": "internal"
                        ]
                        folders.append(folder)
                    }
                } catch {
                    // Continue with other items
                }
            }
        } catch {
            // Path doesn't exist or can't be accessed
        }
        
        return folders
    }
    
    func queryAlbums(options: [String: Any]?) throws -> [[String: Any]] {
        guard MPMediaLibrary.authorizationStatus() == .authorized else {
            throw MediaQueryError.permissionDenied("Music library access not granted")
        }
        
        var albums: [[String: Any]] = []
        
        let query = MPMediaQuery.albums()
        if let collections = query.collections {
            for collection in collections {
                let album: [String: Any] = [
                    "id": collection.representativeItem?.albumPersistentID ?? 0,
                    "album": collection.representativeItem?.albumTitle ?? "",
                    "artist": collection.representativeItem?.albumArtist ?? "",
                    "num_of_songs": collection.count,
                    "year": 0 // Not available in iOS
                ]
                albums.append(album)
            }
        }
        
        return albums
    }
    
    func queryArtists(options: [String: Any]?) throws -> [[String: Any]] {
        guard MPMediaLibrary.authorizationStatus() == .authorized else {
            throw MediaQueryError.permissionDenied("Music library access not granted")
        }
        
        var artists: [[String: Any]] = []
        
        let query = MPMediaQuery.artists()
        if let collections = query.collections {
            for collection in collections {
                let artist: [String: Any] = [
                    "id": collection.representativeItem?.artistPersistentID ?? 0,
                    "artist": collection.representativeItem?.artist ?? "",
                    "num_of_albums": 0, // Would need additional query
                    "num_of_songs": collection.count
                ]
                artists.append(artist)
            }
        }
        
        return artists
    }
    
    func queryGenres(options: [String: Any]?) throws -> [[String: Any]] {
        guard MPMediaLibrary.authorizationStatus() == .authorized else {
            throw MediaQueryError.permissionDenied("Music library access not granted")
        }
        
        var genres: [[String: Any]] = []
        
        let query = MPMediaQuery.genres()
        if let collections = query.collections {
            for collection in collections {
                let genre: [String: Any] = [
                    "id": collection.representativeItem?.genrePersistentID ?? 0,
                    "genre": collection.representativeItem?.genre ?? "",
                    "num_of_songs": collection.count
                ]
                genres.append(genre)
            }
        }
        
        return genres
    }
    
    func queryArtwork(id: Int, type: String, size: String) throws -> [String: Any] {
        Logger.debug("🎨 iOS: queryArtwork called with id: \(id), type: \(type), size: \(size)")
        
        switch type {
        case "audio":
            return try queryAudioArtwork(id: id, size: size)
        case "album":
            return try queryAlbumArtwork(id: id, size: size)
        case "video":
            return try queryVideoArtwork(id: id, size: size)
        case "artist":
            return try queryArtistArtwork(id: id, size: size)
        case "genre":
            return try queryGenreArtwork(id: id, size: size)
        default:
            Logger.debug("🎨 iOS: Unsupported artwork type: \(type)")
            return [
                "id": id,
                "data": NSNull(),
                "format": "jpeg",
                "size": size,
                "is_available": false,
                "error": "Unsupported artwork type: \(type)"
            ]
        }
    }
    
    private func queryAudioArtwork(id: Int, size: String) throws -> [String: Any] {
        guard MPMediaLibrary.authorizationStatus() == .authorized else {
            throw MediaQueryError.permissionDenied("Music library access not granted")
        }
        
        Logger.debug("🎨 iOS: Querying audio artwork for ID: \(id), size: \(size)")
        
        // Convert Int to UInt64 for MPMediaItemPropertyPersistentID
        // Handle negative values by using bit pattern conversion
        let persistentID = UInt64(bitPattern: Int64(id))
        
        if id < 0 {
            Logger.debug("🎨 iOS: Warning - Negative ID detected: \(id), converted to: \(persistentID)")
        }
        
        // Create a predicate to find the media item by ID
        let predicate = MPMediaPropertyPredicate(value: persistentID, forProperty: MPMediaItemPropertyPersistentID)
        let query = MPMediaQuery()
        query.addFilterPredicate(predicate)
        
        Logger.debug("🎨 iOS: Searching for media item with persistentID: \(persistentID)")
        
        guard let items = query.items, let item = items.first else {
            Logger.debug("🎨 iOS: Media item not found for ID: \(id), persistentID: \(persistentID)")
            
            // Try a broader search to see if there are any media items at all
            let allSongsQuery = MPMediaQuery.songs()
            if let allItems = allSongsQuery.items {
                Logger.debug("🎨 iOS: Total songs in library: \(allItems.count)")
                if let firstItem = allItems.first {
                    Logger.debug("🎨 iOS: First song persistentID: \(firstItem.persistentID), title: \(firstItem.title ?? "Unknown")")
                }
            }
            
            return [
                "id": id,
                "data": NSNull(),
                "format": "jpeg",
                "size": size,
                "is_available": false,
                "error": "Media item not found for ID: \(id)"
            ]
        }
        
        Logger.debug("🎨 iOS: Found media item: \(item.title ?? "Unknown") by \(item.artist ?? "Unknown")")
        Logger.debug("🎨 iOS: Media item details - Album: \(item.albumTitle ?? "Unknown"), Genre: \(item.genre ?? "Unknown")")
        
        // Try multiple approaches to get artwork
        var artwork: MPMediaItemArtwork?
        
        // Approach 1: Direct artwork property
        if let directArtwork = item.artwork {
            Logger.debug("🎨 iOS: Found artwork via direct property")
            artwork = directArtwork
        } else {
            Logger.debug("🎨 iOS: No artwork via direct property, trying alternative approaches")
            
            // Approach 2: Try to get artwork from the album
            if let albumTitle = item.albumTitle, !albumTitle.isEmpty {
                Logger.debug("🎨 iOS: Trying to get artwork from album: \(albumTitle)")
                let albumQuery = MPMediaQuery.albums()
                if let albumCollections = albumQuery.collections {
                    for collection in albumCollections {
                        if let representativeItem = collection.representativeItem,
                           representativeItem.albumTitle == albumTitle {
                            if let albumArtwork = representativeItem.artwork {
                                Logger.debug("🎨 iOS: Found artwork from album collection")
                                artwork = albumArtwork
                                break
                            }
                        }
                    }
                }
            }
            
            // Approach 3: Try to get artwork from any song in the same album
            if artwork == nil, let albumTitle = item.albumTitle, !albumTitle.isEmpty {
                Logger.debug("🎨 iOS: Trying to get artwork from any song in album: \(albumTitle)")
                let albumPredicate = MPMediaPropertyPredicate(value: albumTitle, forProperty: MPMediaItemPropertyAlbumTitle)
                let albumSongsQuery = MPMediaQuery.songs()
                albumSongsQuery.addFilterPredicate(albumPredicate)
                
                if let albumSongs = albumSongsQuery.items {
                    for song in albumSongs {
                        if let songArtwork = song.artwork {
                            Logger.debug("🎨 iOS: Found artwork from song in album: \(song.title ?? "Unknown")")
                            artwork = songArtwork
                            break
                        }
                    }
                }
            }
            
            // Approach 4: Try to get artwork from any song by the same artist
            if artwork == nil, let artist = item.artist, !artist.isEmpty {
                Logger.debug("🎨 iOS: Trying to get artwork from any song by artist: \(artist)")
                let artistPredicate = MPMediaPropertyPredicate(value: artist, forProperty: MPMediaItemPropertyArtist)
                let artistSongsQuery = MPMediaQuery.songs()
                artistSongsQuery.addFilterPredicate(artistPredicate)
                
                if let artistSongs = artistSongsQuery.items {
                    for song in artistSongs {
                        if let songArtwork = song.artwork {
                            Logger.debug("🎨 iOS: Found artwork from song by artist: \(song.title ?? "Unknown")")
                            artwork = songArtwork
                            break
                        }
                    }
                }
            }
        }
        
        guard let finalArtwork = artwork else {
            Logger.debug("🎨 iOS: No artwork available for media item ID: \(id) after trying all approaches")
            return [
                "id": id,
                "data": NSNull(),
                "format": "jpeg",
                "size": size,
                "is_available": false,
                "error": "No artwork available for this media item"
            ]
        }
        
        return try processArtworkImage(artwork: finalArtwork, id: id, size: size)
    }
    
    private func queryAlbumArtwork(id: Int, size: String) throws -> [String: Any] {
        guard MPMediaLibrary.authorizationStatus() == .authorized else {
            throw MediaQueryError.permissionDenied("Music library access not granted")
        }
        
        Logger.debug("🎨 iOS: Querying album artwork for ID: \(id), size: \(size)")
        
        // Convert Int to UInt64 for MPMediaItemPropertyAlbumPersistentID
        let albumPersistentID = UInt64(bitPattern: Int64(id))
        
        if id < 0 {
            Logger.debug("🎨 iOS: Warning - Negative album ID detected: \(id), converted to: \(albumPersistentID)")
        }
        
        // First, try to find the album collection
        let albumQuery = MPMediaQuery.albums()
        if let collections = albumQuery.collections {
            for collection in collections {
                if let representativeItem = collection.representativeItem,
                   representativeItem.albumPersistentID == albumPersistentID {
                    
                    Logger.debug("🎨 iOS: Found album collection for ID: \(id)")
                    Logger.debug("🎨 iOS: Album details - Title: \(representativeItem.albumTitle ?? "Unknown"), Artist: \(representativeItem.albumArtist ?? "Unknown")")
                    
                    // Try to get artwork from the representative item first
                    if let artwork = representativeItem.artwork {
                        Logger.debug("🎨 iOS: Found artwork in representative item")
                        return try processArtworkImage(artwork: artwork, id: id, size: size)
                    }
                    
                    // If no artwork in representative item, try to find artwork from any song in the album
                    Logger.debug("🎨 iOS: No artwork in representative item, searching songs in album")
                    for item in collection.items {
            if let artwork = item.artwork {
                            Logger.debug("🎨 iOS: Found artwork in song: \(item.title ?? "Unknown")")
                            return try processArtworkImage(artwork: artwork, id: id, size: size)
                        }
                    }
                    
                    // If still no artwork found, try to find artwork from any song with the same album title
                    if let albumTitle = representativeItem.albumTitle, !albumTitle.isEmpty {
                        Logger.debug("🎨 iOS: No artwork found in collection, trying broader search for album: \(albumTitle)")
                        let albumPredicate = MPMediaPropertyPredicate(value: albumTitle, forProperty: MPMediaItemPropertyAlbumTitle)
                        let albumSongsQuery = MPMediaQuery.songs()
                        albumSongsQuery.addFilterPredicate(albumPredicate)
                        
                        if let albumSongs = albumSongsQuery.items {
                            for song in albumSongs {
                                if let artwork = song.artwork {
                                    Logger.debug("🎨 iOS: Found artwork in broader search for song: \(song.title ?? "Unknown")")
                                    return try processArtworkImage(artwork: artwork, id: id, size: size)
                                }
                            }
                        }
                    }
                    
                    // If still no artwork found, return not available
                    Logger.debug("🎨 iOS: No artwork found in any song of album ID: \(id)")
                        return [
                            "id": id,
                        "data": NSNull(),
                            "format": "jpeg",
                            "size": size,
                        "is_available": false,
                        "error": "No artwork found in album"
                    ]
                }
            }
        }
        
        Logger.debug("🎨 iOS: Album not found for ID: \(id)")
        return [
            "id": id,
            "data": NSNull(),
            "format": "jpeg",
            "size": size,
            "is_available": false,
            "error": "Album not found for ID: \(id)"
        ]
    }
    
    private func queryArtistArtwork(id: Int, size: String) throws -> [String: Any] {
        guard MPMediaLibrary.authorizationStatus() == .authorized else {
            throw MediaQueryError.permissionDenied("Music library access not granted")
        }
        
        Logger.debug("🎨 iOS: Querying artist artwork for ID: \(id), size: \(size)")
        
        // Convert Int to UInt64 for MPMediaItemPropertyArtistPersistentID
        let artistPersistentID = UInt64(bitPattern: Int64(id))
        
        if id < 0 {
            Logger.debug("🎨 iOS: Warning - Negative artist ID detected: \(id), converted to: \(artistPersistentID)")
        }
        
        // Find the artist collection
        let artistQuery = MPMediaQuery.artists()
        if let collections = artistQuery.collections {
            for collection in collections {
                if let representativeItem = collection.representativeItem,
                   representativeItem.artistPersistentID == artistPersistentID {
                    
                    Logger.debug("🎨 iOS: Found artist collection for ID: \(id)")
                    Logger.debug("🎨 iOS: Artist details - Name: \(representativeItem.artist ?? "Unknown")")
                    
                    // Try to get artwork from the representative item first
                    if let artwork = representativeItem.artwork {
                        Logger.debug("🎨 iOS: Found artwork in artist representative item")
                        return try processArtworkImage(artwork: artwork, id: id, size: size)
                    }
                    
                    // If no artwork in representative item, try to find artwork from any song by this artist
                    Logger.debug("🎨 iOS: No artwork in representative item, searching songs by artist")
                    for item in collection.items {
                        if let artwork = item.artwork {
                            Logger.debug("🎨 iOS: Found artwork in song: \(item.title ?? "Unknown")")
                            return try processArtworkImage(artwork: artwork, id: id, size: size)
                        }
                    }
                    
                    // If still no artwork found, try to find artwork from any song with the same artist name
                    if let artistName = representativeItem.artist, !artistName.isEmpty {
                        Logger.debug("🎨 iOS: No artwork found in collection, trying broader search for artist: \(artistName)")
                        let artistPredicate = MPMediaPropertyPredicate(value: artistName, forProperty: MPMediaItemPropertyArtist)
                        let artistSongsQuery = MPMediaQuery.songs()
                        artistSongsQuery.addFilterPredicate(artistPredicate)
                        
                        if let artistSongs = artistSongsQuery.items {
                            for song in artistSongs {
                                if let artwork = song.artwork {
                                    Logger.debug("🎨 iOS: Found artwork in broader search for song: \(song.title ?? "Unknown")")
                                    return try processArtworkImage(artwork: artwork, id: id, size: size)
                                }
                            }
                        }
                    }
                    
                    // If still no artwork found, return not available
                    Logger.debug("🎨 iOS: No artwork found in any song by artist ID: \(id)")
        return [
            "id": id,
            "data": NSNull(),
            "format": "jpeg",
            "size": size,
            "is_available": false,
                        "error": "No artwork found for artist"
                    ]
                }
            }
        }
        
        Logger.debug("🎨 iOS: Artist not found for ID: \(id)")
        return [
            "id": id,
            "data": NSNull(),
            "format": "jpeg",
            "size": size,
            "is_available": false,
            "error": "Artist not found for ID: \(id)"
        ]
    }
    
    private func queryGenreArtwork(id: Int, size: String) throws -> [String: Any] {
        guard MPMediaLibrary.authorizationStatus() == .authorized else {
            throw MediaQueryError.permissionDenied("Music library access not granted")
        }
        
        Logger.debug("🎨 iOS: Querying genre artwork for ID: \(id), size: \(size)")
        
        // Convert Int to UInt64 for MPMediaItemPropertyGenrePersistentID
        let genrePersistentID = UInt64(bitPattern: Int64(id))
        
        if id < 0 {
            Logger.debug("🎨 iOS: Warning - Negative genre ID detected: \(id), converted to: \(genrePersistentID)")
        }
        
        // Find the genre collection
        let genreQuery = MPMediaQuery.genres()
        if let collections = genreQuery.collections {
            for collection in collections {
                if let representativeItem = collection.representativeItem,
                   representativeItem.genrePersistentID == genrePersistentID {
                    
                    Logger.debug("🎨 iOS: Found genre collection for ID: \(id)")
                    Logger.debug("🎨 iOS: Genre details - Name: \(representativeItem.genre ?? "Unknown")")
                    
                    // Try to get artwork from the representative item first
                    if let artwork = representativeItem.artwork {
                        Logger.debug("🎨 iOS: Found artwork in genre representative item")
                        return try processArtworkImage(artwork: artwork, id: id, size: size)
                    }
                    
                    // If no artwork in representative item, try to find artwork from any song in this genre
                    Logger.debug("🎨 iOS: No artwork in representative item, searching songs in genre")
                    for item in collection.items {
                        if let artwork = item.artwork {
                            Logger.debug("🎨 iOS: Found artwork in song: \(item.title ?? "Unknown")")
                            return try processArtworkImage(artwork: artwork, id: id, size: size)
                        }
                    }
                    
                    // If still no artwork found, try to find artwork from any song with the same genre name
                    if let genreName = representativeItem.genre, !genreName.isEmpty {
                        Logger.debug("🎨 iOS: No artwork found in collection, trying broader search for genre: \(genreName)")
                        let genrePredicate = MPMediaPropertyPredicate(value: genreName, forProperty: MPMediaItemPropertyGenre)
                        let genreSongsQuery = MPMediaQuery.songs()
                        genreSongsQuery.addFilterPredicate(genrePredicate)
                        
                        if let genreSongs = genreSongsQuery.items {
                            for song in genreSongs {
                                if let artwork = song.artwork {
                                    Logger.debug("🎨 iOS: Found artwork in broader search for song: \(song.title ?? "Unknown")")
                                    return try processArtworkImage(artwork: artwork, id: id, size: size)
                                }
                            }
                        }
                    }
                    
                    // If still no artwork found, return not available
                    Logger.debug("🎨 iOS: No artwork found in any song in genre ID: \(id)")
                    return [
                        "id": id,
                        "data": NSNull(),
                        "format": "jpeg",
                        "size": size,
                        "is_available": false,
                        "error": "No artwork found for genre"
                    ]
                }
            }
        }
        
        Logger.debug("🎨 iOS: Genre not found for ID: \(id)")
        return [
            "id": id,
            "data": NSNull(),
            "format": "jpeg",
            "size": size,
            "is_available": false,
            "error": "Genre not found for ID: \(id)"
        ]
    }
    
    private func queryVideoArtwork(id: Int, size: String) throws -> [String: Any] {
        guard PHPhotoLibrary.authorizationStatus() == .authorized else {
            throw MediaQueryError.permissionDenied("Photo library access not granted")
        }
        
        Logger.debug("🎨 iOS: Querying video artwork for ID: \(id), size: \(size)")
        
        // For videos, we need to use PHAsset to get thumbnails
        // Note: The ID from queryVideos is actually the hash of the localIdentifier
        // We need to find the asset by enumerating through all video assets
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
        
        let assets = PHAsset.fetchAssets(with: .video, options: fetchOptions)
        
        var targetAsset: PHAsset?
        assets.enumerateObjects { asset, _, stop in
            if abs(asset.localIdentifier.hash) == id {
                targetAsset = asset
                stop.pointee = true
            }
        }
        
        guard let asset = targetAsset else {
            return [
                "id": id,
                "data": NSNull(),
                "format": "jpeg",
                "size": size,
                "is_available": false,
                "error": "Video asset not found for ID: \(id)"
            ]
        }
        
            let imageSize = getImageSize(for: size)
            let options = PHImageRequestOptions()
            options.isSynchronous = true
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .exact
            
            var thumbnailImage: UIImage?
            let semaphore = DispatchSemaphore(value: 0)
            
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: imageSize,
                contentMode: .aspectFit,
                options: options
            ) { image, _ in
                thumbnailImage = image
                semaphore.signal()
            }
            
            semaphore.wait()
            
        guard let image = thumbnailImage else {
                    return [
                        "id": id,
                "data": NSNull(),
                        "format": "jpeg",
                        "size": size,
                "is_available": false,
                "error": "Failed to generate video thumbnail"
            ]
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return [
                "id": id,
                "data": NSNull(),
                "format": "jpeg",
                "size": size,
                "is_available": false,
                "error": "Failed to convert video thumbnail to JPEG data"
            ]
        }
        
        // Save artwork to a temporary file and return the file path
        let filePath = saveArtworkToFile(imageData: imageData, id: id, format: "jpeg")
        
        if let path = filePath {
            Logger.debug("🎨 iOS: Successfully saved video artwork for ID: \(id) to file: \(path)")
            return [
                "id": id,
                "data": path,
                "format": "jpeg",
                "size": size,
                "is_available": true,
                "error": NSNull()
            ]
        } else {
            Logger.debug("🎨 iOS: Failed to save video artwork file for ID: \(id)")
        return [
            "id": id,
            "data": NSNull(),
            "format": "jpeg",
            "size": size,
            "is_available": false,
                "error": "Failed to save video artwork to file"
        ]
        }
    }
    
    private func getImageSize(for size: String) -> CGSize {
        let dimension: CGFloat
        switch size.lowercased() {
        case "small":
            dimension = 150
        case "medium":
            dimension = 300
        case "large":
            dimension = 600
        case "original":
            dimension = 1024
        default:
            dimension = 300
        }
        return CGSize(width: dimension, height: dimension)
    }
    
    func clearCachedArtworks() throws {
        do {
            // Get the documents directory
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let artworkDir = documentsPath.appendingPathComponent("artwork")
            
            // Check if artwork directory exists
            if FileManager.default.fileExists(atPath: artworkDir.path) {
                // Get all files in the artwork directory
                let files = try FileManager.default.contentsOfDirectory(at: artworkDir, includingPropertiesForKeys: nil, options: [])
                
                // Delete all artwork files
                for file in files {
                    try FileManager.default.removeItem(at: file)
                    Logger.debug("🎨 iOS: Deleted cached artwork: \(file.lastPathComponent)")
                }
                
                Logger.debug("🎨 iOS: Cleared \(files.count) cached artwork files")
            }
        } catch {
            Logger.debug("🎨 iOS: Error clearing cached artworks: \(error.localizedDescription)")
            throw MediaQueryError.queryFailed("Failed to clear cached artworks: \(error.localizedDescription)")
        }
    }
    
    /// Debug function to test artwork availability in the media library
    func debugArtworkAvailability() throws -> [String: Any] {
        guard MPMediaLibrary.authorizationStatus() == .authorized else {
            throw MediaQueryError.permissionDenied("Music library access not granted")
        }
        
        var debugInfo: [String: Any] = [:]
        var songsWithArtwork = 0
        var songsWithoutArtwork = 0
        var albumsWithArtwork = 0
        var albumsWithoutArtwork = 0
        var artistsWithArtwork = 0
        var artistsWithoutArtwork = 0
        var genresWithArtwork = 0
        var genresWithoutArtwork = 0
        
        // Check songs
        let songsQuery = MPMediaQuery.songs()
        if let songs = songsQuery.items {
            for song in songs {
                if song.artwork != nil {
                    songsWithArtwork += 1
                } else {
                    songsWithoutArtwork += 1
                }
            }
        }
        
        // Check albums
        let albumsQuery = MPMediaQuery.albums()
        if let albumCollections = albumsQuery.collections {
            for collection in albumCollections {
                if let representativeItem = collection.representativeItem {
                    if representativeItem.artwork != nil {
                        albumsWithArtwork += 1
                    } else {
                        albumsWithoutArtwork += 1
                    }
                }
            }
        }
        
        // Check artists
        let artistsQuery = MPMediaQuery.artists()
        if let artistCollections = artistsQuery.collections {
            for collection in artistCollections {
                if let representativeItem = collection.representativeItem {
                    if representativeItem.artwork != nil {
                        artistsWithArtwork += 1
                    } else {
                        artistsWithoutArtwork += 1
                    }
                }
            }
        }
        
        // Check genres
        let genresQuery = MPMediaQuery.genres()
        if let genreCollections = genresQuery.collections {
            for collection in genreCollections {
                if let representativeItem = collection.representativeItem {
                    if representativeItem.artwork != nil {
                        genresWithArtwork += 1
                    } else {
                        genresWithoutArtwork += 1
                    }
                }
            }
        }
        
        debugInfo = [
            "songs": [
                "total": songsWithArtwork + songsWithoutArtwork,
                "with_artwork": songsWithArtwork,
                "without_artwork": songsWithoutArtwork
            ],
            "albums": [
                "total": albumsWithArtwork + albumsWithoutArtwork,
                "with_artwork": albumsWithArtwork,
                "without_artwork": albumsWithoutArtwork
            ],
            "artists": [
                "total": artistsWithArtwork + artistsWithoutArtwork,
                "with_artwork": artistsWithArtwork,
                "without_artwork": artistsWithoutArtwork
            ],
            "genres": [
                "total": genresWithArtwork + genresWithoutArtwork,
                "with_artwork": genresWithArtwork,
                "without_artwork": genresWithoutArtwork
            ]
        ]
        
        Logger.debug("🎨 iOS: Debug artwork availability - Songs: \(songsWithArtwork)/\(songsWithArtwork + songsWithoutArtwork) with artwork, Albums: \(albumsWithArtwork)/\(albumsWithArtwork + albumsWithoutArtwork) with artwork")
        
        return debugInfo
    }
    
    func scanMedia(path: String) throws {
        // Implementation for scanning media files
    }
    
    // MARK: - Helper Methods
    
    /// Process artwork image and save to file
    private func processArtworkImage(artwork: MPMediaItemArtwork, id: Int, size: String) throws -> [String: Any] {
        let imageSize = getImageSize(for: size)
        
        // Try to get the artwork image with fallback sizes
        var image: UIImage?
        
        // First try with the requested size
        image = artwork.image(at: imageSize)
        
        // If that fails, try with a smaller size
        if image == nil {
            Logger.debug("🎨 iOS: Failed to get artwork at requested size \(imageSize), trying smaller size")
            let smallerSize = CGSize(width: 150, height: 150)
            image = artwork.image(at: smallerSize)
        }
        
        // If that still fails, try with the original size
        if image == nil {
            Logger.debug("🎨 iOS: Failed to get artwork at smaller size, trying original size")
            image = artwork.image(at: CGSize(width: 1024, height: 1024))
        }
        
        guard let finalImage = image else {
            Logger.debug("🎨 iOS: Failed to generate artwork image for ID: \(id)")
            return [
                "id": id,
                "data": NSNull(),
                "format": "jpeg",
                "size": size,
                "is_available": false,
                "error": "Failed to generate artwork image"
            ]
        }
        
        // Convert image to JPEG data
        guard let imageData = finalImage.jpegData(compressionQuality: 0.8) else {
            return [
                "id": id,
                "data": NSNull(),
                "format": "jpeg",
                "size": size,
                "is_available": false,
                "error": "Failed to convert artwork to JPEG data"
            ]
        }
        
        // Save artwork to a temporary file and return the file path
        let filePath = saveArtworkToFile(imageData: imageData, id: id, format: "jpeg")
        
        if let path = filePath {
            Logger.debug("🎨 iOS: Successfully saved artwork for ID: \(id) to file: \(path)")
            return [
                "id": id,
                "data": path,
                "format": "jpeg",
                "size": size,
                "is_available": true,
                "error": NSNull()
            ]
        } else {
            Logger.debug("🎨 iOS: Failed to save artwork file for ID: \(id)")
            return [
                "id": id,
                "data": NSNull(),
                "format": "jpeg",
                "size": size,
                "is_available": false,
                "error": "Failed to save artwork to file"
            ]
        }
    }
    
    /// Save artwork data to a temporary file and return the file path
    private func saveArtworkToFile(imageData: Data, id: Int, format: String) -> String? {
        do {
            // Get the documents directory
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let artworkDir = documentsPath.appendingPathComponent("artwork")
            
            // Create artwork directory if it doesn't exist
            try FileManager.default.createDirectory(at: artworkDir, withIntermediateDirectories: true, attributes: nil)
            
            // Create a unique filename
            let timestamp = Int(Date().timeIntervalSince1970)
            let filename = "artwork_\(id)_\(timestamp).\(format)"
            let fileURL = artworkDir.appendingPathComponent(filename)
            
            // Write the image data to the file
            try imageData.write(to: fileURL)
            
            Logger.debug("🎨 iOS: Saved artwork to file: \(fileURL.path)")
            return fileURL.path
        } catch {
            Logger.debug("🎨 iOS: Error saving artwork to file: \(error.localizedDescription)")
            return nil
        }
    }
    
    // Helper methods
    private func createSortDescriptor(for sortType: String, order: String, mediaType: String) -> NSSortDescriptor? {
        let ascending = order == "ascending"
        
        switch sortType {
        case "title":
            return NSSortDescriptor(key: "title", ascending: ascending)
        case "dateAdded":
            return NSSortDescriptor(key: "dateAdded", ascending: ascending)
        case "dateModified":
            return NSSortDescriptor(key: "dateModified", ascending: ascending)
        case "size":
            return NSSortDescriptor(key: "fileSize", ascending: ascending)
        default:
            return NSSortDescriptor(key: "title", ascending: ascending)
        }
    }
    
    private func getFileExtension(from path: String) -> String {
        return URL(fileURLWithPath: path).pathExtension
    }
    
    private func getMimeType(from fileExtension: String) -> String {
        switch fileExtension.lowercased() {
        case "mp3":
            return "audio/mpeg"
        case "m4a":
            return "audio/mp4"
        case "wav":
            return "audio/wav"
        case "flac":
            return "audio/flac"
        case "mp4":
            return "video/mp4"
        case "mov":
            return "video/quicktime"
        case "avi":
            return "video/x-msvideo"
        case "pdf":
            return "application/pdf"
        case "doc":
            return "application/msword"
        case "docx":
            return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        case "txt":
            return "text/plain"
        default:
            return "application/octet-stream"
        }
    }
    
    private func getDocumentType(from fileExtension: String) -> String {
        switch fileExtension.lowercased() {
        case "pdf":
            return "pdf"
        case "doc":
            return "doc"
        case "docx":
            return "docx"
        case "txt":
            return "txt"
        case "rtf":
            return "rtf"
        case "xls":
            return "xls"
        case "xlsx":
            return "xlsx"
        case "ppt":
            return "ppt"
        case "pptx":
            return "pptx"
        case "csv":
            return "csv"
        case "xml":
            return "xml"
        case "html":
            return "html"
        case "epub":
            return "epub"
        case "mobi":
            return "mobi"
        case "azw":
            return "azw"
        default:
            return "other"
        }
    }
}

enum MediaQueryError: Error {
    case permissionDenied(String)
    case queryFailed(String)
    case invalidParameters(String)
    
    var localizedDescription: String {
        switch self {
        case .permissionDenied(let message):
            return "Permission denied: \(message)"
        case .queryFailed(let message):
            return "Query failed: \(message)"
        case .invalidParameters(let message):
            return "Invalid parameters: \(message)"
        }
    }
}
