import 'package:flutter/material.dart';

Widget buildResultDialogHeader(String title) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [Color(0xff1d63ff), Color(0xff4fa9ff)]),
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
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

Widget buildResultSectionTitle(String title) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xff1d63ff), Color(0xff4fa9ff)],
      ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 1.2,
        ),
      ),
    ),
  );
}

Widget buildResultFlatBox(
  String label,
  String value, {
  bool isLongText = false,
  bool isStatus = false,
  String? statusValue,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey[600],
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 6),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xfff5f7fb),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xffe8ecf3)),
        ),
        child: isStatus
            ? Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: statusValue?.toLowerCase() == "open"
                          ? Colors.orange
                          : Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    value.isEmpty ? "-" : value,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              )
            : Text(
                value.isEmpty ? "-" : value,
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
