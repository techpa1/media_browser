#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>
#include <filesystem>
#include <iostream>
#include <string>
#include <vector>
#include <map>
#include <thread>
#include <future>
#include <chrono>

G_DECLARE_FINAL_TYPE(MediaBrowserPlugin, media_browser_plugin,
                     MEDIA, BROWSER_PLUGIN, GObject)

#define MEDIA_TYPE_BROWSER_PLUGIN media_browser_plugin_get_type()

G_DEFINE_TYPE(MediaBrowserPlugin, media_browser_plugin, g_object_get_type())

// Called when a method call is received from Flutter.
static void media_browser_plugin_handle_method_call(
    MediaBrowserPlugin* self,
    FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar* method = fl_method_call_get_name(method_call);
  FlValue* args = fl_method_call_get_args(method_call);

  if (strcmp(method, "getPlatformVersion") == 0) {
    struct utsname uname_data;
    uname(&uname_data);
    g_autofree gchar* version = g_strdup_printf("Linux %s", uname_data.release);
    g_autoptr(FlValue) result = fl_value_new_string(version);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else if (strcmp(method, "checkPermissions") == 0) {
    // Linux doesn't require special permissions for file access
    g_autoptr(FlValue) status = fl_value_new_string("granted");
    g_autoptr(FlValue) message = fl_value_new_string("All permissions granted");
    g_autoptr(FlValue) missing_permissions = fl_value_new_list();
    
    g_autoptr(FlValue) result = fl_value_new_map();
    fl_value_set_string_take(result, "status", fl_value_ref(status));
    fl_value_set_string_take(result, "message", fl_value_ref(message));
    fl_value_set(result, "missingPermissions", missing_permissions);
    
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else if (strcmp(method, "requestPermissions") == 0) {
    // Same as check permissions on Linux
    g_autoptr(FlValue) status = fl_value_new_string("granted");
    g_autoptr(FlValue) message = fl_value_new_string("All permissions granted");
    g_autoptr(FlValue) missing_permissions = fl_value_new_list();
    
    g_autoptr(FlValue) result = fl_value_new_map();
    fl_value_set_string_take(result, "status", fl_value_ref(status));
    fl_value_set_string_take(result, "message", fl_value_ref(message));
    fl_value_set(result, "missingPermissions", missing_permissions);
    
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else if (strcmp(method, "queryAudios") == 0) {
    // Run in background thread
    std::thread([self, method_call]() {
      g_autoptr(FlValue) result = fl_value_new_list();
      
      try {
        std::vector<std::string> audioExtensions = {".mp3", ".wav", ".flac", ".aac", ".m4a", ".ogg", ".wma"};
        std::vector<std::string> musicPaths = {
          std::string(getenv("HOME")) + "/Music",
          std::string(getenv("HOME")) + "/Downloads"
        };
        
        for (const auto& path : musicPaths) {
          auto files = scanDirectory(path, audioExtensions);
          for (const auto& file : files) {
            g_autoptr(FlValue) fileValue = createFileValue(file);
            fl_value_append_take(result, fl_value_ref(fileValue));
          }
        }
        
        g_autoptr(FlMethodResponse) response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
        fl_method_call_respond(method_call, response, nullptr);
      } catch (const std::exception& e) {
        g_autoptr(FlMethodResponse) response = FL_METHOD_RESPONSE(fl_method_error_response_new("QUERY_AUDIO_FAILED", 
          g_strdup_printf("Failed to query audio files: %s", e.what()), nullptr));
        fl_method_call_respond(method_call, response, nullptr);
      }
    }).detach();
    return; // Response will be sent from background thread
  } else if (strcmp(method, "queryVideos") == 0) {
    // Run in background thread
    std::thread([self, method_call]() {
      g_autoptr(FlValue) result = fl_value_new_list();
      
      try {
        std::vector<std::string> videoExtensions = {".mp4", ".avi", ".mkv", ".mov", ".wmv", ".flv", ".webm"};
        std::vector<std::string> videoPaths = {
          std::string(getenv("HOME")) + "/Videos",
          std::string(getenv("HOME")) + "/Downloads"
        };
        
        for (const auto& path : videoPaths) {
          auto files = scanDirectory(path, videoExtensions);
          for (const auto& file : files) {
            g_autoptr(FlValue) fileValue = createFileValue(file);
            fl_value_append_take(result, fl_value_ref(fileValue));
          }
        }
        
        g_autoptr(FlMethodResponse) response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
        fl_method_call_respond(method_call, response, nullptr);
      } catch (const std::exception& e) {
        g_autoptr(FlMethodResponse) response = FL_METHOD_RESPONSE(fl_method_error_response_new("QUERY_VIDEO_FAILED", 
          g_strdup_printf("Failed to query video files: %s", e.what()), nullptr));
        fl_method_call_respond(method_call, response, nullptr);
      }
    }).detach();
    return; // Response will be sent from background thread
  } else if (strcmp(method, "queryDocuments") == 0) {
    // Run in background thread
    std::thread([self, method_call]() {
      g_autoptr(FlValue) result = fl_value_new_list();
      
      try {
        std::vector<std::string> docExtensions = {".pdf", ".doc", ".docx", ".txt", ".rtf", ".xls", ".xlsx", ".ppt", ".pptx"};
        std::vector<std::string> docPaths = {
          std::string(getenv("HOME")) + "/Documents",
          std::string(getenv("HOME")) + "/Downloads"
        };
        
        for (const auto& path : docPaths) {
          auto files = scanDirectory(path, docExtensions);
          for (const auto& file : files) {
            g_autoptr(FlValue) fileValue = createFileValue(file);
            fl_value_append_take(result, fl_value_ref(fileValue));
          }
        }
        
        g_autoptr(FlMethodResponse) response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
        fl_method_call_respond(method_call, response, nullptr);
      } catch (const std::exception& e) {
        g_autoptr(FlMethodResponse) response = FL_METHOD_RESPONSE(fl_method_error_response_new("QUERY_DOCUMENT_FAILED", 
          g_strdup_printf("Failed to query document files: %s", e.what()), nullptr));
        fl_method_call_respond(method_call, response, nullptr);
      }
    }).detach();
    return; // Response will be sent from background thread
  } else if (strcmp(method, "queryFolders") == 0) {
    // Run in background thread
    std::thread([self, method_call]() {
      g_autoptr(FlValue) result = fl_value_new_list();
      
      try {
        std::vector<std::string> folderPaths = {
          std::string(getenv("HOME")) + "/Documents",
          std::string(getenv("HOME")) + "/Music",
          std::string(getenv("HOME")) + "/Videos",
          std::string(getenv("HOME")) + "/Pictures",
          std::string(getenv("HOME")) + "/Downloads"
        };
        
        for (const auto& path : folderPaths) {
          if (std::filesystem::exists(path) && std::filesystem::is_directory(path)) {
            auto folderInfo = createFolderInfo(path);
            g_autoptr(FlValue) folderValue = createFileValue(folderInfo);
            fl_value_append_take(result, fl_value_ref(folderValue));
          }
        }
        
        g_autoptr(FlMethodResponse) response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
        fl_method_call_respond(method_call, response, nullptr);
      } catch (const std::exception& e) {
        g_autoptr(FlMethodResponse) response = FL_METHOD_RESPONSE(fl_method_error_response_new("QUERY_FOLDER_FAILED", 
          g_strdup_printf("Failed to query folders: %s", e.what()), nullptr));
        fl_method_call_respond(method_call, response, nullptr);
      }
    }).detach();
    return; // Response will be sent from background thread
  } else if (strcmp(method, "queryAlbums") == 0) {
    // Linux doesn't have native album support, return empty list
    g_autoptr(FlValue) result = fl_value_new_list();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else if (strcmp(method, "queryArtists") == 0) {
    // Linux doesn't have native artist support, return empty list
    g_autoptr(FlValue) result = fl_value_new_list();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else if (strcmp(method, "queryGenres") == 0) {
    // Linux doesn't have native genre support, return empty list
    g_autoptr(FlValue) result = fl_value_new_list();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else if (strcmp(method, "queryArtwork") == 0) {
    // Linux artwork implementation - file system based scanning
    FlValue* args = fl_method_call_get_args(method_call);
    
    if (args == nullptr || fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
      g_autoptr(FlValue) result = fl_value_new_map();
      fl_value_set_string_take(result, "id", fl_value_new_int(0));
      fl_value_set_string_take(result, "data", fl_value_new_null());
      fl_value_set_string_take(result, "format", fl_value_new_string("jpeg"));
      fl_value_set_string_take(result, "size", fl_value_new_string("medium"));
      fl_value_set_string_take(result, "is_available", fl_value_new_bool(FALSE));
      fl_value_set_string_take(result, "error", fl_value_new_string("Invalid arguments"));
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
    } else {
      FlValue* id_value = fl_value_lookup_string(args, "id");
      FlValue* type_value = fl_value_lookup_string(args, "type");
      FlValue* size_value = fl_value_lookup_string(args, "size");
      
      int id = id_value ? fl_value_get_int(id_value) : 0;
      const gchar* type = type_value ? fl_value_get_string(type_value) : "audio";
      const gchar* size = size_value ? fl_value_get_string(size_value) : "medium";
      
      g_autoptr(FlValue) result = fl_value_new_map();
      fl_value_set_string_take(result, "id", fl_value_new_int(id));
      fl_value_set_string_take(result, "data", fl_value_new_null());
      fl_value_set_string_take(result, "format", fl_value_new_string("jpeg"));
      fl_value_set_string_take(result, "size", fl_value_new_string(size));
      fl_value_set_string_take(result, "is_available", fl_value_new_bool(FALSE));
      fl_value_set_string_take(result, "error", fl_value_new_string("Artwork scanning not yet implemented for Linux"));
      
      // TODO: Implement file system-based artwork scanning for Linux
      // This would involve:
      // 1. Scanning common music directories (~/Music, /media, etc.)
      // 2. Looking for embedded album art in audio files using GStreamer or similar
      // 3. Looking for folder.jpg, cover.jpg, albumart.jpg files
      // 4. Using taglib or similar libraries for metadata extraction
      
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
    }
  } else if (strcmp(method, "clearCachedArtworks") == 0) {
    // No-op on Linux
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_null()));
  } else if (strcmp(method, "scanMedia") == 0) {
    // No-op on Linux
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_null()));
  } else if (strcmp(method, "getDeviceInfo") == 0) {
    struct utsname uname_data;
    uname(&uname_data);
    
    g_autoptr(FlValue) result = fl_value_new_map();
    fl_value_set_string_take(result, "platform", fl_value_new_string("Linux"));
    fl_value_set_string_take(result, "version", fl_value_new_string(uname_data.release));
    fl_value_set_string_take(result, "model", fl_value_new_string(uname_data.nodename));
    fl_value_set_string_take(result, "manufacturer", fl_value_new_string("Unknown"));
    fl_value_set_string_take(result, "brand", fl_value_new_string("Linux"));
    
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  if (response) {
    fl_method_call_respond(method_call, response, nullptr);
  }
}

// Helper functions
std::vector<std::map<std::string, std::string>> scanDirectory(
    const std::string& path, const std::vector<std::string>& extensions) {
  std::vector<std::map<std::string, std::string>> files;
  
  try {
    for (const auto& entry : std::filesystem::recursive_directory_iterator(path)) {
      if (entry.is_regular_file()) {
        std::string filePath = entry.path().string();
        std::string extension = getFileExtension(filePath);
        
        // Check if file has one of the desired extensions
        bool hasValidExtension = false;
        for (const auto& ext : extensions) {
          if (extension == ext) {
            hasValidExtension = true;
            break;
          }
        }
        
        if (hasValidExtension) {
          auto fileInfo = createFileInfo(filePath);
          files.push_back(fileInfo);
        }
      }
    }
  } catch (const std::exception& e) {
    // Directory might not exist or be accessible, continue
  }
  
  return files;
}

std::string getFileExtension(const std::string& filename) {
  size_t pos = filename.find_last_of('.');
  if (pos != std::string::npos) {
    return filename.substr(pos);
  }
  return "";
}

std::string getDisplayName(const std::string& path) {
  std::filesystem::path p(path);
  return p.stem().string();
}

std::string getMimeType(const std::string& extension) {
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

std::map<std::string, std::string> createFileInfo(const std::string& path) {
  std::map<std::string, std::string> info;
  
  std::filesystem::path p(path);
  std::string filename = p.filename().string();
  std::string extension = getFileExtension(filename);
  std::string displayName = getDisplayName(path);
  
  info["id"] = std::to_string(std::hash<std::string>{}(path));
  info["title"] = displayName;
  info["data"] = path;
  info["file_extension"] = extension;
  info["display_name"] = displayName;
  info["mime_type"] = getMimeType(extension);
  
  try {
    info["size"] = std::to_string(std::filesystem::file_size(path));
    auto time = std::filesystem::last_write_time(path);
    auto sctp = std::chrono::time_point_cast<std::chrono::system_clock::duration>(
        time - std::filesystem::file_time_type::clock::now() + std::chrono::system_clock::now());
    info["date_modified"] = std::to_string(std::chrono::duration_cast<std::chrono::seconds>(sctp.time_since_epoch()).count());
    info["date_added"] = info["date_modified"]; // Use modified time as fallback
  } catch (const std::exception&) {
    info["size"] = "0";
    info["date_modified"] = "0";
    info["date_added"] = "0";
  }
  
  return info;
}

std::map<std::string, std::string> createFolderInfo(const std::string& path) {
  std::map<std::string, std::string> info;
  
  std::filesystem::path p(path);
  std::string filename = p.filename().string();
  
  info["id"] = std::to_string(std::hash<std::string>{}(path));
  info["name"] = filename;
  info["path"] = path;
  info["parent_path"] = p.parent_path().string();
  info["folder_type"] = "other";
  info["storage_location"] = "internal";
  
  try {
    auto time = std::filesystem::last_write_time(path);
    auto sctp = std::chrono::time_point_cast<std::chrono::system_clock::duration>(
        time - std::filesystem::file_time_type::clock::now() + std::chrono::system_clock::now());
    info["date_created"] = std::to_string(std::chrono::duration_cast<std::chrono::seconds>(sctp.time_since_epoch()).count());
    info["date_modified"] = info["date_created"];
    info["date_accessed"] = info["date_created"];
  } catch (const std::exception&) {
    info["date_created"] = "0";
    info["date_modified"] = "0";
    info["date_accessed"] = "0";
  }
  
  info["total_size"] = "0";
  info["file_count"] = "0";
  info["directory_count"] = "0";
  info["is_hidden"] = "false";
  info["is_read_only"] = "false";
  info["is_system"] = "false";
  
  return info;
}

FlValue* createFileValue(const std::map<std::string, std::string>& fileInfo) {
  g_autoptr(FlValue) result = fl_value_new_map();
  
  for (const auto& pair : fileInfo) {
    fl_value_set_string_take(result, pair.first.c_str(), fl_value_new_string(pair.second.c_str()));
  }
  
  return fl_value_ref(result);
}

static void media_browser_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(media_browser_plugin_parent_class)->dispose(object);
}

static void media_browser_plugin_class_init(MediaBrowserPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = media_browser_plugin_dispose;
}

static void media_browser_plugin_init(MediaBrowserPlugin* self) {}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  MediaBrowserPlugin* plugin = MEDIA_BROWSER_PLUGIN(user_data);
  media_browser_plugin_handle_method_call(plugin, method_call);
}

void media_browser_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  MediaBrowserPlugin* plugin = MEDIA_BROWSER_PLUGIN(
      g_object_new(media_browser_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            "media_browser",
                            FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call_cb,
                                            g_object_ref(plugin),
                                            g_object_unref);

  g_object_unref(plugin);
}
