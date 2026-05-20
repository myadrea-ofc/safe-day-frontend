import 'dart:typed_data';
import 'dart:html' as html;

Future<void> downloadExcelFileImpl({
  required Uint8List bytes,
  required String fileName,
}) async {
  final blob = html.Blob([
    bytes,
  ], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');

  final url = html.Url.createObjectUrlFromBlob(blob);

  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();

  html.Url.revokeObjectUrl(url);
}
