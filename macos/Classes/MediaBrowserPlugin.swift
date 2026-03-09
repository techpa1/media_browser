import FlutterMacOS
import Cocoa
import MediaPlayer
import AVFoundation
import Photos
import Foundation

public class MediaBrowserPlugin: NSObject, FlutterPlugin {
    private let mediaBrowserService = MediaBrowserService()
    private let mediaExtractionService = MediaExtractionService()
    
    // Timeout configurations
    private let defaultTimeout: TimeInterval = 30.0 // 30 seconds
    private let shortTimeout: TimeInterval = 10.0 // 10 seconds
    private let longTimeout: TimeInterval = 60.0 // 60 seconds
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "media_browser", binaryMessenger: registrar.messenger)
        let instance = MediaBrowserPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
        case "checkPermissions":
            let mediaType = call.arguments as? [String: Any]
            let type = mediaType?["mediaType"] as? String ?? "all"
            checkPermissions(mediaType: type, result: result)
        case "requestPermissions":
            let mediaType = call.arguments as? [String: Any]
            let type = mediaType?["mediaType"] as? String ?? "all"
            requestPermissions(mediaType: type, result: result)
        case "queryAudios":
            let options = call.arguments as? [String: Any]
            queryAudios(options: options, result: result)
        case "queryVideos":
            let options = call.arguments as? [String: Any]
            queryVideos(options: options, result: result)
        case "queryDocuments":
            let options = call.arguments as? [String: Any]
            queryDocuments(options: options, result: result)
        case "queryFolders":
            let options = call.arguments as? [String: Any]
            queryFolders(options: options, result: result)
        case "queryAlbums":
            let options = call.arguments as? [String: Any]
            queryAlbums(options: options, result: result)
        case "queryArtists":
            let options = call.arguments as? [String: Any]
            queryArtists(options: options, result: result)
        case "queryGenres":
            let options = call.arguments as? [String: Any]
            queryGenres(options: options, result: result)
        case "queryArtwork":
            let args = call.arguments as? [String: Any]
            let id = args?["id"] as? Int ?? 0
            let type = args?["type"] as? String ?? "audio"
            let size = args?["size"] as? String ?? "medium"
            queryArtwork(id: id, type: type, size: size, result: result)
        case "clearCachedArtworks":
            clearCachedArtworks(result: result)
        case "scanMedia":
            let args = call.arguments as? [String: Any]
            let path = args?["path"] as? String ?? ""
            scanMedia(path: path, result: result)
        case "getDeviceInfo":
            getDeviceInfo(result: result)
        case "exportTrack":
            let args = call.arguments as? [String: Any]
            let trackId = args?["trackId"] as? String ?? ""
            exportTrack(trackId: trackId, result: result)
        case "exportTrackWithArtwork":
            let args = call.arguments as? [String: Any]
            let trackId = args?["trackId"] as? String ?? ""
            exportTrackWithArtwork(trackId: trackId, result: result)
        case "extractArtwork":
            let args = call.arguments as? [String: Any]
            let trackId = args?["trackId"] as? String ?? ""
            extractArtwork(trackId: trackId, result: result)
        case "canExportTrack":
            canExportTrack(result: result)
        case "getTrackExtension":
            let args = call.arguments as? [String: Any]
            let trackPath = args?["trackPath"] as? String ?? ""
            getTrackExtension(trackPath: trackPath, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func checkPermissions(mediaType: String, result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let timeoutWorkItem = DispatchWorkItem {
                var missingPermissions: [[String: Any]] = []
                var allGranted = true
                
                switch mediaType {
                case "audio", "MediaType.audio":
                    let audioStatus = MPMediaLibrary.authorizationStatus()
                    Logger.debug("🎵 Audio permission status: \(audioStatus.rawValue) (\(audioStatus))")
                    // Only consider it granted if it's explicitly authorized
                    if audioStatus != .authorized {
                        allGranted = false
                        missingPermissions.append([
                            "name": "NSAppleMusicUsageDescription",
                            "description": "Access to music library",
                            "isRequired": true,
                            "type": "audio"
                        ])
                    }
                case "video", "MediaType.video":
                    let videoStatus = PHPhotoLibrary.authorizationStatus()
                    Logger.debug("🎥 Video permission status: \(videoStatus.rawValue) (\(videoStatus))")
                    // Only consider it granted if it's explicitly authorized
                    if videoStatus != .authorized {
                        allGranted = false
                        missingPermissions.append([
                            "name": "NSPhotoLibraryUsageDescription",
                            "description": "Access to photo library",
                            "isRequired": true,
                            "type": "video"
                        ])
                    }
                case "document", "MediaType.document":
                    // Documents don't require special permissions on macOS
                    // They can be accessed through the app's sandbox
                    break
                case "folder", "MediaType.folder":
                    // Folders don't require special permissions on macOS
                    // They can be accessed through the app's sandbox
                    break
                case "all":
                    if MPMediaLibrary.authorizationStatus() != .authorized {
                        allGranted = false
                        missingPermissions.append([
                            "name": "NSAppleMusicUsageDescription",
                            "description": "Access to music library",
                            "isRequired": true,
                            "type": "audio"
                        ])
                    }
                    if PHPhotoLibrary.authorizationStatus() != .authorized {
                        allGranted = false
                        missingPermissions.append([
                            "name": "NSPhotoLibraryUsageDescription",
                            "description": "Access to photo library",
                            "isRequired": false,
                            "type": "video"
                        ])
                    }
                default:
                    break
                }
                
                let status = allGranted ? "granted" : "denied"
                let message = allGranted ? "All permissions granted" : "Missing required permissions"
                
                DispatchQueue.main.async {
                    result([
                        "status": status,
                        "message": message,
                        "missingPermissions": missingPermissions
                    ])
                }
            }
            
            DispatchQueue.global(qos: .userInitiated).async(execute: timeoutWorkItem)
            
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + self.shortTimeout) {
                if !timeoutWorkItem.isCancelled {
                    timeoutWorkItem.cancel()
                    DispatchQueue.main.async {
                        result(FlutterError(
                            code: "PERMISSION_CHECK_TIMEOUT",
                            message: "Permission check timed out after \(self.shortTimeout) seconds",
                            details: nil
                        ))
                    }
                }
            }
        }
    }
    
    private func requestPermissions(mediaType: String, result: @escaping FlutterResult) {
        switch mediaType {
        case "audio", "MediaType.audio":
            Logger.debug("🎵 Requesting audio permission...")
            let currentStatus = MPMediaLibrary.authorizationStatus()
            Logger.debug("🎵 Current audio permission status: \(currentStatus.rawValue)")
            
            MPMediaLibrary.requestAuthorization { status in
                Logger.debug("🎵 Audio permission request result: \(status.rawValue)")
                DispatchQueue.main.async {
                    let granted = status == .authorized
                    let missingPermissions: [[String: Any]] = granted ? [] : [[
                        "name": "NSAppleMusicUsageDescription",
                        "description": "Access to music library",
                        "isRequired": true,
                        "type": "audio"
                    ]]
                    
                    result([
                        "status": granted ? "granted" : "denied",
                        "message": granted ? "Permission granted" : "Permission denied",
                        "missingPermissions": missingPermissions
                    ])
                }
            }
        case "video", "MediaType.video":
            Logger.debug("🎥 Requesting video permission...")
            let currentStatus = PHPhotoLibrary.authorizationStatus()
            Logger.debug("🎥 Current video permission status: \(currentStatus.rawValue)")
            
            PHPhotoLibrary.requestAuthorization { status in
                Logger.debug("🎥 Video permission request result: \(status.rawValue)")
                DispatchQueue.main.async {
                    let granted = status == .authorized
                    let missingPermissions: [[String: Any]] = granted ? [] : [[
                        "name": "NSPhotoLibraryUsageDescription",
                        "description": "Access to photo library",
                        "isRequired": true,
                        "type": "video"
                    ]]
                    
                    result([
                        "status": granted ? "granted" : "denied",
                        "message": granted ? "Permission granted" : "Permission denied",
                        "missingPermissions": missingPermissions
                    ])
                }
            }
        case "document", "MediaType.document":
            // Documents don't require special permissions on macOS
            result([
                "status": "granted",
                "message": "Document access granted (no special permissions required)",
                "missingPermissions": []
            ])
        case "folder", "MediaType.folder":
            // Folders don't require special permissions on macOS
            result([
                "status": "granted",
                "message": "Folder access granted (no special permissions required)",
                "missingPermissions": []
            ])
        case "all":
            MPMediaLibrary.requestAuthorization { musicStatus in
                PHPhotoLibrary.requestAuthorization { photoStatus in
                    DispatchQueue.main.async {
                        let musicGranted = musicStatus == .authorized
                        let photoGranted = photoStatus == .authorized
                        let allGranted = musicGranted && photoGranted
                        
                        var missingPermissions: [[String: Any]] = []
                        if !musicGranted {
                            missingPermissions.append([
                                "name": "NSAppleMusicUsageDescription",
                                "description": "Access to music library",
                                "isRequired": true,
                                "type": "audio"
                            ])
                        }
                        if !photoGranted {
                            missingPermissions.append([
                                "name": "NSPhotoLibraryUsageDescription",
                                "description": "Access to photo library",
                                "isRequired": false,
                                "type": "video"
                            ])
                        }
                        
                        result([
                            "status": allGranted ? "granted" : "denied",
                            "message": allGranted ? "All permissions granted" : "Some permissions denied",
                            "missingPermissions": missingPermissions
                        ])
                    }
                }
            }
        default:
            result([
                "status": "granted",
                "message": "No permissions required",
                "missingPermissions": []
            ])
        }
    }
    
    private func queryAudios(options: [String: Any]?, result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let timeoutWorkItem = DispatchWorkItem {
                do {
                    let audios = try self.mediaBrowserService.queryAudios(options: options)
                    DispatchQueue.main.async {
                        result(audios)
                    }
                } catch {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "QUERY_AUDIO_FAILED", message: "Failed to query audio files: \(error.localizedDescription)", details: nil))
                    }
                }
            }
            
            DispatchQueue.global(qos: .userInitiated).async(execute: timeoutWorkItem)
            
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + self.defaultTimeout) {
                if !timeoutWorkItem.isCancelled {
                    timeoutWorkItem.cancel()
                    DispatchQueue.main.async {
                        result(FlutterError(code: "QUERY_AUDIO_TIMEOUT", message: "Audio query timed out after \(self.defaultTimeout) seconds", details: nil))
                    }
                }
            }
        }
    }
    
    private func queryVideos(options: [String: Any]?, result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let timeoutWorkItem = DispatchWorkItem {
                do {
                    let videos = try self.mediaBrowserService.queryVideos(options: options)
                    DispatchQueue.main.async {
                        result(videos)
                    }
                } catch {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "QUERY_VIDEO_FAILED", message: "Failed to query video files: \(error.localizedDescription)", details: nil))
                    }
                }
            }
            
            DispatchQueue.global(qos: .userInitiated).async(execute: timeoutWorkItem)
            
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + self.defaultTimeout) {
                if !timeoutWorkItem.isCancelled {
                    timeoutWorkItem.cancel()
                    DispatchQueue.main.async {
                        result(FlutterError(code: "QUERY_VIDEO_TIMEOUT", message: "Video query timed out after \(self.defaultTimeout) seconds", details: nil))
                    }
                }
            }
        }
    }
    
    private func queryDocuments(options: [String: Any]?, result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let timeoutWorkItem = DispatchWorkItem {
                do {
                    let documents = try self.mediaBrowserService.queryDocuments(options: options)
                    DispatchQueue.main.async {
                        result(documents)
                    }
                } catch {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "QUERY_DOCUMENT_FAILED", message: "Failed to query document files: \(error.localizedDescription)", details: nil))
                    }
                }
            }
            
            DispatchQueue.global(qos: .userInitiated).async(execute: timeoutWorkItem)
            
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + self.defaultTimeout) {
                if !timeoutWorkItem.isCancelled {
                    timeoutWorkItem.cancel()
                    DispatchQueue.main.async {
                        result(FlutterError(code: "QUERY_DOCUMENT_TIMEOUT", message: "Document query timed out after \(self.defaultTimeout) seconds", details: nil))
                    }
                }
            }
        }
    }
    
    private func queryFolders(options: [String: Any]?, result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let timeoutWorkItem = DispatchWorkItem {
                do {
                    let folders = try self.mediaBrowserService.queryFolders(options: options)
                    DispatchQueue.main.async {
                        result(folders)
                    }
                } catch {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "QUERY_FOLDER_FAILED", message: "Failed to query folders: \(error.localizedDescription)", details: nil))
                    }
                }
            }
            
            DispatchQueue.global(qos: .userInitiated).async(execute: timeoutWorkItem)
            
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + self.defaultTimeout) {
                if !timeoutWorkItem.isCancelled {
                    timeoutWorkItem.cancel()
                    DispatchQueue.main.async {
                        result(FlutterError(code: "QUERY_FOLDER_TIMEOUT", message: "Folder query timed out after \(self.defaultTimeout) seconds", details: nil))
                    }
                }
            }
        }
    }
    
    private func queryAlbums(options: [String: Any]?, result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let timeoutWorkItem = DispatchWorkItem {
                do {
                    let albums = try self.mediaBrowserService.queryAlbums(options: options)
                    DispatchQueue.main.async {
                        result(albums)
                    }
                } catch {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "QUERY_ALBUM_FAILED", message: "Failed to query albums: \(error.localizedDescription)", details: nil))
                    }
                }
            }
            
            DispatchQueue.global(qos: .userInitiated).async(execute: timeoutWorkItem)
            
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + self.defaultTimeout) {
                if !timeoutWorkItem.isCancelled {
                    timeoutWorkItem.cancel()
                    DispatchQueue.main.async {
                        result(FlutterError(code: "QUERY_ALBUM_TIMEOUT", message: "Album query timed out after \(self.defaultTimeout) seconds", details: nil))
                    }
                }
            }
        }
    }
    
    private func queryArtists(options: [String: Any]?, result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let timeoutWorkItem = DispatchWorkItem {
                do {
                    let artists = try self.mediaBrowserService.queryArtists(options: options)
                    DispatchQueue.main.async {
                        result(artists)
                    }
                } catch {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "QUERY_ARTIST_FAILED", message: "Failed to query artists: \(error.localizedDescription)", details: nil))
                    }
                }
            }
            
            DispatchQueue.global(qos: .userInitiated).async(execute: timeoutWorkItem)
            
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + self.defaultTimeout) {
                if !timeoutWorkItem.isCancelled {
                    timeoutWorkItem.cancel()
                    DispatchQueue.main.async {
                        result(FlutterError(code: "QUERY_ARTIST_TIMEOUT", message: "Artist query timed out after \(self.defaultTimeout) seconds", details: nil))
                    }
                }
            }
        }
    }
    
    private func queryGenres(options: [String: Any]?, result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let timeoutWorkItem = DispatchWorkItem {
                do {
                    let genres = try self.mediaBrowserService.queryGenres(options: options)
                    DispatchQueue.main.async {
                        result(genres)
                    }
                } catch {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "QUERY_GENRE_FAILED", message: "Failed to query genres: \(error.localizedDescription)", details: nil))
                    }
                }
            }
            
            DispatchQueue.global(qos: .userInitiated).async(execute: timeoutWorkItem)
            
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + self.defaultTimeout) {
                if !timeoutWorkItem.isCancelled {
                    timeoutWorkItem.cancel()
                    DispatchQueue.main.async {
                        result(FlutterError(code: "QUERY_GENRE_TIMEOUT", message: "Genre query timed out after \(self.defaultTimeout) seconds", details: nil))
                    }
                }
            }
        }
    }
    
    private func queryArtwork(id: Int, type: String, size: String, result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let timeoutWorkItem = DispatchWorkItem {
                do {
                    let artwork = try self.mediaBrowserService.queryArtwork(id: id, type: type, size: size)
                    DispatchQueue.main.async {
                        result(artwork)
                    }
                } catch {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "QUERY_ARTWORK_FAILED", message: "Failed to query artwork: \(error.localizedDescription)", details: nil))
                    }
                }
            }
            
            DispatchQueue.global(qos: .userInitiated).async(execute: timeoutWorkItem)
            
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + self.longTimeout) {
                if !timeoutWorkItem.isCancelled {
                    timeoutWorkItem.cancel()
                    DispatchQueue.main.async {
                        result(FlutterError(code: "QUERY_ARTWORK_TIMEOUT", message: "Artwork query timed out after \(self.longTimeout) seconds", details: nil))
                    }
                }
            }
        }
    }
    
    private func clearCachedArtworks(result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let timeoutWorkItem = DispatchWorkItem {
                do {
                    try self.mediaBrowserService.clearCachedArtworks()
                    DispatchQueue.main.async {
                        result(nil)
                    }
                } catch {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "CLEAR_CACHE_FAILED", message: "Failed to clear cached artworks: \(error.localizedDescription)", details: nil))
                    }
                }
            }
            
            DispatchQueue.global(qos: .userInitiated).async(execute: timeoutWorkItem)
            
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + self.longTimeout) {
                if !timeoutWorkItem.isCancelled {
                    timeoutWorkItem.cancel()
                    DispatchQueue.main.async {
                        result(FlutterError(code: "CLEAR_CACHE_TIMEOUT", message: "Clear cache timed out after \(self.longTimeout) seconds", details: nil))
                    }
                }
            }
        }
    }
    
    private func scanMedia(path: String, result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let timeoutWorkItem = DispatchWorkItem {
                do {
                    try self.mediaBrowserService.scanMedia(path: path)
                    DispatchQueue.main.async {
                        result(nil)
                    }
                } catch {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "SCAN_MEDIA_FAILED", message: "Failed to scan media: \(error.localizedDescription)", details: nil))
                    }
                }
            }
            
            DispatchQueue.global(qos: .userInitiated).async(execute: timeoutWorkItem)
            
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + self.longTimeout) {
                if !timeoutWorkItem.isCancelled {
                    timeoutWorkItem.cancel()
                    DispatchQueue.main.async {
                        result(FlutterError(code: "SCAN_MEDIA_TIMEOUT", message: "Media scan timed out after \(self.longTimeout) seconds", details: nil))
                    }
                }
            }
        }
    }
    
    private func getDeviceInfo(result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let timeoutWorkItem = DispatchWorkItem {
                let deviceInfo: [String: Any] = [
                    "platform": "macOS",
                    "version": ProcessInfo.processInfo.operatingSystemVersionString,
                    "model": Host.current().localizedName ?? "Unknown",
                    "name": Host.current().name ?? "Unknown",
                    "systemName": "macOS",
                    "identifierForVendor": Host.current().address ?? "Unknown"
                ]
                
                DispatchQueue.main.async {
                    result(deviceInfo)
                }
            }
            
            DispatchQueue.global(qos: .userInitiated).async(execute: timeoutWorkItem)
            
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + self.shortTimeout) {
                if !timeoutWorkItem.isCancelled {
                    timeoutWorkItem.cancel()
                    DispatchQueue.main.async {
                        result(FlutterError(code: "DEVICE_INFO_TIMEOUT", message: "Device info query timed out after \(self.shortTimeout) seconds", details: nil))
                    }
                }
            }
        }
    }
    
    // MARK: - Media Extraction Methods
    
    private func exportTrack(trackId: String, result: @escaping FlutterResult) {
        Logger.debug("🎵 MediaBrowserPlugin (macOS): exportTrack called with trackId: \(trackId)")
        
        mediaExtractionService.exportTrack(trackId: trackId) { [weak self] extractionResult in
            switch extractionResult {
            case .success(let response):
                Logger.debug("🎵 MediaBrowserPlugin (macOS): exportTrack - success")
                result(response)
            case .failure(let error):
                Logger.debug("🎵 MediaBrowserPlugin (macOS): exportTrack - error: \(error.localizedDescription)")
                result(FlutterError(
                    code: "EXPORT_TRACK_FAILED",
                    message: error.localizedDescription,
                    details: nil
                ))
            }
        }
    }
    
    private func exportTrackWithArtwork(trackId: String, result: @escaping FlutterResult) {
        Logger.debug("🎵 MediaBrowserPlugin (macOS): exportTrackWithArtwork called with trackId: \(trackId)")
        
        mediaExtractionService.exportTrackWithArtwork(trackId: trackId) { [weak self] extractionResult in
            switch extractionResult {
            case .success(let response):
                Logger.debug("🎵 MediaBrowserPlugin (macOS): exportTrackWithArtwork - success")
                result(response)
            case .failure(let error):
                Logger.debug("🎵 MediaBrowserPlugin (macOS): exportTrackWithArtwork - error: \(error.localizedDescription)")
                result(FlutterError(
                    code: "EXPORT_TRACK_WITH_ARTWORK_FAILED",
                    message: error.localizedDescription,
                    details: nil
                ))
            }
        }
    }
    
    private func extractArtwork(trackId: String, result: @escaping FlutterResult) {
        Logger.debug("🎵 MediaBrowserPlugin (macOS): extractArtwork called with trackId: \(trackId)")
        
        mediaExtractionService.extractArtwork(trackId: trackId) { [weak self] extractionResult in
            switch extractionResult {
            case .success(let response):
                Logger.debug("🎵 MediaBrowserPlugin (macOS): extractArtwork - success")
                result(response)
            case .failure(let error):
                Logger.debug("🎵 MediaBrowserPlugin (macOS): extractArtwork - error: \(error.localizedDescription)")
                result(FlutterError(
                    code: "EXTRACT_ARTWORK_FAILED",
                    message: error.localizedDescription,
                    details: nil
                ))
            }
        }
    }
    
    private func canExportTrack(result: @escaping FlutterResult) {
        Logger.debug("🎵 MediaBrowserPlugin (macOS): canExportTrack called")
        
        let canExport = mediaExtractionService.canExportTrack()
        Logger.debug("🎵 MediaBrowserPlugin (macOS): canExportTrack - result: \(canExport)")
        result(canExport)
    }
    
    private func getTrackExtension(trackPath: String, result: @escaping FlutterResult) {
        Logger.debug("🎵 MediaBrowserPlugin (macOS): getTrackExtension called with trackPath: \(trackPath)")
        
        let extractionResult = mediaExtractionService.getTrackExtension(trackPath: trackPath)
        switch extractionResult {
        case .success(let response):
            Logger.debug("🎵 MediaBrowserPlugin (macOS): getTrackExtension - success")
            result(response)
        case .failure(let error):
            Logger.debug("🎵 MediaBrowserPlugin (macOS): getTrackExtension - error: \(error.localizedDescription)")
            result(FlutterError(
                code: "GET_TRACK_EXTENSION_FAILED",
                message: error.localizedDescription,
                details: nil
            ))
        }
    }
}
