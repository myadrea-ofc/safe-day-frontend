import 'dart:html' as html;

Future<String> downloadImage({
  required String url,
  required String fileName,
}) async {
  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", fileName)
    ..target = "_blank";

  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();

  return "File diunduh melalui browser";
}
