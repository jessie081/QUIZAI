import 'dart:io';
import 'dart:typed_data';

Future<Uint8List> readPdfBytesFromPath(String filePath) {
  return File(filePath).readAsBytes();
}
