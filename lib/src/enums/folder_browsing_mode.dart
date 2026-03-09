/// Enum for folder browsing modes
/// Determines what content to show when browsing folders
enum FolderBrowsingMode {
  /// Show all folders and files (default behavior)
  all,

  /// Show only audio files and subfolders
  audio,

  /// Show only video files and subfolders
  video,

  /// Show only document files and subfolders
  document,

  /// Show only audio and video files and subfolders
  audioAndVideo,

  /// Show only audio and document files and subfolders
  audioAndDocument,

  /// Show only video and document files and subfolders
  videoAndDocument,

  /// Show only audio and video and document files and subfolders
  audioAndVideoAndDocument,

  /// Show only folders (no files)
  foldersOnly,
}
