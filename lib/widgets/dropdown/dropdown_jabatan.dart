import 'package:flutter/material.dart';

class DropdownJabatan extends StatelessWidget {
  final String? value;
  final Function(String?) onChanged;

  const DropdownJabatan({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const List<String> jabatanList = [
    "Manager",
    "Superintendent",
    "Supervisor",
    "Foreman",
    "Officer",
    "Mekanik",
    "Electrical",
    "Operator HD",
    "Operator DT",
    "Helper",
    "Admin",
    "Site Director",
    "Welder",
    "Tyreman",
    "Safetyman",
    "Driver",
    "Administrasi / Clerk",
    "KTT",
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
          hint: Text("Pilih Jabatan"),
          items: jabatanList
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
