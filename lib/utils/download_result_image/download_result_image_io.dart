import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:media_scanner/media_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Future<String> downloadResultImage({
  required String url,
  required String fileName,
}) async {
  Directory dir;

  if (Platform.isAndroid) {
    final status = await Permission.storage.request();

    if (!status.isGranted) {
      throw "Izin storage ditolak";
    }

    dir = Directory("/storage/emulated/0/Pictures/Safe Day");
  } else {
    dir = await getApplicationDocumentsDirectory();
  }

  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }

  final response = await http.get(Uri.parse(url));

  if (response.statusCode != 200) {
    throw "Download gagal";
  }

  final name = fileName.split('/').last;
  final file = File("${dir.path}/$name");

  await file.writeAsBytes(response.bodyBytes);

  final savedPath = file.path;

  if (Platform.isAndroid) {
    await MediaScanner.loadMedia(path: savedPath);
    await MediaScanner.loadMedia(path: dir.path);
  }

  return savedPath;
}
