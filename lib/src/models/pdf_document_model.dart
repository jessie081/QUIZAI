class PdfDocumentModel {
  PdfDocumentModel({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.extractedText,
    required this.wordCount,
    required this.createdAt,
    this.pageCount,
  });

  final String id;
  final String fileName;
  final String filePath;
  final String extractedText;
  final int wordCount;
  final DateTime createdAt;
  final int? pageCount;

  factory PdfDocumentModel.fromExtraction({
    required String id,
    required String fileName,
    required String filePath,
    required String extractedText,
    int? pageCount,
    DateTime? createdAt,
  }) {
    final normalized = extractedText.trim();
    final words = normalized.isEmpty
        ? 0
        : normalized.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;

    return PdfDocumentModel(
      id: id,
      fileName: fileName,
      filePath: filePath,
      extractedText: normalized,
      wordCount: words,
      pageCount: pageCount,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  String get previewText {
    if (extractedText.length <= 200) {
      return extractedText;
    }
    return '${extractedText.substring(0, 200).trim()}...';
  }

  PdfDocumentModel copyWith({
    String? id,
    String? fileName,
    String? filePath,
    String? extractedText,
    int? wordCount,
    DateTime? createdAt,
    int? pageCount,
  }) {
    return PdfDocumentModel(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      extractedText: extractedText ?? this.extractedText,
      wordCount: wordCount ?? this.wordCount,
      createdAt: createdAt ?? this.createdAt,
      pageCount: pageCount ?? this.pageCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'filePath': filePath,
      'extractedText': extractedText,
      'wordCount': wordCount,
      'createdAt': createdAt.toIso8601String(),
      'pageCount': pageCount,
    };
  }

  factory PdfDocumentModel.fromJson(Map<String, dynamic> json) {
    return PdfDocumentModel(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      filePath: json['filePath'] as String,
      extractedText: json['extractedText'] as String,
      wordCount: json['wordCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      pageCount: json['pageCount'] as int?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is PdfDocumentModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
