#include <flutter_plugin_registrar.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>
#include <shlobj.h>
#include <filesystem>
#include <iostream>
#include <memory>
#include <sstream>
#include <string>
#include <vector>
#include <map>
#include <thread>
#include <future>
#include <chrono>

namespace {

class MediaBrowserPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  MediaBrowserPlugin();

  virtual ~MediaBrowserPlugin();

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // Platform version
  void GetPlatformVersion(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // Permission methods
  void CheckPermissions(const flutter::EncodableValue& arguments, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void RequestPermissions(const flutter::EncodableValue& arguments, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // Query methods
  void QueryAudios(const flutter::EncodableValue& arguments, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void QueryVideos(const flutter::EncodableValue& arguments, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void QueryDocuments(const flutter::EncodableValue& arguments, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void QueryFolders(const flutter::EncodableValue& arguments, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void QueryAlbums(const flutter::EncodableValue& arguments, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void QueryArtists(const flutter::EncodableValue& arguments, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void QueryGenres(const flutter::EncodableValue& arguments, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void QueryArtwork(const flutter::EncodableValue& arguments, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // Utility methods
  void ClearCachedArtworks(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void ScanMedia(const flutter::EncodableValue& arguments, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void GetDeviceInfo(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // Helper methods
  std::vector<std::map<std::string, flutter::EncodableValue>> ScanDirectory(const std::string& path, const std::vector<std::string>& extensions);
  std::string GetFileExtension(const std::string& filename);
  std::string GetDisplayName(const std::string& path);
  int64_t GetFileSize(const std::string& path);
  int64_t GetFileModifiedTime(const std::string& path);
  std::string GetMimeType(const std::string& extension);
  std::map<std::string, flutter::EncodableValue> CreateFileInfo(const std::string& path, const std::string& type);
};

// static
void MediaBrowserPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "media_browser",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<MediaBrowserPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

MediaBrowserPlugin::MediaBrowserPlugin() {}

MediaBrowserPlugin::~MediaBrowserPlugin() {}

void MediaBrowserPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  const auto& method = method_call.method_name();
  const auto& arguments = method_call.arguments();

  if (method == "getPlatformVersion") {
    GetPlatformVersion(std::move(result));
  } else if (method == "checkPermissions") {
    CheckPermissions(arguments, std::move(result));
  } else if (method == "requestPermissions") {
    RequestPermissions(arguments, std::move(result));
  } else if (method == "queryAudios") {
    QueryAudios(arguments, std::move(result));
  } else if (method == "queryVideos") {
    QueryVideos(arguments, std::move(result));
  } else if (method == "queryDocuments") {
    QueryDocuments(arguments, std::move(result));
  } else if (method == "queryFolders") {
    QueryFolders(arguments, std::move(result));
  } else if (method == "queryAlbums") {
    QueryAlbums(arguments, std::move(result));
  } else if (method == "queryArtists") {
    QueryArtists(arguments, std::move(result));
  } else if (method == "queryGenres") {
    QueryGenres(arguments, std::move(result));
  } else if (method == "queryArtwork") {
    QueryArtwork(arguments, std::move(result));
  } else if (method == "clearCachedArtworks") {
    ClearCachedArtworks(std::move(result));
  } else if (method == "scanMedia") {
    ScanMedia(arguments, std::move(result));
  } else if (method == "getDeviceInfo") {
    GetDeviceInfo(std::move(result));
  } else {
    result->NotImplemented();
  }
}

void MediaBrowserPlugin::GetPlatformVersion(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  std::string version = "Windows 10";
  
  // Get actual Windows version
  OSVERSIONINFOEX osvi;
  ZeroMemory(&osvi, sizeof(OSVERSIONINFOEX));
  osvi.dwOSVersionInfoSize = sizeof(OSVERSIONINFOEX);
  
  if (GetVersionEx((OSVERSIONINFO*)&osvi)) {
    std::ostringstream oss;
    oss << "Windows " << osvi.dwMajorVersion << "." << osvi.dwMinorVersion;
    version = oss.str();
  }
  
  result->Success(flutter::EncodableValue(version));
}

void MediaBrowserPlugin::CheckPermissions(const flutter::EncodableValue& arguments, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  // On Windows, we don't need special permissions for file access
  std::map<std::string, flutter::EncodableValue> response;
  response["status"] = flutter::EncodableValue("granted");
  response["message"] = flutter::EncodableValue("All permissions granted");
  response["missingPermissions"] = flutter::EncodableValue(std::vector<flutter::EncodableValue>());
  
  result->Success(flutter::EncodableValue(response));
}

void MediaBrowserPlugin::RequestPermissions(const flutter::EncodableValue& arguments, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  // Same as check permissions on Windows
  CheckPermissions(arguments, std::move(result));
}

void MediaBrowserPlugin::QueryAudios(const flutter::EncodableValue& arguments, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  std::thread([this, result = std::move(result)]() {
    try {
      std::vector<std::string> audioExtensions = {".mp3", ".wav", ".flac", ".aac", ".m4a", ".ogg", ".wma"};
      std::vector<std::string> musicPaths = {
        std::string(getenv("USERPROFILE")) + "\\Music",
        std::string(getenv("USERPROFILE")) + "\\Downloads"
      };
      
      std::vector<flutter::EncodableValue> audios;
      
      for (const auto& path : musicPaths) {
        auto files = ScanDirectory(path, audioExtensions);
        for (const auto& file : files) {
          audios.push_back(flutter::EncodableValue(file));
        }
      }
      
      result->Success(flutter::EncodableValue(audios));
    } catch (const std::exception& e) {
      result->Error("QUERY_AUDIO_FAILED", std::string("Failed to query audio files: ") + e.what());
    }
  }).detach();
}

void MediaBrowserPlugin::QueryVideos(const flutter::EncodableValue& arguments, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  std::thread([this, result = std::move(result)]() {
    try {
      std::vector<std::string> videoExtensions = {".mp4", ".avi", ".mkv", ".mov", ".wmv", ".flv", ".webm"};
      std::vector<std::string> videoPaths = {
        std::string(getenv("USERPROFILE")) + "\\Videos",
        std::string(getenv("USERPROFILE")) + "\\Downloads"
      };
      
      std::vector<flutter::EncodableValue> videos;
      
      for (const auto& path : videoPaths) {
        auto files = ScanDirectory(path, videoExtensions);
        for (const auto& file : files) {
          videos.push_back(flutter::EncodableValue(file));
        }
      }
      
      result->Success(flutter::EncodableValue(videos));
    } catch (const std::exception& e) {
      result->Error("QUERY_VIDEO_FAILED", std::string("Failed to query video files: ") + e.what());
    }
  }).detach();
}

void MediaBrowserPlugin::QueryDocuments(const flutter::EncodableValue& arguments, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  std::thread([this, result = std::move(result)]() {
    try {
      std::vector<std::string> docExtensions = {".pdf", ".doc", ".docx", ".txt", ".rtf", ".xls", ".xlsx", ".ppt", ".pptx"};
      std::vector<std::string> docPaths = {
        std::string(getenv("USERPROFILE")) + "\\Documents",
        std::string(getenv("USERPROFILE")) + "\\Downloads"
      };
      
      std::vector<flutter::EncodableValue> documents;
      
      for (const auto& path : docPaths) {
        auto files = ScanDirectory(path, docExtensions);
        for (const auto& file : files) {
          documents.push_back(flutter::EncodableValue(file));
        }
      }
      
      result->Success(flutter::EncodableValue(documents));
    } catch (const std::exception& e) {
      result->Error("QUERY_DOCUMENT_FAILED", std::string("Failed to query document files: ") + e.what());
    }
  }).detach();
}

void MediaBrowserPlugin::QueryFolders(const flutter::EncodableValue& arguments, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  std::thread([this, result = std::move(result)]() {
    try {
      std::vector<std::string> folderPaths = {
        std::string(getenv("USERPROFILE")) + "\\Documents",
        std::string(getenv("USERPROFILE")) + "\\Music",
        std::string(getenv("USERPROFILE")) + "\\Videos",
        std::string(getenv("USERPROFILE")) + "\\Pictures",
        std::string(getenv("USERPROFILE")) + "\\Downloads"
      };
      
      std::vector<flutter::EncodableValue> folders;
      
      for (const auto& path : folderPaths) {
        if (std::filesystem::exists(path) && std::filesystem::is_directory(path)) {
          auto folderInfo = CreateFileInfo(path, "folder");
          folders.push_back(flutter::EncodableValue(folderInfo));
        }
      }
      
      result->Success(flutter::EncodableValue(folders));
    } catch (const std::exception& e) {
      result->Error("QUERY_FOLDER_FAILED", std::string("Failed to query folders: ") + e.what());
    }
  }).detach();
}

void MediaBrowserPlugin::QueryAlbums(const flutter::EncodableValue& arguments, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  // Windows doesn't have native album support, return empty list
  result->Success(flutter::EncodableValue(std::vector<flutter::EncodableValue>()));
}

void MediaBrowserPlugin::QueryArtists(const flutter::EncodableValue& arguments, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  // Windows doesn't have native artist support, return empty list
  result->Success(flutter::EncodableValue(std::vector<flutter::EncodableValue>()));
}

void MediaBrowserPlugin::QueryGenres(const flutter::EncodableValue& arguments, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  // Windows doesn't have native genre support, return empty list
  result->Success(flutter::EncodableValue(std::vector<flutter::EncodableValue>()));
}

void MediaBrowserPlugin::QueryArtwork(const flutter::EncodableValue& arguments, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  try {
    const auto& args = std::get<flutter::EncodableMap>(arguments);
    int id = std::get<int>(args.at(flutter::EncodableValue("id")));
    std::string type = std::get<std::string>(args.at(flutter::EncodableValue("type")));
    std::string size = std::get<std::string>(args.at(flutter::EncodableValue("size")));
    
    std::map<std::string, flutter::EncodableValue> artwork;
    artwork["id"] = flutter::EncodableValue(id);
    artwork["data"] = flutter::EncodableValue(nullptr);
    artwork["format"] = flutter::EncodableValue("jpeg");
    artwork["size"] = flutter::EncodableValue(size);
    artwork["is_available"] = flutter::EncodableValue(false);
    artwork["error"] = flutter::EncodableValue("Artwork scanning not yet implemented for Windows");
    
    // TODO: Implement file system-based artwork scanning for Windows
    // This would involve:
    // 1. Scanning common music directories (Music, Downloads, etc.)
    // 2. Looking for embedded album art in audio files
    // 3. Looking for folder.jpg, cover.jpg, albumart.jpg files
    // 4. Using Windows Media Foundation or similar APIs
    
    result->Success(flutter::EncodableValue(artwork));
  } catch (const std::exception& e) {
    std::map<std::string, flutter::EncodableValue> artwork;
    artwork["id"] = flutter::EncodableValue(0);
    artwork["data"] = flutter::EncodableValue(nullptr);
    artwork["format"] = flutter::EncodableValue("jpeg");
    artwork["size"] = flutter::EncodableValue("medium");
    artwork["is_available"] = flutter::EncodableValue(false);
    artwork["error"] = flutter::EncodableValue(std::string("Error: ") + e.what());
    
    result->Success(flutter::EncodableValue(artwork));
  }
}

void MediaBrowserPlugin::ClearCachedArtworks(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  // No-op on Windows
  result->Success();
}

void MediaBrowserPlugin::ScanMedia(const flutter::EncodableValue& arguments, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  // No-op on Windows
  result->Success();
}

void MediaBrowserPlugin::GetDeviceInfo(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  std::map<std::string, flutter::EncodableValue> deviceInfo;
  deviceInfo["platform"] = flutter::EncodableValue("Windows");
  
  // Get Windows version
  OSVERSIONINFOEX osvi;
  ZeroMemory(&osvi, sizeof(OSVERSIONINFOEX));
  osvi.dwOSVersionInfoSize = sizeof(OSVERSIONINFOEX);
  
  if (GetVersionEx((OSVERSIONINFO*)&osvi)) {
    std::ostringstream oss;
    oss << osvi.dwMajorVersion << "." << osvi.dwMinorVersion;
    deviceInfo["version"] = flutter::EncodableValue(oss.str());
  } else {
    deviceInfo["version"] = flutter::EncodableValue("Unknown");
  }
  
  // Get computer name
  char computerName[MAX_COMPUTERNAME_LENGTH + 1];
  DWORD size = sizeof(computerName);
  if (GetComputerNameA(computerName, &size)) {
    deviceInfo["model"] = flutter::EncodableValue(std::string(computerName));
  } else {
    deviceInfo["model"] = flutter::EncodableValue("Unknown");
  }
  
  deviceInfo["manufacturer"] = flutter::EncodableValue("Microsoft");
  deviceInfo["brand"] = flutter::EncodableValue("Windows");
  
  result->Success(flutter::EncodableValue(deviceInfo));
}

// Helper method implementations
std::vector<std::map<std::string, flutter::EncodableValue>> MediaBrowserPlugin::ScanDirectory(
    const std::string& path, const std::vector<std::string>& extensions) {
  std::vector<std::map<std::string, flutter::EncodableValue>> files;
  
  try {
    for (const auto& entry : std::filesystem::recursive_directory_iterator(path)) {
      if (entry.is_regular_file()) {
        std::string filePath = entry.path().string();
        std::string extension = GetFileExtension(filePath);
        
        // Check if file has one of the desired extensions
        bool hasValidExtension = false;
        for (const auto& ext : extensions) {
          if (extension == ext) {
            hasValidExtension = true;
            break;
          }
        }
        
        if (hasValidExtension) {
          auto fileInfo = CreateFileInfo(filePath, "file");
          files.push_back(fileInfo);
        }
      }
    }
  } catch (const std::exception& e) {
    // Directory might not exist or be accessible, continue
  }
  
  return files;
}

std::string MediaBrowserPlugin::GetFileExtension(const std::string& filename) {
  size_t pos = filename.find_last_of('.');
  if (pos != std::string::npos) {
    return filename.substr(pos);
  }
  return "";
}

std::string MediaBrowserPlugin::GetDisplayName(const std::string& path) {
  std::filesystem::path p(path);
  return p.stem().string();
}

int64_t MediaBrowserPlugin::GetFileSize(const std::string& path) {
  try {
    return std::filesystem::file_size(path);
  } catch (const std::exception&) {
    return 0;
  }
}

int64_t MediaBrowserPlugin::GetFileModifiedTime(const std::string& path) {
  try {
    auto time = std::filesystem::last_write_time(path);
    auto sctp = std::chrono::time_point_cast<std::chrono::system_clock::duration>(
        time - std::filesystem::file_time_type::clock::now() + std::chrono::system_clock::now());
    return std::chrono::duration_cast<std::chrono::seconds>(sctp.time_since_epoch()).count();
  } catch (const std::exception&) {
    return 0;
  }
}

std::string MediaBrowserPlugin::GetMimeType(const std::string& extension) {
  if (extension == ".mp3") return "audio/mpeg";
  if (extension == ".wav") return "audio/wav";
  if (extension == ".flac") return "audio/flac";
  if (extension == ".aac") return "audio/aac";
  if (extension == ".m4a") return "audio/mp4";
  if (extension == ".ogg") return "audio/ogg";
  if (extension == ".wma") return "audio/x-ms-wma";
  if (extension == ".mp4") return "video/mp4";
  if (extension == ".avi") return "video/x-msvideo";
  if (extension == ".mkv") return "video/x-matroska";
  if (extension == ".mov") return "video/quicktime";
  if (extension == ".wmv") return "video/x-ms-wmv";
  if (extension == ".flv") return "video/x-flv";
  if (extension == ".webm") return "video/webm";
  if (extension == ".pdf") return "application/pdf";
  if (extension == ".doc") return "application/msword";
  if (extension == ".docx") return "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
  if (extension == ".txt") return "text/plain";
  if (extension == ".rtf") return "application/rtf";
  if (extension == ".xls") return "application/vnd.ms-excel";
  if (extension == ".xlsx") return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
  if (extension == ".ppt") return "application/vnd.ms-powerpoint";
  if (extension == ".pptx") return "application/vnd.openxmlformats-officedocument.presentationml.presentation";
  return "application/octet-stream";
}

std::map<std::string, flutter::EncodableValue> MediaBrowserPlugin::CreateFileInfo(
    const std::string& path, const std::string& type) {
  std::map<std::string, flutter::EncodableValue> info;
  
  std::filesystem::path p(path);
  std::string filename = p.filename().string();
  std::string extension = GetFileExtension(filename);
  std::string displayName = GetDisplayName(path);
  
  info["id"] = flutter::EncodableValue(static_cast<int64_t>(std::hash<std::string>{}(path)));
  info["title"] = flutter::EncodableValue(displayName);
  info["data"] = flutter::EncodableValue(path);
  info["file_extension"] = flutter::EncodableValue(extension);
  info["display_name"] = flutter::EncodableValue(displayName);
  info["mime_type"] = flutter::EncodableValue(GetMimeType(extension));
  
  if (type == "file") {
    info["size"] = flutter::EncodableValue(GetFileSize(path));
    info["date_modified"] = flutter::EncodableValue(GetFileModifiedTime(path));
    info["date_added"] = flutter::EncodableValue(GetFileModifiedTime(path)); // Use modified time as fallback
  } else if (type == "folder") {
    info["name"] = flutter::EncodableValue(filename);
    info["path"] = flutter::EncodableValue(path);
    info["parent_path"] = flutter::EncodableValue(p.parent_path().string());
    info["date_created"] = flutter::EncodableValue(GetFileModifiedTime(path));
    info["date_modified"] = flutter::EncodableValue(GetFileModifiedTime(path));
    info["date_accessed"] = flutter::EncodableValue(GetFileModifiedTime(path));
    info["total_size"] = flutter::EncodableValue(static_cast<int64_t>(0));
    info["file_count"] = flutter::EncodableValue(static_cast<int64_t>(0));
    info["directory_count"] = flutter::EncodableValue(static_cast<int64_t>(0));
    info["is_hidden"] = flutter::EncodableValue(false);
    info["is_read_only"] = flutter::EncodableValue(false);
    info["is_system"] = flutter::EncodableValue(false);
    info["folder_type"] = flutter::EncodableValue("other");
    info["storage_location"] = flutter::EncodableValue("internal");
  }
  
  return info;
}

}  // namespace

void MediaBrowserPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  MediaBrowserPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
