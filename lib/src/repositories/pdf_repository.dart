import 'dart:typed_data';

import '../models/pdf_document_model.dart';
import '../services/pdf_processing_service.dart';

class PdfRepository {
  const PdfRepository(this._service);

  final PdfProcessingService _service;

  Future<PdfDocumentModel> processDocument({
    required String id,
    required String fileName,
    required String filePath,
    String? nativePath,
    List<int>? bytes,
  }) async {
    final extractedText = bytes != null && bytes.isNotEmpty
        ? await _service.extractTextFromBytes(
            Uint8List.fromList(bytes),
            fileName: fileName,
          )
        : await _service.extractTextFromPath(
            nativePath ?? filePath,
            fileName: fileName,
          );

    return PdfDocumentModel.fromExtraction(
      id: id,
      fileName: fileName,
      filePath: filePath,
      extractedText: extractedText,
    );
  }
}
