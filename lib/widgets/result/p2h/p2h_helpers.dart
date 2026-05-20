import 'package:flutter/material.dart';
import 'package:safety_apps/widgets/result/page_style.dart';

String normStatus(String? v) => (v ?? '').trim().toLowerCase();

enum StatusKind { yes, no, ok, bad, warn, none }

StatusKind kindStatus(String? v) {
  final t = normStatus(v);

  // YES/NO
  if (t == "iya" || t == "ya" || t == "yes") return StatusKind.yes;
  if (t == "tidak" || t == "no") return StatusKind.no;

  if (t == "layak" || t == "baik" || t == "ok") return StatusKind.ok;
  if (t == "tidak") return StatusKind.bad;

  if (t == "ada & layak" || t == "ada dan layak") return StatusKind.ok;
  if (t == "tidak berfungsi" || t == "rusak") return StatusKind.warn;
  if (t == "tidak ada") return StatusKind.bad;

  // N/A
  if (t == "n/a" || t == "na") return StatusKind.warn;

  return StatusKind.none;
}

Color kBg(StatusKind k) {
  switch (k) {
    case StatusKind.yes:
    case StatusKind.ok:
      return Colors.green.withOpacity(0.12);
    case StatusKind.no:
    case StatusKind.bad:
      return Colors.red.withOpacity(0.12);
    case StatusKind.warn:
      return Colors.amber.withOpacity(0.18);
    case StatusKind.none:
      return const Color(0xfff5f7fb);
  }
}

Color kBorder(StatusKind k) {
  switch (k) {
    case StatusKind.yes:
    case StatusKind.ok:
      return Colors.green.withOpacity(0.35);
    case StatusKind.no:
    case StatusKind.bad:
      return Colors.red.withOpacity(0.35);
    case StatusKind.warn:
      return Colors.amber.withOpacity(0.45);
    case StatusKind.none:
      return const Color(0xffe8ecf3);
  }
}

Color kText(StatusKind k) {
  switch (k) {
    case StatusKind.yes:
    case StatusKind.ok:
      return Colors.green.shade800;
    case StatusKind.no:
    case StatusKind.bad:
      return Colors.red.shade800;
    case StatusKind.warn:
      return Colors.amber.shade900;
    case StatusKind.none:
      return Colors.black;
  }
}

IconData kIcon(StatusKind k) {
  switch (k) {
    case StatusKind.yes:
    case StatusKind.ok:
      return Icons.check_circle_rounded;
    case StatusKind.no:
    case StatusKind.bad:
      return Icons.cancel_rounded;
    case StatusKind.warn:
      return Icons.warning_amber_rounded;
    case StatusKind.none:
      return Icons.info_outline;
  }
}

Widget docBtn({
  required List<String> files,
  required VoidCallback onShowFiles,
}) {
  return InkWell(
    borderRadius: BorderRadius.circular(14),
    onTap: () {
      if (files.isEmpty) return;
      onShowFiles();
    },
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ResultPageStyle.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ResultPageStyle.primary.withOpacity(0.14)),
      ),
      child: ShaderMask(
        shaderCallback: (bounds) =>
            ResultPageStyle.primaryGradient.createShader(bounds),
        child: const Icon(
          Icons.attach_file_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    ),
  );
}

Widget statusBaseChip(Color base, IconData icon, String v) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: base.withOpacity(0.12),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: base.withOpacity(0.35)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: base),
        const SizedBox(width: 6),
        Text(
          v,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 12,
            color: base,
          ),
        ),
      ],
    ),
  );
}

Widget statusChip<T>({
  required String v,
  required T Function(String value) kind,
  required String Function(String value) norm,
  required IconData Function(T kindValue) iconOf,
  required T noneKind,
  required T yesKind,
  required T okKind,
  required T warnKind,
}) {
  final k = kind(v);

  // kalau masih ada status "open"
  if (norm(v) == "open") {
    final base = Colors.orange;
    return statusBaseChip(base, Icons.timelapse_rounded, v);
  }

  if (k == noneKind) {
    return statusBaseChip(Colors.blueGrey, Icons.info_outline, v);
  }

  final base = (k == yesKind || k == okKind)
      ? Colors.green
      : (k == warnKind ? Colors.amber : Colors.red);

  final icon = iconOf(k);
  return statusBaseChip(base, icon, v);
}
