import 'package:flutter/material.dart';

class DropdownKlasifikasiInsiden extends StatelessWidget {
  final String? value;
  final Function(String?) onChanged;

  const DropdownKlasifikasiInsiden({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const List<String> klasifikasiinsidenList = [
    "FAI (First Aid Incident)",
    "MTI (Medical Treatment Incident)",
    "LTI (Lost Time Incident)",
    "Fatality (Kematian)",
    "PD (Property Damage/Kerusakan Harta Benda)",
    "Fire Case Incident",
    "Environmental Damage (Kerusakan Lingkungan)",
    "Nearmiss",
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
          hint: Text("Pilih klasifikasi insiden"),
          items: klasifikasiinsidenList
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
