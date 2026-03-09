/// Document model containing information about document files
class DocumentModel {
  /// Unique identifier for the document file
  final int id;

  /// Title/name of the document
  final String title;

  /// File path
  final String data;

  /// File size in bytes
  final int size;

  /// Date added timestamp
  final int dateAdded;

  /// Date modified timestamp
  final int dateModified;

  /// File extension
  final String fileExtension;

  /// Display name without extension
  final String displayName;

  /// MIME type
  final String mimeType;

  /// Document type category
  final DocumentType documentType;

  /// Author/creator
  final String author;

  /// Subject/topic
  final String subject;

  /// Keywords
  final String keywords;

  /// Page count (for supported formats)
  final int pageCount;

  /// Word count (for supported formats)
  final int wordCount;

  /// Language
  final String language;

  /// Whether the file is encrypted
  final bool isEncrypted;

  /// Whether the file is compressed
  final bool isCompressed;

  const DocumentModel({
    required this.id,
    required this.title,
    required this.data,
    required this.size,
    required this.dateAdded,
    required this.dateModified,
    required this.fileExtension,
    required this.displayName,
    required this.mimeType,
    required this.documentType,
    required this.author,
    required this.subject,
    required this.keywords,
    required this.pageCount,
    required this.wordCount,
    required this.language,
    required this.isEncrypted,
    required this.isCompressed,
  });

  /// Create DocumentModel from Map
  factory DocumentModel.fromMap(Map<String, dynamic> map) {
    return DocumentModel(
      id: map['id'] ?? 0,
      title: map['title'] ?? '',
      data: map['data'] ?? '',
      size: map['size'] ?? 0,
      dateAdded: map['date_added'] ?? 0,
      dateModified: map['date_modified'] ?? 0,
      fileExtension: map['file_extension'] ?? '',
      displayName: map['display_name'] ?? '',
      mimeType: map['mime_type'] ?? '',
      documentType: DocumentType.fromString(map['document_type'] ?? ''),
      author: map['author'] ?? '',
      subject: map['subject'] ?? '',
      keywords: map['keywords'] ?? '',
      pageCount: map['page_count'] ?? 0,
      wordCount: map['word_count'] ?? 0,
      language: map['language'] ?? '',
      isEncrypted: map['is_encrypted'] ?? false,
      isCompressed: map['is_compressed'] ?? false,
    );
  }

  /// Convert DocumentModel to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'data': data,
      'size': size,
      'date_added': dateAdded,
      'date_modified': dateModified,
      'file_extension': fileExtension,
      'display_name': displayName,
      'mime_type': mimeType,
      'document_type': documentType.toString(),
      'author': author,
      'subject': subject,
      'keywords': keywords,
      'page_count': pageCount,
      'word_count': wordCount,
      'language': language,
      'is_encrypted': isEncrypted,
      'is_compressed': isCompressed,
    };
  }

  @override
  String toString() {
    return 'DocumentModel(id: $id, title: $title, documentType: $documentType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DocumentModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Document type enumeration
enum DocumentType {
  pdf,
  doc,
  docx,
  txt,
  rtf,
  xls,
  xlsx,
  ppt,
  pptx,
  csv,
  xml,
  html,
  epub,
  mobi,
  azw,
  image,
  archive,
  other;

  /// Create DocumentType from string
  factory DocumentType.fromString(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return DocumentType.pdf;
      case 'doc':
        return DocumentType.doc;
      case 'docx':
        return DocumentType.docx;
      case 'txt':
        return DocumentType.txt;
      case 'rtf':
        return DocumentType.rtf;
      case 'xls':
        return DocumentType.xls;
      case 'xlsx':
        return DocumentType.xlsx;
      case 'ppt':
        return DocumentType.ppt;
      case 'pptx':
        return DocumentType.pptx;
      case 'csv':
        return DocumentType.csv;
      case 'xml':
        return DocumentType.xml;
      case 'html':
        return DocumentType.html;
      case 'epub':
        return DocumentType.epub;
      case 'mobi':
        return DocumentType.mobi;
      case 'azw':
        return DocumentType.azw;
      case 'image':
        return DocumentType.image;
      case 'archive':
        return DocumentType.archive;
      default:
        return DocumentType.other;
    }
  }

  @override
  String toString() {
    return name;
  }
}
