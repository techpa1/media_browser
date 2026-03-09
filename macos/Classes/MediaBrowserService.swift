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
                    "size": 0, // Not available in macOS
                    "date_added": Int(item.dateAdded.timeIntervalSince1970),
                    "date_modified": Int(item.lastPlayedDate?.timeIntervalSince1970 ?? 0),
                    "track": item.albumTrackNumber,
                    "year": 0, // Not available in macOS
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
                    "is_audiobook": false // Not available in macOS
                ]
                audios.append(audio)
            }
        }
        
        return audios
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
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "filename", ascending: sortOrder == "ascending")]
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
    
    func queryDocuments(options: [String: Any]?) throws -> [[String: Any]] {
        var documents: [[String: Any]] = []
        
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let downloadsPath = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first ?? documentsPath
        let desktopPath = fileManager.urls(for: .desktopDirectory, in: .userDomainMask).first ?? documentsPath
        
        let paths = [documentsPath, downloadsPath, desktopPath]
        
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
    
    func queryFolders(options: [String: Any]?) throws -> [[String: Any]] {
        var folders: [[String: Any]] = []
        
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let downloadsPath = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first ?? documentsPath
        let musicPath = fileManager.urls(for: .musicDirectory, in: .userDomainMask).first ?? documentsPath
        let moviesPath = fileManager.urls(for: .moviesDirectory, in: .userDomainMask).first ?? documentsPath
        let picturesPath = fileManager.urls(for: .picturesDirectory, in: .userDomainMask).first ?? documentsPath
        let desktopPath = fileManager.urls(for: .desktopDirectory, in: .userDomainMask).first ?? documentsPath
        
        let paths = [
            ("Documents", documentsPath, "documents"),
            ("Downloads", downloadsPath, "downloads"),
            ("Music", musicPath, "music"),
            ("Movies", moviesPath, "video"),
            ("Pictures", picturesPath, "pictures"),
            ("Desktop", desktopPath, "desktop")
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
                    "year": 0 // Not available in macOS
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
        switch type {
        case "audio", "album":
            return try queryAudioArtwork(id: id, size: size)
        case "video":
            return try queryVideoArtwork(id: id, size: size)
        default:
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
        
        // Create a predicate to find the media item by ID
        let predicate = MPMediaPropertyPredicate(value: id, forProperty: MPMediaItemPropertyPersistentID)
        let query = MPMediaQuery()
        query.addFilterPredicate(predicate)
        
        if let items = query.items, let item = items.first {
            if let artwork = item.artwork {
                let imageSize = getImageSize(for: size)
                if let image = artwork.image(at: imageSize) {
                    if let imageData = image.jpegData(compressionQuality: 0.8) {
                        let base64String = imageData.base64EncodedString()
                        return [
                            "id": id,
                            "data": base64String,
                            "format": "jpeg",
                            "size": size,
                            "is_available": true,
                            "error": NSNull()
                        ]
                    }
                }
            }
        }
        
        return [
            "id": id,
            "data": NSNull(),
            "format": "jpeg",
            "size": size,
            "is_available": false,
            "error": "No audio artwork found"
        ]
    }
    
    private func queryVideoArtwork(id: Int, size: String) throws -> [String: Any] {
        guard PHPhotoLibrary.authorizationStatus() == .authorized else {
            throw MediaQueryError.permissionDenied("Photo library access not granted")
        }
        
        // For videos, we need to use PHAsset to get thumbnails
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
        
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [String(id)], options: fetchOptions)
        
        if let asset = assets.firstObject {
            let imageSize = getImageSize(for: size)
            let options = PHImageRequestOptions()
            options.isSynchronous = true
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .exact
            
            var thumbnailImage: NSImage?
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
            
            if let image = thumbnailImage {
                if let imageData = image.tiffRepresentation {
                    let bitmapRep = NSBitmapImageRep(data: imageData)
                    if let jpegData = bitmapRep?.representation(using: .jpeg, properties: [.compressionFactor: 0.8]) {
                        let base64String = jpegData.base64EncodedString()
                        return [
                            "id": id,
                            "data": base64String,
                            "format": "jpeg",
                            "size": size,
                            "is_available": true,
                            "error": NSNull()
                        ]
                    }
                }
            }
        }
        
        return [
            "id": id,
            "data": NSNull(),
            "format": "jpeg",
            "size": size,
            "is_available": false,
            "error": "No video artwork found"
        ]
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
        // Implementation for clearing cached artworks
    }
    
    func scanMedia(path: String) throws {
        // Implementation for scanning media files
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
