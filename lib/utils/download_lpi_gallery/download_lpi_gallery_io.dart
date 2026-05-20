import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:media_scanner/media_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

Future<String> downloadLpiGallery({
  required List<String> fotoPaths,
  required void Function(int current, int total) onProgress,
}) async {
  final total = fotoPaths.length;

  if (total == 0) {
    throw "Tidak ada foto untuk diunduh";
  }

  if (Platform.isAndroid) {
    final status = await Permission.storage.request();

    if (!status.isGranted) {
      throw "Izin penyimpanan ditolak";
    }
  }

  final dir = Directory("/storage/emulated/0/Pictures/Safe Day");

  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }

  for (int i = 0; i < fotoPaths.length; i++) {
    final foto = fotoPaths[i];

    final response = await http.get(
      Uri.parse("http://safety.borneo.co.id/uploads/$foto"),
    );

    if (response.statusCode != 200) {
      throw "Gagal download $foto";
    }

    final name = foto.split('/').last;
    final file = File("${dir.path}/$name");

    await file.writeAsBytes(response.bodyBytes);

    if (Platform.isAndroid) {
      await MediaScanner.loadMedia(path: file.path);
    }

    onProgress(i + 1, total);
  }

  if (Platform.isAndroid) {
    await MediaScanner.loadMedia(path: dir.path);
  }

  return dir.path;
}
