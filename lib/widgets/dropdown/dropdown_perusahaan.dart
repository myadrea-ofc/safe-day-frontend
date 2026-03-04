import 'package:flutter/material.dart';

class DropdownPerusahaan extends StatelessWidget {
  final String? value;
  final Function(String?) onChanged;

  const DropdownPerusahaan({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const List<String> perusahaanList = [
    "PT Mantimin Coal Mining",
    "PT Bagas Bumi Persada",
    "PT Liebherr Perkasa Indonesia",
    "PT EBB",
    "PT Bagong Motor",
    "Mine Contractor",
    "Hauling Contractor",
    "Subkontraktor",
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
          hint: Text("Pilih Perusahaan"),
          items: perusahaanList
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
