import 'package:flutter/material.dart';

DataRow buildEmptyRow(int columnCount) {
  return DataRow(
    cells: List.generate(columnCount, (_) => const DataCell(SizedBox())),
  );
}
