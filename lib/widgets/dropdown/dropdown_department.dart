import 'package:flutter/material.dart';

class DropdownDepartment extends StatelessWidget {
  final String? value;
  final Function(String?) onChanged;

  const DropdownDepartment({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const List<String> departmentList = [
    "HSES",
    "MINE",
    "Mining",
    "HRGA",
    "TRLO",
    "TECS",
    "ITTE",
    "IFXC",
    "PLANT",
    "Mine Contractor",
    "Hauling Contractor",
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
          hint: Text("Pilih Department"),
          items: departmentList
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
