import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:safety_apps/network/api_client.dart';

class P5MExportService {
  static Future<File> downloadExportXlsx({
    DateTime? start,
    DateTime? end,
  }) async {
    var path = "/p5m/export.xlsx";

    if (start != null && end != null) {
      final s = DateFormat("yyyy-MM-dd").format(start);
      final e = DateFormat("yyyy-MM-dd").format(end); // end exclusive
      path += "?start=$s&end=$e";
    }

    // pakai getBytes kalau kamu menambahkannya, kalau tidak pakai get() juga masih jalan
    final res = await ApiClient.getBytes(path);

    if (res.statusCode == 429) {
      throw Exception(res.body); // backend kamu kirim "tunggu x detik"
    }
    if (res.statusCode != 200) {
      throw Exception("Download export gagal (${res.statusCode}): ${res.body}");
    }

    final dir = await getTemporaryDirectory();
    final file = File(
      "${dir.path}/P5M_${DateTime.now().millisecondsSinceEpoch}.xlsx",
    );
    await file.writeAsBytes(res.bodyBytes, flush: true);
    return file;
  }
}
