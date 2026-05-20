import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:safety_apps/service/export_excel/excel_downloader.dart';
import 'package:safety_apps/service/export_excel/export_service.dart';
import 'package:safety_apps/service/export_excel/export_type.dart';

Future<void> exportExcelCurrentFilter({
  required BuildContext context,
  required bool canCurrentUserDownloadExcel,
  required ExportType type,
  required DateTimeRange? range,
  required VoidCallback onNoAccess,
  required VoidCallback onStartExporting,
  required VoidCallback onFinishExporting,
  Map<String, String?> extraQuery = const {},
}) async {
  if (!canCurrentUserDownloadExcel) {
    onNoAccess();
    return;
  }

  onStartExporting();

  try {
    final result = await ExportService.downloadExportXlsxBytes(
      endpoint: type.endpoint,
      filePrefix: type.filePrefix,
      start: range?.start,
      end: range?.end,
      extraQuery: extraQuery,
    );

    if (kIsWeb) {
      await downloadExcelFile(bytes: result.bytes, fileName: result.fileName);
    } else {
      await Share.shareXFiles([
        XFile.fromData(
          result.bytes,
          name: result.fileName,
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ),
      ], text: type.shareText);
    }

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("File Excel berhasil diexport")),
    );
  } catch (e) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Export gagal: $e")));
  } finally {
    onFinishExporting();
  }
}
