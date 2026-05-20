import 'dart:html' as html;

Future<String> downloadLpiGallery({
  required List<String> fotoPaths,
  required void Function(int current, int total) onProgress,
}) async {
  final total = fotoPaths.length;

  if (total == 0) {
    throw "Tidak ada foto untuk diunduh";
  }

  for (int i = 0; i < fotoPaths.length; i++) {
    final foto = fotoPaths[i];
    final name = foto.split('/').last;
    final url = "http://safety.borneo.co.id/uploads/$foto";

    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", name)
      ..target = "_blank";

    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();

    onProgress(i + 1, total);

    await Future.delayed(const Duration(milliseconds: 250));
  }

  return "File diunduh melalui browser";
}
