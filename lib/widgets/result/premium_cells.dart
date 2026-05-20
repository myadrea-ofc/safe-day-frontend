import 'package:flutter/material.dart';
import 'package:safety_apps/widgets/result/table_helpers.dart';

Color _chipBg(String role) {
  final r = role.toLowerCase().trim();

  if (r == "superadmin") return const Color(0xFFDCFCE7);
  if (r == "admin") return const Color(0xFFFEF3C7);
  if (r == "member") return const Color(0xFFDBEAFE);

  return const Color(0xFFF3F4F6);
}

Color _chipText(String role) {
  final r = role.toLowerCase().trim();

  if (r == "superadmin") return const Color(0xFF166534);
  if (r == "admin") return const Color(0xFF92400E);
  if (r == "member") return const Color(0xFF1D4ED8);

  return const Color(0xFF374151);
}

Widget _buildChip(String text) {
  final safeText = text.isEmpty ? "-" : text;

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: _chipBg(safeText),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: _chipText(safeText).withOpacity(0.25)),
    ),
    child: Text(
      safeText,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: _chipText(safeText),
      ),
    ),
  );
}

Widget roleBadgePremium(String role) {
  return _buildChip(role);
}

Widget creatorRoleBadgePremium(String role) {
  return _buildChip(role);
}

Widget ratingCell(num? rating) {
  if (rating == null) {
    return buildResultCell("-");
  }

  final int rounded = rating.round();

  Color bg = const Color(0xFFF3F4F6);
  Color fg = const Color(0xFF374151);

  if (rounded >= 1 && rounded <= 2) {
    bg = const Color(0xFFFEE2E2);
    fg = const Color(0xFF991B1B);
  } else if (rounded >= 3 && rounded <= 5) {
    bg = const Color(0xFFFEF3C7);
    fg = const Color(0xFF92400E);
  }

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: fg.withOpacity(0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_rounded, size: 16, color: fg),
            const SizedBox(width: 6),
            Text(
              rating.toString(),
              style: TextStyle(fontWeight: FontWeight.w800, color: fg),
            ),
          ],
        ),
      ),
    ),
  );
}
