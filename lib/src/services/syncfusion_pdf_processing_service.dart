import 'dart:typed_data';

import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'pdf_file_bytes_reader.dart';
import 'pdf_processing_service.dart';

class SyncfusionPdfProcessingService implements PdfProcessingService {
  const SyncfusionPdfProcessingService();

  @override
  Future<String> extractTextFromPath(String filePath, {String? fileName}) async {
    final bytes = await readPdfBytesFromPath(filePath);
    return extractTextFromBytes(bytes, fileName: fileName);
  }

  @override
  Future<String> extractTextFromBytes(
    Uint8List bytes, {
    String? fileName,
  }) async {
    if (bytes.isEmpty) {
      return '';
    }

    PdfDocument? document;
    try {
      document = PdfDocument(inputBytes: bytes);
      final extractor = PdfTextExtractor(document);
      return extractor.extractText().trim();
    } on Object catch (_) {
      return '';
    } finally {
      document?.dispose();
    }
  }
}
