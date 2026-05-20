import 'package:flutter/material.dart';

Future<void> showNoExcelAccessDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Akses Download Ditolak"),
      content: const Text(
        "Akun kamu belum diberi akses untuk mendownload Excel.\n"
        "Silakan hubungi Admin Site / HO untuk memberikan akses.",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Tutup"),
        ),
      ],
    ),
  );
}
