import Foundation
import MediaPlayer
import AVFoundation
import UIKit

// MARK: - How Other Apps (like mConnect) Actually Do It
// They use MPMusicPlayerController + AVAudioEngine or just read the asset data directly

class MediaExtractionService {
    
    // MARK: - Export Track (Working Method)
    func exportTrack(trackId: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        Logger.debug("🎵 MediaExtractionService: exportTrack called with trackId: \(trackId)")
        
        guard let trackIdUInt64 = UInt64(trackId) else {
            completion(.failure(MediaExtractionError.invalidTrackId("Invalid trackId format")))
            return
        }
        let trackIdNumber = NSNumber(value: trackIdUInt64)
        
        let query = MPMediaQuery.songs()
        let predicate = MPMediaPropertyPredicate(value: trackIdNumber, forProperty: MPMediaItemPropertyPersistentID)
        query.addFilterPredicate(predicate)
        
        guard let items = query.items, let track = items.first else {
            completion(.failure(MediaExtractionError.trackNotFound("Track not found")))
            return
        }
        
        Logger.debug("🎵 Found track: \(track.title ?? "Unknown")")
        
        guard let assetURL = track.assetURL else {
            completion(.failure(MediaExtractionError.noAssetURL("No asset URL")))
            return
        }
        
        // Get extension
        let urlExtension = assetURL.pathExtension.isEmpty ? "m4a" : assetURL.pathExtension
        let isMP3 = urlExtension.lowercased() == "mp3"
        
        // Create destination URL with unique timestamp
        let tempDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let timestamp = Date().timeIntervalSince1970
        let outputURL = tempDirectoryURL.appendingPathComponent("exported_\(trackId)_\(timestamp)").appendingPathExtension(urlExtension)
        
        Logger.debug("🎵 Output URL: \(outputURL.path)")
        Logger.debug("🎵 Is MP3: \(isMP3)")
        
        // Remove existing file
        try? FileManager.default.removeItem(at: outputURL)
        
        // Method 1: Try direct data reading (works for purchased/imported tracks)
        if let data = try? Data(contentsOf: assetURL) {
            Logger.debug("🎵 Method 1: Direct data read succeeded, size: \(data.count) bytes")
            do {
                try data.write(to: outputURL)
                let response: [String: Any] = ["success": true, "filePath": outputURL.path]
                completion(.success(response))
                return
            } catch {
                Logger.debug("🎵 Method 1: Failed to write data: \(error)")
            }
        }
        
        // Method 2: Use AVAsset + AVAssetExportSession (works for most tracks)
        Logger.debug("🎵 Method 2: Using AVAssetExportSession")
        let asset = AVURLAsset(url: assetURL)
        
        // For MP3, we need special handling
        if isMP3 {
            self.exportMP3Track(asset: asset, outputURL: outputURL, completion: completion)
            return
        }
        
        // Check if asset is exportable first
        asset.loadValuesAsynchronously(forKeys: ["exportable"]) {
            var error: NSError?
            let status = asset.statusOfValue(forKey: "exportable", error: &error)
            
            if status == .failed || error != nil {
                Logger.error("🎵 Failed to load exportable status: \(error?.localizedDescription ?? "unknown")")
                DispatchQueue.main.async {
                    completion(.failure(MediaExtractionError.exportFailed("Asset not exportable")))
                }
                return
            }
            
            if !asset.isExportable {
                Logger.error("🎵 Asset is not exportable (likely DRM protected)")
                DispatchQueue.main.async {
                    completion(.failure(MediaExtractionError.exportFailed("DRM protected track")))
                }
                return
            }
            
            // Create export session
            guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) else {
                Logger.error("🎵 Cannot create export session")
                DispatchQueue.main.async {
                    completion(.failure(MediaExtractionError.exportSessionFailed("Cannot create export session")))
                }
                return
            }
            
            exportSession.outputURL = outputURL
            exportSession.outputFileType = self.getOutputFileType(for: urlExtension)
            
            Logger.debug("🎵 Starting export with file type: \(exportSession.outputFileType?.rawValue ?? "unknown")")
            
            // Set timeout
            var hasCompleted = false
            let timeoutWork = DispatchWorkItem {
                if !hasCompleted {
                    Logger.error("🎵 Export timed out after 30 seconds")
                    exportSession.cancelExport()
                }
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + 30, execute: timeoutWork)
            
            exportSession.exportAsynchronously {
                hasCompleted = true
                timeoutWork.cancel()
                
                DispatchQueue.main.async {
                    Logger.debug("🎵 Export completed with status: \(exportSession.status.rawValue)")
                    
                    switch exportSession.status {
                    case .completed:
                        if FileManager.default.fileExists(atPath: outputURL.path) {
                            do {
                                let attrs = try FileManager.default.attributesOfItem(atPath: outputURL.path)
                                let size = attrs[.size] as? Int64 ?? 0
                                Logger.debug("🎵 Export successful, file size: \(size) bytes")
                                
                                if size > 0 {
                                    let response: [String: Any] = ["success": true, "filePath": outputURL.path]
                                    completion(.success(response))
                                } else {
                                    completion(.failure(MediaExtractionError.emptyFile("Exported file is empty")))
                                }
                            } catch {
                                completion(.failure(MediaExtractionError.fileCheckError(error.localizedDescription)))
                            }
                        } else {
                            completion(.failure(MediaExtractionError.fileNotFound("File not created")))
                        }
                        
                    case .failed:
                        let errorMsg = exportSession.error?.localizedDescription ?? "Export failed"
                        Logger.error("🎵 Export failed: \(errorMsg)")
                        completion(.failure(MediaExtractionError.exportFailed(errorMsg)))
                        
                    case .cancelled:
                        completion(.failure(MediaExtractionError.exportCancelled("Export cancelled")))
                        
                    default:
                        completion(.failure(MediaExtractionError.exportUnknown("Unknown status")))
                    }
                }
            }
        }
    }
    
    private func exportMP3Track(asset: AVURLAsset, outputURL: URL, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        Logger.debug("🎵 exportMP3Track: Starting MP3 export")
        
        // For MP3, export as MOV first, then extract the audio data
        let tempMOVURL = outputURL.deletingPathExtension().appendingPathExtension("mov")
        try? FileManager.default.removeItem(at: tempMOVURL)
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) else {
            Logger.error("🎵 exportMP3Track: Cannot create export session")
            completion(.failure(MediaExtractionError.exportSessionFailed("Cannot create export session")))
            return
        }
        
        exportSession.outputURL = tempMOVURL
        exportSession.outputFileType = .mov  // Use MOV container for MP3
        
        Logger.debug("🎵 exportMP3Track: Exporting to MOV container")
        
        var hasCompleted = false
        let timeoutWork = DispatchWorkItem {
            if !hasCompleted {
                Logger.error("🎵 exportMP3Track: Export timed out")
                exportSession.cancelExport()
            }
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + 30, execute: timeoutWork)
        
        exportSession.exportAsynchronously {
            hasCompleted = true
            timeoutWork.cancel()
            
            DispatchQueue.main.async {
                Logger.debug("🎵 exportMP3Track: Export status: \(exportSession.status.rawValue)")
                
                if exportSession.status == .completed {
                    // Extract MP3 from MOV container
                    do {
                        try self.extractMP3FromMOV(movURL: tempMOVURL, outputURL: outputURL)
                        
                        // Clean up temp file
                        try? FileManager.default.removeItem(at: tempMOVURL)
                        
                        Logger.debug("🎵 exportMP3Track: MP3 extraction successful")
                        let response: [String: Any] = ["success": true, "filePath": outputURL.path]
                        completion(.success(response))
                    } catch {
                        Logger.error("🎵 exportMP3Track: MP3 extraction failed: \(error)")
                        try? FileManager.default.removeItem(at: tempMOVURL)
                        completion(.failure(MediaExtractionError.exportFailed("MP3 extraction failed: \(error.localizedDescription)")))
                    }
                } else {
                    let errorMsg = exportSession.error?.localizedDescription ?? "Export failed"
                    Logger.error("🎵 exportMP3Track: Export failed: \(errorMsg)")
                    completion(.failure(MediaExtractionError.exportFailed(errorMsg)))
                }
            }
        }
    }
    
    private func extractMP3FromMOV(movURL: URL, outputURL: URL) throws {
        Logger.debug("🎵 extractMP3FromMOV: Extracting MP3 from MOV container")
        
        guard FileManager.default.fileExists(atPath: movURL.path) else {
            throw MediaExtractionError.fileNotFound("MOV file not found")
        }
        
        guard let inputHandle = FileHandle(forReadingAtPath: movURL.path) else {
            throw MediaExtractionError.fileCheckError("Cannot open MOV file")
        }
        
        defer { inputHandle.closeFile() }
        
        FileManager.default.createFile(atPath: outputURL.path, contents: nil, attributes: nil)
        guard let outputHandle = FileHandle(forWritingAtPath: outputURL.path) else {
            throw MediaExtractionError.fileCheckError("Cannot create output file")
        }
        
        defer { outputHandle.closeFile() }
        
        // Read QuickTime atoms to find mdat (media data)
        var foundMdat = false
        let bufferSize = 1024 * 100
        
        while true {
            let currentOffset = inputHandle.offsetInFile
            let fileSize = inputHandle.seekToEndOfFile()
            inputHandle.seek(toFileOffset: currentOffset)
            
            if currentOffset >= fileSize {
                break
            }
            
            // Read atom size (4 bytes)
            guard let sizeData = readBytes(from: inputHandle, count: 4), sizeData.count == 4 else {
                break
            }
            
            // Read atom name (4 bytes)
            guard let nameData = readBytes(from: inputHandle, count: 4), nameData.count == 4 else {
                break
            }
            
            let atomSize = UInt32(bigEndian: sizeData.withUnsafeBytes { $0.load(as: UInt32.self) })
            let atomName = String(data: nameData, encoding: .utf8) ?? ""
            
            Logger.debug("🎵 extractMP3FromMOV: Found atom '\(atomName)' with size \(atomSize)")
            
            if atomName == "mdat" {
                foundMdat = true
                var remainingBytes = Int(atomSize) - 8  // Subtract header size
                
                Logger.debug("🎵 extractMP3FromMOV: Extracting \(remainingBytes) bytes of audio data")
                
                while remainingBytes > 0 {
                    let chunkSize = min(bufferSize, remainingBytes)
                    guard let chunk = readBytes(from: inputHandle, count: chunkSize), !chunk.isEmpty else {
                        throw MediaExtractionError.fileCheckError("Unexpected end of file")
                    }
                    
                    outputHandle.write(chunk)
                    remainingBytes -= chunk.count
                }
                
                Logger.debug("🎵 extractMP3FromMOV: Extraction complete")
                break
            }
            
            if atomSize == 0 {
                break
            }
            
            let skipBytes = Int(atomSize) - 8
            if skipBytes > 0 {
                inputHandle.seek(toFileOffset: inputHandle.offsetInFile + UInt64(skipBytes))
            }
        }
        
        if !foundMdat {
            throw MediaExtractionError.fileCheckError("No audio data found in MOV")
        }
        
        // Verify output file
        let attrs = try FileManager.default.attributesOfItem(atPath: outputURL.path)
        let size = attrs[.size] as? Int64 ?? 0
        Logger.debug("🎵 extractMP3FromMOV: Output file size: \(size) bytes")
        
        if size == 0 {
            throw MediaExtractionError.emptyFile("Extracted file is empty")
        }
    }
    
    private func readBytes(from handle: FileHandle, count: Int) -> Data? {
        if #available(iOS 13.4, *) {
            return try? handle.read(upToCount: count)
        } else {
            let data = handle.readData(ofLength: count)
            return data.isEmpty ? nil : data
        }
    }
    
    private func getOutputFileType(for extension: String) -> AVFileType {
        switch `extension`.lowercased() {
        case "m4a": return .m4a
        case "wav": return .wav
        case "aif", "aiff": return .aiff
        case "caf": return .caf
        default: return .m4a
        }
    }
    
    // MARK: - Export Track with Artwork
    func exportTrackWithArtwork(trackId: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        guard let trackIdUInt64 = UInt64(trackId) else {
            completion(.failure(MediaExtractionError.invalidTrackId("Invalid trackId")))
            return
        }
        let trackIdNumber = NSNumber(value: trackIdUInt64)
        
        let query = MPMediaQuery.songs()
        let predicate = MPMediaPropertyPredicate(value: trackIdNumber, forProperty: MPMediaItemPropertyPersistentID)
        query.addFilterPredicate(predicate)
        
        guard let items = query.items, let track = items.first else {
            completion(.failure(MediaExtractionError.trackNotFound("Track not found")))
            return
        }
        
        guard let assetURL = track.assetURL else {
            completion(.failure(MediaExtractionError.noAssetURL("No asset URL")))
            return
        }
        
        let asset = AVAsset(url: assetURL)
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            completion(.failure(MediaExtractionError.exportSessionFailed("Cannot create export session")))
            return
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let timestamp = Date().timeIntervalSince1970
        let audioOutputURL = documentsPath.appendingPathComponent("exported_\(trackId)_\(timestamp).m4a")
        let artworkOutputURL = documentsPath.appendingPathComponent("artwork_\(trackId)_\(timestamp).jpg")
        
        try? FileManager.default.removeItem(at: audioOutputURL)
        try? FileManager.default.removeItem(at: artworkOutputURL)
        
        exportSession.outputURL = audioOutputURL
        exportSession.outputFileType = .m4a
        
        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                switch exportSession.status {
                case .completed:
                    if let artwork = track.artwork, 
                       let artworkImage = artwork.image(at: CGSize(width: 1000, height: 1000)),
                       let artworkData = artworkImage.jpegData(compressionQuality: 0.8) {
                        try? artworkData.write(to: artworkOutputURL)
                    }
                    
                    let response: [String: Any] = [
                        "success": true,
                        "audioFilePath": audioOutputURL.path,
                        "artworkFilePath": artworkOutputURL.path
                    ]
                    completion(.success(response))
                    
                case .failed:
                    completion(.failure(MediaExtractionError.exportFailed(exportSession.error?.localizedDescription ?? "Export failed")))
                case .cancelled:
                    completion(.failure(MediaExtractionError.exportCancelled("Export cancelled")))
                default:
                    completion(.failure(MediaExtractionError.exportUnknown("Unknown status")))
                }
            }
        }
    }
    
    // MARK: - Extract Artwork
    func extractArtwork(trackId: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        guard let trackIdUInt64 = UInt64(trackId) else {
            completion(.failure(MediaExtractionError.invalidTrackId("Invalid trackId")))
            return
        }
        let trackIdNumber = NSNumber(value: trackIdUInt64)
        
        let query = MPMediaQuery.songs()
        let predicate = MPMediaPropertyPredicate(value: trackIdNumber, forProperty: MPMediaItemPropertyPersistentID)
        query.addFilterPredicate(predicate)
        
        guard let items = query.items, let track = items.first else {
            completion(.failure(MediaExtractionError.trackNotFound("Track not found")))
            return
        }
        
        if let artwork = track.artwork, 
           let artworkImage = artwork.image(at: CGSize(width: 1000, height: 1000)) {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let timestamp = Date().timeIntervalSince1970
            let artworkOutputURL = documentsPath.appendingPathComponent("artwork_\(trackId)_\(timestamp).jpg")
            
            try? FileManager.default.removeItem(at: artworkOutputURL)
            
            if let artworkData = artworkImage.jpegData(compressionQuality: 0.8) {
                do {
                    try artworkData.write(to: artworkOutputURL)
                    let response: [String: Any] = ["success": true, "artworkPath": artworkOutputURL.path]
                    completion(.success(response))
                } catch {
                    completion(.failure(MediaExtractionError.artworkSaveFailed(error.localizedDescription)))
                }
            } else {
                completion(.failure(MediaExtractionError.artworkConversionFailed("Cannot convert to JPEG")))
            }
        } else {
            completion(.failure(MediaExtractionError.noArtwork("No artwork found")))
        }
    }
    
    func canExportTrack() -> Bool {
        return MPMediaLibrary.authorizationStatus() == .authorized
    }
    
    func getTrackExtension(trackPath: String) -> Result<[String: Any], Error> {
        if let assetURL = URL(string: trackPath) {
            let fileExtension = assetURL.pathExtension.lowercased()
            let response: [String: Any] = ["extension": fileExtension]
            return .success(response)
        } else {
            return .failure(MediaExtractionError.invalidURL("Invalid track path"))
        }
    }
}

// MARK: - Errors
enum MediaExtractionError: Error, LocalizedError {
    case invalidTrackId(String)
    case trackNotFound(String)
    case noAssetURL(String)
    case emptyFile(String)
    case fileCheckError(String)
    case fileNotFound(String)
    case exportFailed(String)
    case importError(String)
    case exportSessionFailed(String)
    case exportCancelled(String)
    case exportUnknown(String)
    case artworkSaveFailed(String)
    case artworkConversionFailed(String)
    case noArtwork(String)
    case invalidURL(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidTrackId(let msg): return "Invalid Track ID: \(msg)"
        case .trackNotFound(let msg): return "Track Not Found: \(msg)"
        case .noAssetURL(let msg): return "No Asset URL: \(msg)"
        case .emptyFile(let msg): return "Empty File: \(msg)"
        case .fileCheckError(let msg): return "File Check Error: \(msg)"
        case .fileNotFound(let msg): return "File Not Found: \(msg)"
        case .exportFailed(let msg): return "Export Failed: \(msg)"
        case .importError(let msg): return "Import Error: \(msg)"
        case .exportSessionFailed(let msg): return "Export Session Failed: \(msg)"
        case .exportCancelled(let msg): return "Export Cancelled: \(msg)"
        case .exportUnknown(let msg): return "Export Unknown: \(msg)"
        case .artworkSaveFailed(let msg): return "Artwork Save Failed: \(msg)"
        case .artworkConversionFailed(let msg): return "Artwork Conversion Failed: \(msg)"
        case .noArtwork(let msg): return "No Artwork: \(msg)"
        case .invalidURL(let msg): return "Invalid URL: \(msg)"
        }
    }
}