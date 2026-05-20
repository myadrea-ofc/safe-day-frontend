import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:safety_apps/widgets/result/page_style.dart';

bool isYesNoValue(String? v) {
  if (v == null) return false;
  final t = v.toLowerCase().trim();
  return t == "iya" ||
      t == "tidak" ||
      t == "n/a" ||
      t == "na" ||
      t == "yes" ||
      t == "ya" ||
      t == "no";
}

Color statusBg(String? v) {
  final t = (v ?? "").toLowerCase().trim();

  if (t == "ya" || t == "yes") {
    return Colors.green.withOpacity(0.12);
  } else if (t == "iya" || t == "yes") {
    return Colors.green.withOpacity(0.12);
  } else if (t == "tidak" || t == "no") {
    return Colors.red.withOpacity(0.12);
  } else if (t == "n/a" || t == "na") {
    return Colors.amber.withOpacity(0.18);
  }

  return const Color(0xfff5f7fb); // default biru muda lama
}

Color statusBorder(String? v) {
  final t = (v ?? "").toLowerCase().trim();

  if (t == "ya" || t == "yes") {
    return Colors.green.withOpacity(0.35);
  } else if (t == "iya" || t == "yes") {
    return Colors.green.withOpacity(0.35);
  } else if (t == "tidak" || t == "no") {
    return Colors.red.withOpacity(0.35);
  } else if (t == "n/a" || t == "na") {
    return Colors.amber.withOpacity(0.45);
  }

  return const Color(0xffe8ecf3);
}

Color statusText(String? v) {
  final t = (v ?? "").toLowerCase().trim();

  if (t == "ya" || t == "yes") {
    return Colors.green.shade800;
  } else if (t == "iya" || t == "yes") {
    return Colors.green.shade800;
  } else if (t == "tidak" || t == "no") {
    return Colors.red.shade800;
  } else if (t == "n/a" || t == "na") {
    return Colors.amber.shade900;
  }

  return Colors.black;
}

IconData statusIcon(String? v) {
  final t = (v ?? "").toLowerCase().trim();
  if (t == "ya" || t == "yes") return Icons.check_circle_rounded;
  if (t == "iya" || t == "yes") return Icons.check_circle_rounded;
  if (t == "tidak" || t == "no") return Icons.cancel_rounded;
  if (t == "n/a" || t == "na") return Icons.warning_amber_rounded;
  return Icons.info_outline;
}

Widget inspeksiFlatBox(String label, String? value, {bool isLongText = false}) {
  final safeValue = (value ?? "-").trim();
  final isStatusValue = isYesNoValue(value);

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
          color: isStatusValue ? statusBg(value) : const Color(0xfff5f7fb),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isStatusValue
                ? statusBorder(value)
                : const Color(0xffe8ecf3),
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
                        color: statusText(value),
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: statusBorder(value).withOpacity(0.20),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: statusBorder(value),
                        width: 1.4,
                      ),
                    ),
                    child: Icon(
                      statusIcon(value),
                      size: 18,
                      color: statusText(value),
                    ),
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

Widget inspeksiDialogHeader(String title) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: BoxDecoration(
      gradient: ResultPageStyle.primaryGradient,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
    ),
    child: Center(
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}

String formatTanggal(String? value) {
  if (value == null || value.isEmpty) return "-";
  try {
    final date = DateTime.parse(value);
    return DateFormat("dd/MM/yyyy").format(date);
  } catch (_) {
    return value;
  }
}
