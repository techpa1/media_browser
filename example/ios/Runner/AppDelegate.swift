import Flutter
import UIKit
import MediaPlayer
import Photos

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    #if DEBUG
    print("📱 AppDelegate: application didFinishLaunchingWithOptions called")
    #endif
    
    GeneratedPluginRegistrant.register(with: self)
    
    #if DEBUG
    print("📱 AppDelegate: GeneratedPluginRegistrant.register completed")
    #endif
    
    // Register custom media permission plugin
    if let controller = window?.rootViewController as? FlutterViewController {
      #if DEBUG
      print("📱 AppDelegate: Found FlutterViewController, setting up permission channel")
      #endif
      
      let mediaPermissionChannel = FlutterMethodChannel(name: "media_browser_permissions", binaryMessenger: controller.binaryMessenger)
      
      #if DEBUG
      print("📱 AppDelegate: Created permission channel: media_browser_permissions")
      #endif
      
      mediaPermissionChannel.setMethodCallHandler { (call, result) in
        #if DEBUG
        print("📱 AppDelegate: Received method call: \(call.method)")
        print("📱 AppDelegate: Arguments: \(call.arguments ?? "nil")")
        #endif
        
        switch call.method {
        case "requestPermissions":
          self.requestMediaPermissions(call: call, result: result)
        case "checkPermissions":
          self.checkMediaPermissions(call: call, result: result)
        case "getPlatformVersion":
          result("iOS " + UIDevice.current.systemVersion)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
      
      #if DEBUG
      print("📱 AppDelegate: Permission channel setup completed")
      #endif
    } else {
      #if DEBUG
      print("📱 AppDelegate: ERROR - FlutterViewController not found!")
      #endif
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func requestMediaPermissions(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
      return
    }
    
    // Handle both string and enum values
    let mediaType: String
    if let mediaTypeString = args["mediaType"] as? String {
      // Check if it's an enum string like "MediaType.audio"
      if mediaTypeString.hasPrefix("MediaType.") {
        let enumValue = String(mediaTypeString.dropFirst("MediaType.".count))
        mediaType = enumValue
      } else {
        mediaType = mediaTypeString
      }
    } else if let mediaTypeEnum = args["mediaType"] {
      // Convert enum to string (e.g., "MediaType.audio" -> "audio")
      let enumString = String(describing: mediaTypeEnum)
      if enumString.contains("audio") {
        mediaType = "audio"
      } else if enumString.contains("video") {
        mediaType = "video"
      } else if enumString.contains("document") {
        mediaType = "document"
      } else if enumString.contains("folder") {
        mediaType = "folder"
      } else if enumString.contains("all") {
        mediaType = "all"
      } else {
        result(FlutterError(code: "UNSUPPORTED_MEDIA_TYPE", message: "Unsupported media type: \(enumString)", details: nil))
        return
      }
    } else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "MediaType not found in arguments", details: nil))
      return
    }
    
    #if DEBUG
    print("📱 AppDelegate: requestMediaPermissions called for type: \(mediaType)")
    #endif
    
    switch mediaType {
    case "audio":
      requestMusicPermission(result: result)
    case "video":
      requestPhotoPermission(result: result)
    case "document", "folder":
      // Documents and folders don't require special permissions on iOS
      result([
        "status": "granted",
        "message": "Document/Folder access granted (no special permissions required)",
        "missingPermissions": []
      ])
    case "all":
      requestAllPermissions(result: result)
    default:
      result(FlutterError(code: "UNSUPPORTED_MEDIA_TYPE", message: "Unsupported media type: \(mediaType)", details: nil))
    }
  }
  
  private func checkMediaPermissions(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
      return
    }
    
    // Handle both string and enum values
    let mediaType: String
    if let mediaTypeString = args["mediaType"] as? String {
      // Check if it's an enum string like "MediaType.audio"
      if mediaTypeString.hasPrefix("MediaType.") {
        let enumValue = String(mediaTypeString.dropFirst("MediaType.".count))
        mediaType = enumValue
      } else {
        mediaType = mediaTypeString
      }
    } else if let mediaTypeEnum = args["mediaType"] {
      // Convert enum to string (e.g., "MediaType.audio" -> "audio")
      let enumString = String(describing: mediaTypeEnum)
      if enumString.contains("audio") {
        mediaType = "audio"
      } else if enumString.contains("video") {
        mediaType = "video"
      } else if enumString.contains("document") {
        mediaType = "document"
      } else if enumString.contains("folder") {
        mediaType = "folder"
      } else if enumString.contains("all") {
        mediaType = "all"
      } else {
        result(FlutterError(code: "UNSUPPORTED_MEDIA_TYPE", message: "Unsupported media type: \(enumString)", details: nil))
        return
      }
    } else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "MediaType not found in arguments", details: nil))
      return
    }
    
    #if DEBUG
    print("📱 AppDelegate: checkMediaPermissions called for type: \(mediaType)")
    #endif
    
    switch mediaType {
    case "audio":
      checkMusicPermission(result: result)
    case "video":
      checkPhotoPermission(result: result)
    case "document", "folder":
      // Documents and folders don't require special permissions on iOS
      result([
        "status": "granted",
        "message": "Document/Folder access granted (no special permissions required)",
        "missingPermissions": []
      ])
    case "all":
      checkAllPermissions(result: result)
    default:
      result(FlutterError(code: "UNSUPPORTED_MEDIA_TYPE", message: "Unsupported media type: \(mediaType)", details: nil))
    }
  }
  
  private func requestMusicPermission(result: @escaping FlutterResult) {
    #if DEBUG
    print("🎵 AppDelegate: requestMusicPermission called")
    #endif
    
    if #available(iOS 9.3, *) {
      #if DEBUG
      print("🎵 AppDelegate: Calling MPMediaLibrary.requestAuthorization...")
      #endif
      
      MPMediaLibrary.requestAuthorization { status in
        #if DEBUG
        print("🎵 AppDelegate: MPMediaLibrary.requestAuthorization callback received with status: \(status.rawValue)")
        #endif
        
        DispatchQueue.main.async {
          switch status {
          case .authorized:
            #if DEBUG
            print("🎵 AppDelegate: Music permission granted")
            #endif
            result([
              "status": "granted",
              "message": "Music library access granted",
              "missingPermissions": []
            ])
          case .denied, .restricted, .notDetermined:
            #if DEBUG
            print("🎵 AppDelegate: Music permission denied/restricted/notDetermined")
            #endif
            result([
              "status": "denied",
              "message": "Music library access denied",
              "missingPermissions": [[
                "name": "NSAppleMusicUsageDescription",
                "description": "Access to music library",
                "isRequired": true,
                "type": "audio"
              ]]
            ])
          @unknown default:
            #if DEBUG
            print("🎵 AppDelegate: Unknown music permission status")
            #endif
            result([
              "status": "denied",
              "message": "Unknown music permission status",
              "missingPermissions": [[
                "name": "NSAppleMusicUsageDescription",
                "description": "Access to music library",
                "isRequired": true,
                "type": "audio"
              ]]
            ])
          }
        }
      }
    } else {
      #if DEBUG
      print("🎵 AppDelegate: iOS version too old for MPMediaLibrary")
      #endif
      result([
        "status": "denied",
        "message": "iOS version too old for music library access",
        "missingPermissions": [[
          "name": "NSAppleMusicUsageDescription",
          "description": "Access to music library",
          "isRequired": true,
          "type": "audio"
        ]]
      ])
    }
  }
  
  private func checkMusicPermission(result: @escaping FlutterResult) {
    #if DEBUG
    print("🎵 AppDelegate: checkMusicPermission called")
    #endif
    
    if #available(iOS 9.3, *) {
      let status = MPMediaLibrary.authorizationStatus()
      
      #if DEBUG
      print("🎵 AppDelegate: Music permission status: \(status.rawValue)")
      #endif
      
      switch status {
      case .authorized:
        result([
          "status": "granted",
          "message": "Music library access granted",
          "missingPermissions": []
        ])
      case .denied, .restricted, .notDetermined:
        result([
          "status": "denied",
          "message": "Music library access denied",
          "missingPermissions": [[
            "name": "NSAppleMusicUsageDescription",
            "description": "Access to music library",
            "isRequired": true,
            "type": "audio"
          ]]
        ])
      @unknown default:
        result([
          "status": "denied",
          "message": "Unknown music permission status",
          "missingPermissions": [[
            "name": "NSAppleMusicUsageDescription",
            "description": "Access to music library",
            "isRequired": true,
            "type": "audio"
          ]]
        ])
      }
    } else {
      result([
        "status": "denied",
        "message": "iOS version too old for music library access",
        "missingPermissions": [[
          "name": "NSAppleMusicUsageDescription",
          "description": "Access to music library",
          "isRequired": true,
          "type": "audio"
        ]]
      ])
    }
  }
  
  private func requestPhotoPermission(result: @escaping FlutterResult) {
    #if DEBUG
    print("🎥 AppDelegate: requestPhotoPermission called")
    #endif
    
    PHPhotoLibrary.requestAuthorization { status in
      #if DEBUG
      print("🎥 AppDelegate: PHPhotoLibrary.requestAuthorization callback received with status: \(status.rawValue)")
      #endif
      
      DispatchQueue.main.async {
        switch status {
        case .authorized:
          #if DEBUG
          print("🎥 AppDelegate: Photo permission granted")
          #endif
          result([
            "status": "granted",
            "message": "Photo library access granted",
            "missingPermissions": []
          ])
        case .denied, .restricted, .notDetermined:
          #if DEBUG
          print("🎥 AppDelegate: Photo permission denied/restricted/notDetermined")
          #endif
          result([
            "status": "denied",
            "message": "Photo library access denied",
            "missingPermissions": [[
              "name": "NSPhotoLibraryUsageDescription",
              "description": "Access to photo library",
              "isRequired": true,
              "type": "video"
            ]]
          ])
        @unknown default:
          #if DEBUG
          print("🎥 AppDelegate: Unknown photo permission status")
          #endif
          result([
            "status": "denied",
            "message": "Unknown photo permission status",
            "missingPermissions": [[
              "name": "NSPhotoLibraryUsageDescription",
              "description": "Access to photo library",
              "isRequired": true,
              "type": "video"
            ]]
          ])
        }
      }
    }
  }
  
  private func checkPhotoPermission(result: @escaping FlutterResult) {
    #if DEBUG
    print("🎥 AppDelegate: checkPhotoPermission called")
    #endif
    
    let status = PHPhotoLibrary.authorizationStatus()
    
    #if DEBUG
    print("🎥 AppDelegate: Photo permission status: \(status.rawValue)")
    #endif
    
    switch status {
    case .authorized:
      result([
        "status": "granted",
        "message": "Photo library access granted",
        "missingPermissions": []
      ])
    case .denied, .restricted, .notDetermined:
      result([
        "status": "denied",
        "message": "Photo library access denied",
        "missingPermissions": [[
          "name": "NSPhotoLibraryUsageDescription",
          "description": "Access to photo library",
          "isRequired": true,
          "type": "video"
        ]]
      ])
    @unknown default:
      result([
        "status": "denied",
        "message": "Unknown photo permission status",
        "missingPermissions": [[
          "name": "NSPhotoLibraryUsageDescription",
          "description": "Access to photo library",
          "isRequired": true,
          "type": "video"
        ]]
      ])
    }
  }
  
  private func requestAllPermissions(result: @escaping FlutterResult) {
    #if DEBUG
    print("📱 AppDelegate: requestAllPermissions called")
    #endif
    
    let group = DispatchGroup()
    var audioResult: [String: Any] = [:]
    var videoResult: [String: Any] = [:]
    
    // Request audio permission
    group.enter()
    requestMusicPermission { audioPermissionResult in
      audioResult = audioPermissionResult as? [String: Any] ?? [:]
      group.leave()
    }
    
    // Request video permission
    group.enter()
    requestPhotoPermission { videoPermissionResult in
      videoResult = videoPermissionResult as? [String: Any] ?? [:]
      group.leave()
    }
    
    group.notify(queue: .main) {
      let audioGranted = audioResult["status"] as? String == "granted"
      let videoGranted = videoResult["status"] as? String == "granted"
      
      if audioGranted && videoGranted {
        result([
          "status": "granted",
          "message": "All permissions granted",
          "missingPermissions": []
        ])
      } else {
        var missingPermissions: [[String: Any]] = []
        
        if !audioGranted {
          missingPermissions.append([
            "name": "NSAppleMusicUsageDescription",
            "description": "Access to music library",
            "isRequired": true,
            "type": "audio"
          ])
        }
        
        if !videoGranted {
          missingPermissions.append([
            "name": "NSPhotoLibraryUsageDescription",
            "description": "Access to photo library",
            "isRequired": true,
            "type": "video"
          ])
        }
        
        result([
          "status": "denied",
          "message": "Some permissions denied",
          "missingPermissions": missingPermissions
        ])
      }
    }
  }
  
  private func checkAllPermissions(result: @escaping FlutterResult) {
    #if DEBUG
    print("📱 AppDelegate: checkAllPermissions called")
    #endif
    
    let audioStatus = MPMediaLibrary.authorizationStatus()
    let videoStatus = PHPhotoLibrary.authorizationStatus()
    
    #if DEBUG
    print("🎵 AppDelegate: Audio permission status: \(audioStatus.rawValue)")
    print("🎥 AppDelegate: Video permission status: \(videoStatus.rawValue)")
    #endif
    
    let audioGranted = audioStatus == .authorized
    let videoGranted = videoStatus == .authorized
    
    if audioGranted && videoGranted {
      result([
        "status": "granted",
        "message": "All permissions granted",
        "missingPermissions": []
      ])
    } else {
      var missingPermissions: [[String: Any]] = []
      
      if !audioGranted {
        missingPermissions.append([
          "name": "NSAppleMusicUsageDescription",
          "description": "Access to music library",
          "isRequired": true,
          "type": "audio"
        ])
      }
      
      if !videoGranted {
        missingPermissions.append([
          "name": "NSPhotoLibraryUsageDescription",
          "description": "Access to photo library",
          "isRequired": true,
          "type": "video"
        ])
      }
      
      result([
        "status": "denied",
        "message": "Some permissions denied",
        "missingPermissions": missingPermissions
      ])
    }
  }
}