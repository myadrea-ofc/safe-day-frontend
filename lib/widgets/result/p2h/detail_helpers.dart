import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:safety_apps/utils/p2h_file_handler/p2h_file_handler.dart';
import 'package:safety_apps/widgets/result/p2h/p2h_helpers.dart';
import 'package:safety_apps/widgets/result/page_style.dart';

Widget flatBoxP2H(String label, String? value, {bool isLongText = false}) {
  final safeValue = (value ?? "-").trim();
  final k = kindStatus(value);
  final isStatusValue = k != StatusKind.none;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 15,
          color: Colors.grey[600],
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 6),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isStatusValue ? kBg(k) : const Color(0xfff5f7fb),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isStatusValue ? kBorder(k) : const Color(0xffe8ecf3),
          ),
        ),
        child: isStatusValue
            ? Row(
                children: [
                  Expanded(
                    child: Text(
                      safeValue.isEmpty ? "-" : safeValue,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: kText(k),
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: kBorder(k).withOpacity(0.20),
                      shape: BoxShape.circle,
                      border: Border.all(color: kBorder(k), width: 1.4),
                    ),
                    child: Icon(kIcon(k), size: 18, color: kText(k)),
                  ),
                ],
              )
            : Text(
                safeValue.isEmpty ? "-" : safeValue,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.black,
                  height: isLongText ? 1.5 : 1.2,
                ),
              ),
      ),
    ],
  );
}

Widget pairP2H(
  BuildContext context,
  Widget a,
  Widget b, {
  double breakpoint = 520,
  double gap = 12,
}) {
  return LayoutBuilder(
    builder: (context, c) {
      final oneColumn = c.maxWidth < breakpoint;

      if (oneColumn) {
        return Column(
          children: [
            a,
            SizedBox(height: gap),
            b,
          ],
        );
      }

      return Row(
        children: [
          Expanded(child: a),
          SizedBox(width: gap),
          Expanded(child: b),
        ],
      );
    },
  );
}

enum P2HFileKind { image, pdf, excel, csv, word, other }

P2HFileKind getP2HFileKind(String path) {
  final p = path.toLowerCase().split('?').first;

  if (p.endsWith('.jpg') ||
      p.endsWith('.jpeg') ||
      p.endsWith('.png') ||
      p.endsWith('.webp') ||
      p.endsWith('.heic')) {
    return P2HFileKind.image;
  }

  if (p.endsWith('.pdf')) return P2HFileKind.pdf;

  if (p.endsWith('.xls') || p.endsWith('.xlsx')) {
    return P2HFileKind.excel;
  }

  if (p.endsWith('.csv')) return P2HFileKind.csv;

  if (p.endsWith('.doc') || p.endsWith('.docx')) {
    return P2HFileKind.word;
  }

  return P2HFileKind.other;
}

IconData getP2HFileIcon(String path) {
  switch (getP2HFileKind(path)) {
    case P2HFileKind.image:
      return Icons.image_outlined;
    case P2HFileKind.pdf:
      return Icons.picture_as_pdf_outlined;
    case P2HFileKind.excel:
      return Icons.table_chart_outlined;
    case P2HFileKind.csv:
      return Icons.grid_on_outlined;
    case P2HFileKind.word:
      return Icons.description_outlined;
    case P2HFileKind.other:
      return Icons.insert_drive_file_outlined;
  }
}

Color getP2HFileColor(String path) {
  switch (getP2HFileKind(path)) {
    case P2HFileKind.image:
      return Colors.blue.shade700;
    case P2HFileKind.pdf:
      return Colors.red.shade700;
    case P2HFileKind.excel:
    case P2HFileKind.csv:
      return Colors.green.shade700;
    case P2HFileKind.word:
      return Colors.indigo.shade700;
    case P2HFileKind.other:
      return Colors.grey.shade700;
  }
}

Color getP2HFileBgColor(String path) {
  switch (getP2HFileKind(path)) {
    case P2HFileKind.image:
      return Colors.blue.shade50;
    case P2HFileKind.pdf:
      return Colors.red.shade50;
    case P2HFileKind.excel:
    case P2HFileKind.csv:
      return Colors.green.shade50;
    case P2HFileKind.word:
      return Colors.indigo.shade50;
    case P2HFileKind.other:
      return Colors.grey.shade100;
  }
}

void showFilesDialogP2H({
  required BuildContext context,
  required List<String> files,
  required bool Function(String path) isImageFile,
}) {
  showDialog(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xfff9fafc),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: ResultPageStyle.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.folder_open_rounded, color: Colors.white),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Dokumen Terlampir",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...files.map((file) {
              final isImage = isImageFile(file);
              final fileIcon = getP2HFileIcon(file);
              final fileColor = getP2HFileColor(file);
              final fileBgColor = getP2HFileBgColor(file);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: fileBgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(fileIcon, color: fileColor, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        file,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Color(0xff333333),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.visibility_outlined,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                      tooltip: "Preview",
                      onPressed: () async {
                        Navigator.pop(context);
                        if (isImage) {
                          previewImageP2H(context: context, file: file);
                        } else {
                          await downloadAndOpenFileP2H(
                            context: context,
                            url: "http://safety.borneo.co.id/uploads/$file",
                            fileName: file,
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.download_outlined,
                        color: Colors.green.shade700,
                        size: 20,
                      ),
                      tooltip: "Download",
                      onPressed: () {
                        Navigator.pop(context);
                        downloadWithPopupP2H(
                          context: context,
                          url: "http://safety.borneo.co.id/uploads/$file",
                          fileName: file,
                          isImage: isImage,
                        );
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: ResultPageStyle.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Tutup",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
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

void previewImageP2H({required BuildContext context, required String file}) {
  final controller = TransformationController();
  TapDownDetails? doubleTapDetails;

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: "",
    barrierColor: Colors.transparent,
    pageBuilder: (_, __, ___) {
      double dragOffset = 0;

      return StatefulBuilder(
        builder: (context, setState) {
          return GestureDetector(
            onVerticalDragUpdate: (details) {
              dragOffset += details.delta.dy;
              setState(() {});
            },
            onVerticalDragEnd: (_) {
              if (dragOffset.abs() > 120) {
                Navigator.pop(context);
              } else {
                setState(() => dragOffset = 0);
              }
            },
            child: Stack(
              children: [
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(color: Colors.black.withOpacity(0.6)),
                ),
                Transform.translate(
                  offset: Offset(0, dragOffset),
                  child: Center(
                    child: Hero(
                      tag: file,
                      child: GestureDetector(
                        onDoubleTapDown: (details) =>
                            doubleTapDetails = details,
                        onDoubleTap: () {
                          final position = doubleTapDetails!.localPosition;
                          if (controller.value != Matrix4.identity()) {
                            controller.value = Matrix4.identity();
                          } else {
                            controller.value = Matrix4.identity()
                              ..translate(-position.dx * 2, -position.dy * 2)
                              ..scale(3.0);
                          }
                        },
                        child: InteractiveViewer(
                          transformationController: controller,
                          minScale: 1,
                          maxScale: 4,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              "http://safety.borneo.co.id/uploads/$file",
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const SizedBox(
                                  height: 300,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              },
                              errorBuilder: (_, __, ___) => const SizedBox(
                                height: 300,
                                child: Center(
                                  child: Text(
                                    "Gagal memuat gambar",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  right: 20,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(Icons.close, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Future<void> downloadAndOpenFileP2H({
  required BuildContext context,
  required String url,
  required String fileName,
}) async {
  try {
    await openP2HFile(url: url, fileName: fileName);
  } catch (e) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Gagal membuka file"),
        content: Text(e.toString()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup"),
          ),
        ],
      ),
    );
  }
}

void showDownloadProgressDialogP2H(
  BuildContext context,
  ValueNotifier<String> text,
) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(width: 16),
              ValueListenableBuilder<String>(
                valueListenable: text,
                builder: (_, value, __) {
                  return Text(value, style: const TextStyle(fontSize: 14));
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

void showDownloadSuccessDialogP2H(BuildContext context, String filePath) {
  showDialog(
    context: context,
    builder: (_) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 30),
              ),
              const SizedBox(height: 16),
              const Text(
                "Download Berhasil",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                filePath,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Tutup"),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> downloadWithPopupP2H({
  required BuildContext context,
  required String url,
  required String fileName,
  bool isImage = false,
}) async {
  final progressText = ValueNotifier("Menyiapkan unduhan...");
  showDownloadProgressDialogP2H(context, progressText);

  try {
    final filePath = await downloadP2HFile(
      url: url,
      fileName: fileName,
      isImage: isImage,
      onProgressText: (value) {
        progressText.value = value;
      },
    );

    Navigator.of(context, rootNavigator: true).pop();
    showDownloadSuccessDialogP2H(context, filePath);
  } catch (e) {
    Navigator.of(context, rootNavigator: true).pop();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Download gagal: $e")));
  }
}
