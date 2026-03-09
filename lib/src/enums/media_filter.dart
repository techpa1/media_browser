/// Media filter for querying different types of media
class MediaFilter {
  /// Filter for audio files
  static const String audio = 'audio';

  /// Filter for video files
  static const String video = 'video';

  /// Filter for document files
  static const String document = 'document';

  /// Filter for image files
  static const String image = 'image';

  /// Filter for folder/directory
  static const String folder = 'folder';

  /// Filter for all media types
  static const String all = 'all';
}

/// Audio format filter
class AudioFormat {
  static const String mp3 = 'mp3';
  static const String aac = 'aac';
  static const String flac = 'flac';
  static const String wav = 'wav';
  static const String ogg = 'ogg';
  static const String m4a = 'm4a';
  static const String wma = 'wma';
  static const String amr = 'amr';
  static const String opus = 'opus';
}

/// Video format filter
class VideoFormat {
  static const String mp4 = 'mp4';
  static const String avi = 'avi';
  static const String mkv = 'mkv';
  static const String mov = 'mov';
  static const String wmv = 'wmv';
  static const String flv = 'flv';
  static const String webm = 'webm';
  static const String m4v = 'm4v';
  static const String mpg = 'mpg';
  static const String mpeg = 'mpeg';
  static const String m2v = 'm2v';
  static const String mts = 'mts';
  static const String m2ts = 'm2ts';
  static const String ts = 'ts';
  static const String vob = 'vob';
}

/// Document format filter
class DocumentFormat {
  static const String pdf = 'pdf';
  static const String doc = 'doc';
  static const String docx = 'docx';
  static const String txt = 'txt';
  static const String rtf = 'rtf';
  static const String xls = 'xls';
  static const String xlsx = 'xlsx';
  static const String ppt = 'ppt';
  static const String pptx = 'pptx';
  static const String csv = 'csv';
  static const String xml = 'xml';
  static const String html = 'html';
  static const String epub = 'epub';
  static const String mobi = 'mobi';
  static const String azw = 'azw';
}

/// Image format filter
class ImageFormat {
  static const String jpg = 'jpg';
  static const String jpeg = 'jpeg';
  static const String png = 'png';
  static const String gif = 'gif';
  static const String bmp = 'bmp';
  static const String webp = 'webp';
  static const String svg = 'svg';
  static const String tiff = 'tiff';
  static const String ico = 'ico';
  static const String heic = 'heic';
  static const String heif = 'heif';
}

/// Archive format filter
class ArchiveFormat {
  static const String zip = 'zip';
  static const String rar = 'rar';
  static const String tar = 'tar';
  static const String gz = 'gz';
  static const String bz2 = 'bz2';
  static const String xz = 'xz';
  static const String sevenZ = '7z';
  static const String iso = 'iso';
}

/// Media type enumeration
enum MediaType {
  audio,
  video,
  document,
  image,
  folder,
  archive,
  other;

  /// Create MediaType from string
  factory MediaType.fromString(String type) {
    switch (type.toLowerCase()) {
      case 'audio':
        return MediaType.audio;
      case 'video':
        return MediaType.video;
      case 'document':
        return MediaType.document;
      case 'image':
        return MediaType.image;
      case 'folder':
        return MediaType.folder;
      case 'archive':
        return MediaType.archive;
      default:
        return MediaType.other;
    }
  }

  @override
  String toString() {
    return name;
  }
}

/// File size range filter
class FileSizeRange {
  final int minSize;
  final int maxSize;

  const FileSizeRange({
    required this.minSize,
    required this.maxSize,
  });

  /// Create range for files smaller than specified size
  factory FileSizeRange.smallerThan(int maxSize) {
    return FileSizeRange(minSize: 0, maxSize: maxSize);
  }

  /// Create range for files larger than specified size
  factory FileSizeRange.largerThan(int minSize) {
    return FileSizeRange(minSize: minSize, maxSize: -1);
  }

  /// Create range for files between specified sizes
  factory FileSizeRange.between(int minSize, int maxSize) {
    return FileSizeRange(minSize: minSize, maxSize: maxSize);
  }

  /// Create range for files of exact size
  factory FileSizeRange.exact(int size) {
    return FileSizeRange(minSize: size, maxSize: size);
  }
}

/// Date range filter
class DateRange {
  final int startDate;
  final int endDate;

  const DateRange({
    required this.startDate,
    required this.endDate,
  });

  /// Create range for files created after specified date
  factory DateRange.after(int startDate) {
    return DateRange(startDate: startDate, endDate: -1);
  }

  /// Create range for files created before specified date
  factory DateRange.before(int endDate) {
    return DateRange(startDate: 0, endDate: endDate);
  }

  /// Create range for files created between specified dates
  factory DateRange.between(int startDate, int endDate) {
    return DateRange(startDate: startDate, endDate: endDate);
  }
}
