import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:media_scanner/media_scanner.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Future<String> downloadLpiFile({
  required String url,
  required String fileName,
  bool isImage = false,
}) async {
  Directory dir;

  if (Platform.isAndroid) {
    final status = await Permission.storage.request();

    if (!status.isGranted) {
      throw "Izin penyimpanan ditolak";
    }

    dir = Directory(
      isImage
          ? "/storage/emulated/0/Pictures/Safe Day"
          : "/storage/emulated/0/Documents",
    );
  } else {
    dir = await getApplicationDocumentsDirectory();
  }

  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }

  final response = await http.get(Uri.parse(url));

  if (response.statusCode != 200) {
    throw "Gagal download file";
  }

  final file = File("${dir.path}/$fileName");
  await file.writeAsBytes(response.bodyBytes);

  final savedPath = file.path;

  if (Platform.isAndroid && isImage) {
    await MediaScanner.loadMedia(path: savedPath);
  }

  return savedPath;
}

Future<void> openLpiFile({
  required String url,
  required String fileName,
}) async {
  Directory dir;

  if (Platform.isAndroid) {
    final status = await Permission.storage.request();

    if (!status.isGranted) {
      throw "Izin penyimpanan ditolak";
    }

    dir = Directory("/storage/emulated/0/Download");
  } else {
    dir = await getApplicationDocumentsDirectory();
  }

  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }

  final response = await http.get(Uri.parse(url));

  if (response.statusCode != 200) {
    throw "Gagal mengunduh file";
  }

  final file = File("${dir.path}/$fileName");
  await file.writeAsBytes(response.bodyBytes);

  final result = await OpenFile.open(file.path);

  if (result.type != ResultType.done) {
    throw result.message;
  }
}
