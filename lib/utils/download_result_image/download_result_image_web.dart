import 'dart:html' as html;

Future<String> downloadResultImage({
  required String url,
  required String fileName,
}) async {
  final name = fileName.split('/').last;

  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", name)
    ..target = "_blank";

  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();

  return "File diunduh melalui browser";
}
