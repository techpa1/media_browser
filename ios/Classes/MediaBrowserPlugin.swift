import Flutter
import UIKit
import MediaPlayer
import AVFoundation
import Photos
import Foundation
import Combine

public class MediaBrowserPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private let mediaBrowserService = MediaBrowserService()
    private let mediaExtractionService = MediaExtractionService()
    
    // Timeout configurations
    private let defaultTimeout: TimeInterval = 30.0 // 30 seconds
    private let shortTimeout: TimeInterval = 10.0 // 10 seconds
    private let longTimeout: TimeInterval = 60.0 // 60 seconds
    
    // Permission monitoring
    private var eventChannel: FlutterEventChannel?
    private var eventSink: FlutterEventSink?
    private var permissionTimer: Timer?
    private var lastAudioPermissionStatus: MPMediaLibraryAuthorizationStatus = .notDetermined
    private var lastVideoPermissionStatus: PHAuthorizationStatus = .notDetermined
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "media_browser", binaryMessenger: registrar.messenger())
        let instance = MediaBrowserPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        
        // Set up event channel for permission change notifications
        instance.eventChannel = FlutterEventChannel(name: "media_browser/permission_changes", binaryMessenger: registrar.messenger())
        instance.eventChannel?.setStreamHandler(instance)
        
        // Initialize permission status tracking
        instance.initializePermissionTracking()
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        Logger.debug("📱 iOS Plugin: Received method call: \(call.method)")
        Logger.debug("📱 iOS Plugin: Arguments: \(call.arguments ?? "nil")")
        
        switch call.method {
        case "getPlatformVersion":
            Logger.debug("📱 iOS Plugin: Handling getPlatformVersion")
            result("iOS " + UIDevice.current.systemVersion)
        case "checkPermissions":
            Logger.debug("📱 iOS Plugin: Handling checkPermissions")
            let mediaType = call.arguments as? [String: Any]
            let type = mediaType?["mediaType"] as? String ?? "all"
            Logger.debug("📱 iOS Plugin: Media type: \(type)")
            checkPermissions(mediaType: type, result: result)
        case "requestPermissions":
            Logger.debug("📱 iOS Plugin: Handling requestPermissions")
            let mediaType = call.arguments as? [String: Any]
            let type = mediaType?["mediaType"] as? String ?? "all"
            Logger.debug("📱 iOS Plugin: Media type: \(type)")
            requestPermissions(mediaType: type, result: result)
        case "queryAudios":
            let options = call.arguments as? [String: Any]
            queryAudios(options: options, result: result)
        case "queryAudiosFromAlbum":
            let args = call.arguments as? [String: Any]
            let albumId = args?["albumId"] as? Int ?? 0
            let options = args?["options"] as? [String: Any]
            queryAudiosFromAlbum(albumId: albumId, options: options, result: result)
        case "queryAudiosFromArtist":
            let args = call.arguments as? [String: Any]
            let artistId = args?["artistId"] as? Int ?? 0
            let options = args?["options"] as? [String: Any]
            queryAudiosFromArtist(artistId: artistId, options: options, result: result)
        case "queryAudiosFromGenre":
            let args = call.arguments as? [String: Any]
            let genreId = args?["genreId"] as? Int ?? 0
            let options = args?["options"] as? [String: Any]
            queryAudiosFromGenre(genreId: genreId, options: options, result: result)
        case "queryAudiosFromPath":
            let args = call.arguments as? [String: Any]
            let path = args?["path"] as? String ?? ""
            let options = args?["options"] as? [String: Any]
            queryAudiosFromPath(path: path, options: options, result: result)
        case "queryVideos":
            let options = call.arguments as? [String: Any]
            queryVideos(options: options, result: result)
        case "queryVideosFromPath":
            let args = call.arguments as? [String: Any]
            let path = args?["path"] as? String ?? ""
            let options = args?["options"] as? [String: Any]
            queryVideosFromPath(path: path, options: options, result: result)
        case "queryDocuments":
            let options = call.arguments as? [String: Any]
            queryDocuments(options: options, result: result)
        case "queryDocumentsFromPath":
            let args = call.arguments as? [String: Any]
            let path = args?["path"] as? String ?? ""
            let options = args?["options"] as? [String: Any]
            queryDocumentsFromPath(path: path, options: options, result: result)
        case "queryFolders":
            let options = call.arguments as? [String: Any]
            queryFolders(options: options, result: result)
        case "queryFoldersFromPath":
            let args = call.arguments as? [String: Any]
            let path = args?["path"] as? String ?? ""
            let options = args?["options"] as? [String: Any]
            let browsingMode = args?["browsingMode"] as? String ?? "all"
            queryFoldersFromPath(path: path, options: options, browsingMode: browsingMode, result: result)
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
        case "debugArtworkAvailability":
            debugArtworkAvailability(result: result)
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
        // Permission checks must happen on the main thread for iOS
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            var missingPermissions: [[String: Any]] = []
            var allGranted = true
            
            switch mediaType {
            case "audio", "MediaType.audio":
                let audioStatus = MPMediaLibrary.authorizationStatus()
                Logger.debug("🎵 Audio permission status: \(audioStatus.rawValue) (\(audioStatus))")
                Logger.debug("🎵 Audio permission is authorized: \(audioStatus == .authorized)")
                // Only consider it granted if it's explicitly authorized
                if audioStatus != .authorized {
                    allGranted = false
                    let permissionState = self.getDetailedPermissionState(audioStatus)
                    Logger.debug("🎵 Audio permission missing, adding to missingPermissions")
                    missingPermissions.append([
                        "name": "NSAppleMusicUsageDescription",
                        "description": "Access to music library",
                        "isRequired": true,
                        "type": "audio",
                        "status": permissionState["status"] as! String,
                        "canRequest": permissionState["canRequest"] as! Bool,
                        "shouldShowRationale": permissionState["shouldShowRationale"] as! Bool
                    ])
                } else {
                    Logger.debug("🎵 Audio permission is granted")
                }
                case "video", "MediaType.video":
                    let videoStatus = PHPhotoLibrary.authorizationStatus()
                    Logger.debug("🎥 Video permission status: \(videoStatus.rawValue) (\(videoStatus))")
                    Logger.debug("🎥 Video permission is authorized: \(videoStatus == .authorized)")
                    // Only consider it granted if it's explicitly authorized 
                    if videoStatus != .authorized {
                        allGranted = false
                        let permissionState = self.getDetailedPermissionState(videoStatus)
                        Logger.debug("🎥 Video permission missing, adding to missingPermissions")
                        missingPermissions.append([
                            "name": "NSPhotoLibraryUsageDescription",
                            "description": "Access to photo and video library",
                            "isRequired": true,
                            "type": "video",
                            "status": permissionState["status"] as! String,
                            "canRequest": permissionState["canRequest"] as! Bool,
                            "shouldShowRationale": permissionState["shouldShowRationale"] as! Bool
                        ])
                    } else {
                        Logger.debug("🎥 Video permission is granted")
                    }
                case "document", "MediaType.document":
                    // Documents don't require special permissions on iOS
                    // They can be accessed through the app's sandbox
                    break
                case "folder", "MediaType.folder":
                    // Folders don't require special permissions on iOS
                    // They can be accessed through the app's sandbox
                    break
                case "all":
                    let audioStatus = MPMediaLibrary.authorizationStatus()
                    let videoStatus = PHPhotoLibrary.authorizationStatus()
                    
                    // Only consider it granted if it's explicitly authorized
                    if audioStatus != .authorized {
                        allGranted = false
                        let permissionState = self.getDetailedPermissionState(audioStatus)
                        missingPermissions.append([
                            "name": "NSAppleMusicUsageDescription",
                            "description": "Access to music library",
                            "isRequired": true,
                            "type": "audio",
                            "status": permissionState["status"] as! String,
                            "canRequest": permissionState["canRequest"] as! Bool,
                            "shouldShowRationale": permissionState["shouldShowRationale"] as! Bool
                        ])
                    }
                    if videoStatus != .authorized{
                        allGranted = false
                        let permissionState = self.getDetailedPermissionState(videoStatus)
                        missingPermissions.append([
                            "name": "NSPhotoLibraryUsageDescription",
                            "description": "Access to photo and video library",
                            "isRequired": false,
                            "type": "video",
                            "status": permissionState["status"] as! String,
                            "canRequest": permissionState["canRequest"] as! Bool,
                            "shouldShowRationale": permissionState["shouldShowRationale"] as! Bool
                        ])
                    }
                default:
                    break
                }
                
            let status = allGranted ? "granted" : "denied"
            let message = allGranted ? "All permissions granted" : "Missing required permissions"
            
            Logger.debug("🔐 Final permission check result for \(mediaType):")
            Logger.debug("🔐 Status: \(status)")
            Logger.debug("🔐 Message: \(message)")
            Logger.debug("🔐 Missing permissions count: \(missingPermissions.count)")
            Logger.debug("🔐 All granted: \(allGranted)")
            
            result([
                "status": status,
                "message": message,
                "missingPermissions": missingPermissions
            ])
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
                        "description": "Access to photo and video library",
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
            // Documents don't require special permissions on iOS
            result([
                "status": "granted",
                "message": "Document access granted (no special permissions required)",
                "missingPermissions": []
            ])
        case "folder", "MediaType.folder":
            // Folders don't require special permissions on iOS
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
                            let permissionState = self.getDetailedPermissionState(musicStatus)
                            missingPermissions.append([
                                "name": "NSAppleMusicUsageDescription",
                                "description": "Access to music library",
                                "isRequired": true,
                                "type": "audio",
                                "status": permissionState["status"] as! String,
                                "canRequest": permissionState["canRequest"] as! Bool,
                                "shouldShowRationale": permissionState["shouldShowRationale"] as! Bool
                            ])
                        }
                        if !photoGranted {
                            let permissionState = self.getDetailedPermissionState(photoStatus)
                            missingPermissions.append([
                                "name": "NSPhotoLibraryUsageDescription",
                                "description": "Access to photo and video library",
                                "isRequired": false,
                                "type": "video",
                                "status": permissionState["status"] as! String,
                                "canRequest": permissionState["canRequest"] as! Bool,
                                "shouldShowRationale": permissionState["shouldShowRationale"] as! Bool
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
            do {
                let audios = try self.mediaBrowserService.queryAudios(options: options)
                DispatchQueue.main.async { result(audios) }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "QUERY_AUDIO_FAILED", message: "Failed to query audio files: \(error.localizedDescription)", details: nil))
                }
            }
        }
    }
    
    private func queryAudiosFromAlbum(albumId: Int, options: [String: Any]?, result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                let audios = try self.mediaBrowserService.queryAudiosFromAlbum(albumId: albumId, options: options)
                DispatchQueue.main.async { result(audios) }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "QUERY_AUDIO_FROM_ALBUM_FAILED", message: "Failed to query audio files from album: \(error.localizedDescription)", details: nil))
                }
            }
        }
    }
    
    private func queryAudiosFromArtist(artistId: Int, options: [String: Any]?, result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                let audios = try self.mediaBrowserService.queryAudiosFromArtist(artistId: artistId, options: options)
                DispatchQueue.main.async { result(audios) }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "QUERY_AUDIO_FROM_ARTIST_FAILED", message: "Failed to query audio files from artist: \(error.localizedDescription)", details: nil))
                }
            }
        }
    }
    
    private func queryAudiosFromGenre(genreId: Int, options: [String: Any]?, result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                let audios = try self.mediaBrowserService.queryAudiosFromGenre(genreId: genreId, options: options)
                DispatchQueue.main.async { result(audios) }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "QUERY_AUDIO_FROM_GENRE_FAILED", message: "Failed to query audio files from genre: \(error.localizedDescription)", details: nil))
                }
            }
        }
    }
    
    private func queryAudiosFromPath(path: String, options: [String: Any]?, result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                let audios = try self.mediaBrowserService.queryAudiosFromPath(path: path, options: options)
                DispatchQueue.main.async { result(audios) }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "QUERY_AUDIO_FROM_PATH_FAILED", message: "Failed to query audio files from path: \(error.localizedDescription)", details: nil))
                }
            }
        }
    }
    
    private func queryVideos(options: [String: Any]?, result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                let videos = try self.mediaBrowserService.queryVideos(options: options)
                DispatchQueue.main.async { result(videos) }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "QUERY_VIDEO_FAILED", message: "Failed to query video files: \(error.localizedDescription)", details: nil))
                }
            }
        }
    }
    
    private func queryVideosFromPath(path: String, options: [String: Any]?, result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                let videos = try self.mediaBrowserService.queryVideosFromPath(path: path, options: options)
                DispatchQueue.main.async { result(videos) }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "QUERY_VIDEO_FROM_PATH_FAILED", message: "Failed to query video files from path: \(error.localizedDescription)", details: nil))
                }
            }
        }
    }
    
    private func queryDocuments(options: [String: Any]?, result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                let documents = try self.mediaBrowserService.queryDocuments(options: options)
                DispatchQueue.main.async { result(documents) }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "QUERY_DOCUMENT_FAILED", message: "Failed to query document files: \(error.localizedDescription)", details: nil))
                }
            }
        }
    }
    
    private func queryDocumentsFromPath(path: String, options: [String: Any]?, result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                let documents = try self.mediaBrowserService.queryDocumentsFromPath(path: path, options: options)
                DispatchQueue.main.async { result(documents) }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "QUERY_DOCUMENT_FROM_PATH_FAILED", message: "Failed to query document files from path: \(error.localizedDescription)", details: nil))
                }
            }
        }
    }
    
    private func queryFolders(options: [String: Any]?, result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                let folders = try self.mediaBrowserService.queryFolders(options: options)
                DispatchQueue.main.async { result(folders) }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "QUERY_FOLDER_FAILED", message: "Failed to query folders: \(error.localizedDescription)", details: nil))
                }
            }
        }
    }
    
    private func queryFoldersFromPath(path: String, options: [String: Any]?, browsingMode: String, result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                let folders = try self.mediaBrowserService.queryFoldersFromPath(path: path, options: options, browsingMode: browsingMode)
                DispatchQueue.main.async { result(folders) }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "QUERY_FOLDER_FROM_PATH_FAILED", message: "Failed to query folders from path: \(error.localizedDescription)", details: nil))
                }
            }
        }
    }
    
    private func queryAlbums(options: [String: Any]?, result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                let albums = try self.mediaBrowserService.queryAlbums(options: options)
                DispatchQueue.main.async { result(albums) }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "QUERY_ALBUM_FAILED", message: "Failed to query albums: \(error.localizedDescription)", details: nil))
                }
            }
        }
    }
    
    private func queryArtists(options: [String: Any]?, result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                let artists = try self.mediaBrowserService.queryArtists(options: options)
                DispatchQueue.main.async { result(artists) }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "QUERY_ARTIST_FAILED", message: "Failed to query artists: \(error.localizedDescription)", details: nil))
                }
            }
        }
    }
    
    private func queryGenres(options: [String: Any]?, result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                let genres = try self.mediaBrowserService.queryGenres(options: options)
                DispatchQueue.main.async { result(genres) }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "QUERY_GENRE_FAILED", message: "Failed to query genres: \(error.localizedDescription)", details: nil))
                }
            }
        }
    }
    
    private func queryArtwork(id: Int, type: String, size: String, result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                let artwork = try self.mediaBrowserService.queryArtwork(id: id, type: type, size: size)
                DispatchQueue.main.async { result(artwork) }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "QUERY_ARTWORK_FAILED", message: "Failed to query artwork: \(error.localizedDescription)", details: nil))
                }
            }
        }
    }
    
    private func clearCachedArtworks(result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                try self.mediaBrowserService.clearCachedArtworks()
                DispatchQueue.main.async { result(nil) }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "CLEAR_CACHE_FAILED", message: "Failed to clear cached artworks: \(error.localizedDescription)", details: nil))
                }
            }
        }
    }
    
    private func scanMedia(path: String, result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                try self.mediaBrowserService.scanMedia(path: path)
                DispatchQueue.main.async { result(nil) }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "SCAN_MEDIA_FAILED", message: "Failed to scan media: \(error.localizedDescription)", details: nil))
                }
            }
        }
    }
    
    private func getDeviceInfo(result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .utility).async {
            let deviceInfo: [String: Any] = [
                "platform": "iOS",
                "version": UIDevice.current.systemVersion,
                "model": UIDevice.current.model,
                "name": UIDevice.current.name,
                "systemName": UIDevice.current.systemName,
                "identifierForVendor": UIDevice.current.identifierForVendor?.uuidString ?? ""
            ]
            DispatchQueue.main.async { result(deviceInfo) }
        }
    }
    
    private func debugArtworkAvailability(result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                let debugInfo = try self.mediaBrowserService.debugArtworkAvailability()
                DispatchQueue.main.async { result(debugInfo) }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "DEBUG_ARTWORK_FAILED", message: "Failed to debug artwork availability: \(error.localizedDescription)", details: nil))
                }
            }
        }
    }
    
    // MARK: - Permission Monitoring
    
    private func initializePermissionTracking() {
        // Initialize with current permission statuses
        lastAudioPermissionStatus = MPMediaLibrary.authorizationStatus()
        lastVideoPermissionStatus = PHPhotoLibrary.authorizationStatus()
        
        Logger.debug("🔐 iOS: Initialized permission tracking - Audio: \(lastAudioPermissionStatus.rawValue), Video: \(lastVideoPermissionStatus.rawValue)")
    }
    
    private func startPermissionMonitoring() {
        stopPermissionMonitoring() // Stop any existing timer
        
        // Use a longer interval to reduce battery impact
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkPermissionChanges()
        }
        
        Logger.debug("🔐 iOS: Started permission monitoring with 5-second interval")
    }
    
    private func stopPermissionMonitoring() {
        permissionTimer?.invalidate()
        permissionTimer = nil
        Logger.debug("🔐 iOS: Stopped permission monitoring")
    }
    
    private func checkPermissionChanges() {
        let currentAudioStatus = MPMediaLibrary.authorizationStatus()
        let currentVideoStatus = PHPhotoLibrary.authorizationStatus()
        
        var hasChanges = false
        var changes: [String: Any] = [:]
        
        // Check audio permission changes
        if currentAudioStatus != lastAudioPermissionStatus {
            hasChanges = true
            changes["audio"] = [
                "previous": permissionStatusToString(lastAudioPermissionStatus),
                "current": permissionStatusToString(currentAudioStatus),
                "granted": currentAudioStatus == .authorized,
                "denied": currentAudioStatus == .denied || currentAudioStatus == .restricted
            ]
            
            Logger.debug("🔐 iOS: Audio permission changed from \(lastAudioPermissionStatus.rawValue) to \(currentAudioStatus.rawValue)")
            lastAudioPermissionStatus = currentAudioStatus
        }
        
        // Check video permission changes
        if currentVideoStatus != lastVideoPermissionStatus {
            hasChanges = true
            changes["video"] = [
                "previous": photoPermissionStatusToString(lastVideoPermissionStatus),
                "current": photoPermissionStatusToString(currentVideoStatus),
                "granted": currentVideoStatus == .authorized,
                "denied": currentVideoStatus == .denied || currentVideoStatus == .restricted
            ]
            
            Logger.debug("🔐 iOS: Video permission changed from \(lastVideoPermissionStatus.rawValue) to \(currentVideoStatus.rawValue)")
            lastVideoPermissionStatus = currentVideoStatus
        }
        
        // Send notification if there are changes
        if hasChanges {
            // Determine affected media types
            var affectedMediaTypes: [String] = []
            
            if changes["audio"] != nil {
                affectedMediaTypes.append("audio")
            }
            if changes["video"] != nil {
                affectedMediaTypes.append("video")
            }
            
            // Note: iOS doesn't have separate document/folder permissions
            // Documents and folders are handled through the same permissions as audio/video
            // If audio permission changes, it affects documents/folders too
            if changes["audio"] != nil {
                if !affectedMediaTypes.contains("document") {
                    affectedMediaTypes.append("document")
                }
                if !affectedMediaTypes.contains("folder") {
                    affectedMediaTypes.append("folder")
                }
            }
            
            let event: [String: Any] = [
                "type": "permission_changed",
                "timestamp": Int(Date().timeIntervalSince1970 * 1000),
                "changes": changes,
                "affectedMediaTypes": affectedMediaTypes
            ]
            
            sendPermissionChangeEvent(event)
        }
    }
    
    private func sendPermissionChangeEvent(_ event: [String: Any]) {
        guard let eventSink = eventSink else {
            Logger.debug("🔐 iOS: No event sink available to send permission change")
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.eventSink?(event)
            Logger.debug("🔐 iOS: Sent permission change event: \(event)")
        }
    }
    
    private func permissionStatusToString(_ status: MPMediaLibraryAuthorizationStatus) -> String {
        switch status {
        case .notDetermined:
            return "notDetermined"
        case .denied:
            return "denied"
        case .restricted:
            return "restricted"
        case .authorized:
            return "authorized"
        @unknown default:
            return "unknown"
        }
    }
    
    private func getDetailedPermissionState(_ status: MPMediaLibraryAuthorizationStatus) -> [String: Any] {
        switch status {
        case .authorized:
            return [
                "status": "granted",
                "canRequest": false,
                "shouldShowRationale": false
            ]
        case .denied:
            // iOS: Once denied, cannot request again, must go to settings
            return [
                "status": "permanently_denied",
                "canRequest": false,
                "shouldShowRationale": false
            ]
        case .restricted:
            return [
                "status": "permanently_denied",
                "canRequest": false,
                "shouldShowRationale": false
            ]
        case .notDetermined:
            // iOS: notDetermined can be requested, but no dialog needed (OS handles it)
            return [
                "status": "notDetermined",
                "canRequest": true,
                "shouldShowRationale": false
            ]
        @unknown default:
            return [
                "status": "denied",
                "canRequest": false,
                "shouldShowRationale": false
            ]
        }
    }
    
    private func getDetailedPermissionState(_ status: PHAuthorizationStatus) -> [String: Any] {
        switch status {
        case .authorized, .limited:
            return [
                "status": "granted",
                "canRequest": false,
                "shouldShowRationale": false
            ]
        case .denied:
            // iOS: Once denied, cannot request again, must go to settings
            return [
                "status": "permanently_denied",
                "canRequest": false,
                "shouldShowRationale": false
            ]
        case .restricted:
            return [
                "status": "permanently_denied",
                "canRequest": false,
                "shouldShowRationale": false
            ]
        case .notDetermined:
            // iOS: notDetermined can be requested, but no dialog needed (OS handles it)
            return [
                "status": "notDetermined",
                "canRequest": true,
                "shouldShowRationale": false
            ]
        @unknown default:
            return [
                "status": "denied",
                "canRequest": false,
                "shouldShowRationale": false
            ]
        }
    }
    
    private func photoPermissionStatusToString(_ status: PHAuthorizationStatus) -> String {
        switch status {
        case .notDetermined:
            return "notDetermined"
        case .restricted:
            return "restricted"
        case .denied:
            return "denied"
        case .authorized:
            return "authorized"
        case .limited:
            return "limited"
        @unknown default:
            return "unknown"
        }
    }
    
    // MARK: - Media Extraction Methods
    
    private func exportTrack(trackId: String, result: @escaping FlutterResult) {
        Logger.debug("🎵 MediaBrowserPlugin: exportTrack called with trackId: \(trackId)")
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            self.mediaExtractionService.exportTrack(trackId: trackId) { extractionResult in
                DispatchQueue.main.async {
                    switch extractionResult {
                    case .success(let response):
                        Logger.debug("🎵 MediaBrowserPlugin: exportTrack - success")
                        result(response)
                    case .failure(let error):
                        Logger.debug("🎵 MediaBrowserPlugin: exportTrack - error: \(error.localizedDescription)")
                        result(FlutterError(
                            code: "EXPORT_TRACK_FAILED",
                            message: error.localizedDescription,
                            details: nil
                        ))
                    }
                }
            }
        }
    }
    
    private func exportTrackWithArtwork(trackId: String, result: @escaping FlutterResult) {
        Logger.debug("🎵 MediaBrowserPlugin: exportTrackWithArtwork called with trackId: \(trackId)")
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            self.mediaExtractionService.exportTrackWithArtwork(trackId: trackId) { extractionResult in
                DispatchQueue.main.async {
                    switch extractionResult {
                    case .success(let response):
                        Logger.debug("🎵 MediaBrowserPlugin: exportTrackWithArtwork - success")
                        result(response)
                    case .failure(let error):
                        Logger.debug("🎵 MediaBrowserPlugin: exportTrackWithArtwork - error: \(error.localizedDescription)")
                        result(FlutterError(
                            code: "EXPORT_TRACK_WITH_ARTWORK_FAILED",
                            message: error.localizedDescription,
                            details: nil
                        ))
                    }
                }
            }
        }
    }
    
    private func extractArtwork(trackId: String, result: @escaping FlutterResult) {
        Logger.debug("🎵 MediaBrowserPlugin: extractArtwork called with trackId: \(trackId)")
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            self.mediaExtractionService.extractArtwork(trackId: trackId) { extractionResult in
                DispatchQueue.main.async {
                    switch extractionResult {
                    case .success(let response):
                        Logger.debug("🎵 MediaBrowserPlugin: extractArtwork - success")
                        result(response)
                    case .failure(let error):
                        Logger.debug("🎵 MediaBrowserPlugin: extractArtwork - error: \(error.localizedDescription)")
                        result(FlutterError(
                            code: "EXTRACT_ARTWORK_FAILED",
                            message: error.localizedDescription,
                            details: nil
                        ))
                    }
                }
            }
        }
    }
    
    private func canExportTrack(result: @escaping FlutterResult) {
        Logger.debug("🎵 MediaBrowserPlugin: canExportTrack called")
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let canExport = self.mediaExtractionService.canExportTrack()
            Logger.debug("🎵 MediaBrowserPlugin: canExportTrack - result: \(canExport)")
            DispatchQueue.main.async { result(canExport) }
        }
    }
    
    private func getTrackExtension(trackPath: String, result: @escaping FlutterResult) {
        Logger.debug("🎵 MediaBrowserPlugin: getTrackExtension called with trackPath: \(trackPath)")
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let extractionResult = self.mediaExtractionService.getTrackExtension(trackPath: trackPath)
            DispatchQueue.main.async {
                switch extractionResult {
                case .success(let response):
                    Logger.debug("🎵 MediaBrowserPlugin: getTrackExtension - success")
                    result(response)
                case .failure(let error):
                    Logger.debug("🎵 MediaBrowserPlugin: getTrackExtension - error: \(error.localizedDescription)")
                    result(FlutterError(
                        code: "GET_TRACK_EXTENSION_FAILED",
                        message: error.localizedDescription,
                        details: nil
                    ))
                }
            }
        }
    }
    
    // MARK: - FlutterStreamHandler
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        Logger.debug("🔐 iOS: Permission change listener started")
        self.eventSink = events
        startPermissionMonitoring()
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        Logger.debug("🔐 iOS: Permission change listener cancelled")
        self.eventSink = nil
        stopPermissionMonitoring()
        return nil
    }
}
