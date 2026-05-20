import 'package:flutter/material.dart';
import 'package:safety_apps/utils/download_image/download_image.dart';
import 'package:safety_apps/widgets/result/page_style.dart';

Future<void> showFoto({
  required BuildContext context,
  required String? fileName,
  required String title,
  required Widget Function(String title) buildResultDialogHeader,
}) async {
  if (fileName == null || fileName.isEmpty || fileName == "null") {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Foto $title tidak tersedia")));
    return;
  }

  await showDialog(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildResultDialogHeader("Detail P5M"),
          Padding(
            padding: const EdgeInsets.all(14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                "http://safety.borneo.co.id/uploads/$fileName",
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Column(
                  children: [
                    Icon(Icons.broken_image, size: 50, color: Colors.grey),
                    Text("Gagal memuat gambar"),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: ResultPageStyle.primaryGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.download, color: Colors.white),
                label: const Text(
                  "Download Gambar",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                onPressed: () async {
                  Navigator.pop(context);

                  await _downloadWithPopup(
                    context: context,
                    url: "http://safety.borneo.co.id/uploads/$fileName",
                    fileName: fileName,
                  );
                },
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup"),
          ),
          const SizedBox(height: 10),
        ],
      ),
    ),
  );
}

Future<void> _downloadWithPopup({
  required BuildContext context,
  required String url,
  required String fileName,
}) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text("Mengunduh gambar..."),
          ],
        ),
      ),
    ),
  );

  String savedPath = "";

  try {
    savedPath = await downloadImage(url: url, fileName: fileName);
  } catch (e) {
    Navigator.pop(context);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Download gagal"),
        content: Text("$e"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup"),
          ),
        ],
      ),
    );
    return;
  }

  Navigator.pop(context);

  showDialog(
    context: context,
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 16),
            const Text(
              "Download Berhasil",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              savedPath,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff1d63ff), Color(0xff4fa9ff)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  "Tutup",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
