import 'dart:typed_data';

abstract class PdfProcessingService {
  Future<String> extractTextFromPath(String filePath, {String? fileName});

  Future<String> extractTextFromBytes(
    Uint8List bytes, {
    String? fileName,
  });
}
