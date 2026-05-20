import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Widget buildResultCell(String text, {FontWeight? weight}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: Align(
      alignment: Alignment.center,
      child: Tooltip(
        message: text,
        child: Text(
          text.isEmpty ? "-" : text,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: weight ?? FontWeight.w700,
            color: Colors.black.withOpacity(0.72),
          ),
        ),
      ),
    ),
  );
}

Widget buildResultCellWrap(String text) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: Align(
      alignment: Alignment.center,
      child: Text(
        text.isEmpty ? "-" : text,
        textAlign: TextAlign.center,
        softWrap: true,
        style: TextStyle(
          height: 1.35,
          color: Colors.black.withOpacity(0.72),
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

String formatResultTanggal(DateTime? dt) {
  if (dt == null) return "-";
  return DateFormat("dd/MM/yyyy").format(dt);
}
