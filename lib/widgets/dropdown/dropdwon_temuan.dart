import 'package:flutter/material.dart';

class DropdownTemuan extends StatelessWidget {
  final String? value;
  final Function(String?) onChanged;

  const DropdownTemuan({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const List<String> temuanList = [
    "Kondisi Tidak Aman (KTA)",
    "Tindakan Tidak Aman (TTA)",
    "Lainnya",
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton(
          value: value,
          isExpanded: true,
          hint: Text("Pilih Temuan"),
          items: temuanList
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
