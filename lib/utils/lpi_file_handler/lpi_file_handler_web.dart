import 'dart:html' as html;

Future<String> downloadLpiFile({
  required String url,
  required String fileName,
  bool isImage = false,
}) async {
  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", fileName)
    ..target = "_blank";

  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();

  return "File diunduh melalui browser";
}

Future<void> openLpiFile({
  required String url,
  required String fileName,
}) async {
  html.window.open(url, "_blank");
}
