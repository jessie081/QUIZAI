import 'dart:typed_data';

import 'pdf_file_bytes_reader_stub.dart'
    if (dart.library.io) 'pdf_file_bytes_reader_io.dart' as impl;

Future<Uint8List> readPdfBytesFromPath(String filePath) {
  return impl.readPdfBytesFromPath(filePath);
}
