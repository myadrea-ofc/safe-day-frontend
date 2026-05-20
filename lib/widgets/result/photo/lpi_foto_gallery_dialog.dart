import 'package:flutter/material.dart';
import 'package:safety_apps/models/lpi.dart';
import 'package:safety_apps/utils/download_lpi_gallery/download_lpi_gallery.dart';
import 'package:safety_apps/widgets/result/detail_helpers.dart';
import 'package:safety_apps/widgets/result/page_style.dart';

class LpiFotoGalleryDialogHelper {
  final BuildContext context;

  int _currentDownload = 0;
  int _totalDownload = 0;
  VoidCallback? _updateProgressDialog;

  LpiFotoGalleryDialogHelper({required this.context});

  void showFotoGallery(LPIModel e) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildResultDialogHeader("Foto Kejadian (${e.fotoPaths.length})"),
            SizedBox(
              height: 220,
              child: PageView.builder(
                itemCount: e.fotoPaths.length,
                controller: PageController(viewportFraction: 0.9),
                itemBuilder: (_, i) {
                  final path = e.fotoPaths[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        "http://safety.borneo.co.id/uploads/$path",
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            const Center(child: Text("Gagal memuat foto")),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
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
                    "Download Semua Foto",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    await downloadAllFoto(e);
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

  Future<void> downloadAllFoto(LPIModel e) async {
    _currentDownload = 0;
    _totalDownload = e.fotoPaths.length;

    if (_totalDownload == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tidak ada foto untuk diunduh")),
      );
      return;
    }

    _showProgressDialog();

    try {
      final resultPath = await downloadLpiGallery(
        fotoPaths: e.fotoPaths,
        onProgress: (current, total) {
          _currentDownload = current;
          _totalDownload = total;
          _updateProgressDialog?.call();
        },
      );

      Navigator.of(context, rootNavigator: true).pop();
      _showSuccessDialog(resultPath);
    } catch (error) {
      Navigator.of(context, rootNavigator: true).pop();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal download: $error")));
    }
  }

  void _showSuccessDialog(String folderPath) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              const Text(
                "Download Berhasil",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                folderPath,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Tutup"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProgressDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            _updateProgressDialog = () {
              setStateDialog(() {});
            };

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 20),
                    Text(
                      "Mengunduh $_currentDownload / $_totalDownload foto",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
