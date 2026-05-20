import 'package:flutter/material.dart';

Widget chipApar(String? text) {
  final t = (text ?? "-").trim().toLowerCase();

  // warna sesuai rule
  Color bg;
  Color border;
  Color fg;

  if (t == "ya" || t == "yes") {
    bg = Colors.green.withOpacity(0.12);
    border = Colors.green.withOpacity(0.35);
    fg = Colors.green.shade800;
  } else if (t == "tidak" || t == "no") {
    bg = Colors.red.withOpacity(0.12);
    border = Colors.red.withOpacity(0.35);
    fg = Colors.red.shade800;
  } else if (t == "n/a" || t == "na" || t == "n.a") {
    bg = Colors.amber.withOpacity(0.18);
    border = Colors.amber.withOpacity(0.45);
    fg = Colors.amber.shade900;
  } else {
    // fallback kalau datanya aneh / kosong
    bg = Colors.grey.withOpacity(0.12);
    border = Colors.grey.withOpacity(0.30);
    fg = Colors.grey.shade800;
  }

  // tampilkan label rapih
  String label;
  if (t == "ya" || t == "yes")
    label = "Ya";
  else if (t == "tidak" || t == "no")
    label = "Tidak";
  else if (t == "n/a" || t == "na" || t == "n.a")
    label = "N/A";
  else
    label = (text == null || text.trim().isEmpty) ? "-" : text.trim();

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: border),
    ),
    child: Text(
      label,
      style: TextStyle(fontWeight: FontWeight.w900, color: fg),
    ),
  );
}
