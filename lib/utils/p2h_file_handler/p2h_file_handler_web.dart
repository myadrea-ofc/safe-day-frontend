import 'dart:html' as html;

Future<void> openP2HFile({
  required String url,
  required String fileName,
}) async {
  html.window.open(url, "_blank");
}

Future<String> downloadP2HFile({
  required String url,
  required String fileName,
  bool isImage = false,
  void Function(String value)? onProgressText,
}) async {
  onProgressText?.call("Menyiapkan unduhan...");

  final safeName = fileName.split('/').last;

  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", safeName)
    ..target = "_blank";

  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();

  return "File diunduh melalui browser";
}
