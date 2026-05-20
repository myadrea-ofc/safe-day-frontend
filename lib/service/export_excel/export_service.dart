import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:safety_apps/network/api_client.dart';

class ExportXlsxResult {
  final Uint8List bytes;
  final String fileName;

  const ExportXlsxResult({required this.bytes, required this.fileName});
}

class ExportService {
  static Future<ExportXlsxResult> downloadExportXlsxBytes({
    required String endpoint,
    required String filePrefix,
    DateTime? start,
    DateTime? end,
    Map<String, String?> extraQuery = const {},
  }) async {
    var path = "$endpoint/export.xlsx";

    final query = <String, String>{};

    if (start != null && end != null) {
      final startStr = DateFormat("yyyy-MM-dd").format(start);
      final endStr = DateFormat("yyyy-MM-dd").format(end);

      query["start"] = startStr;
      query["end"] = endStr;
    }

    extraQuery.forEach((key, value) {
      final cleanValue = value?.trim();

      if (cleanValue != null && cleanValue.isNotEmpty) {
        query[key] = cleanValue;
      }
    });

    if (query.isNotEmpty) {
      path += "?${Uri(queryParameters: query).query}";
    }

    final res = await ApiClient.getBytes(path);
    final bytes = res.bodyBytes;

    debugPrint("EXPORT PATH: $path");
    debugPrint("EXPORT STATUS: ${res.statusCode}");
    debugPrint("EXPORT CONTENT-TYPE: ${res.headers['content-type']}");
    debugPrint("EXPORT CONTENT-LENGTH: ${res.headers['content-length']}");
    debugPrint("EXPORT BYTE LENGTH: ${bytes.length}");

    if (res.statusCode == 429) {
      throw Exception(res.body);
    }

    if (res.statusCode != 200) {
      throw Exception("Download export gagal (${res.statusCode}): ${res.body}");
    }

    final isXlsx = bytes.length >= 2 && bytes[0] == 0x50 && bytes[1] == 0x4B;

    if (!isXlsx) {
      throw Exception(
        "Response bukan file XLSX valid. Content-Type: ${res.headers['content-type']}",
      );
    }

    if (bytes.length < 1000) {
      throw Exception(
        "File XLSX terlalu kecil (${bytes.length} bytes). Kemungkinan file dari backend terpotong atau workbook belum selesai dibuat.",
      );
    }

    final fileName =
        "${filePrefix}_${DateTime.now().millisecondsSinceEpoch}.xlsx";

    return ExportXlsxResult(bytes: bytes, fileName: fileName);
  }
}
