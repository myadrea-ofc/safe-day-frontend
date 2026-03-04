import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageCompressor {
  static const maxSize = 5 * 1024 * 1024;

  static Future<File> compressIfNeeded(File file) async {
    if (file.lengthSync() <= maxSize) return file;

    final tempDir = await getTemporaryDirectory();
    final targetPath = p.join(
      tempDir.path,
      "cmp_${DateTime.now().millisecondsSinceEpoch}.jpg",
    );

    XFile? result = await FlutterImageCompress.compressAndGetFile(
      file.path,
      targetPath,
      quality: 70,
      minWidth: 1280,
      minHeight: 1280,
    );

    if (result == null) return file;

    File compressed = File(result.path);

    if (compressed.lengthSync() > maxSize) {
      final retry = await FlutterImageCompress.compressAndGetFile(
        compressed.path,
        targetPath,
        quality: 55,
        minWidth: 1024,
        minHeight: 1024,
      );
      if (retry != null) compressed = File(retry.path);
    }

    return compressed;
  }
}
