import 'package:flutter/material.dart';

class DropdownNoLambungLV extends StatelessWidget {
  final String? value;
  final Function(String?) onChanged;

  const DropdownNoLambungLV({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const List<String> jabatanList = [
    "LVDC-TOY 1147",
    "LVDC-TOY 1148",
    "LVDC-TOY 1149",
    "LVDC-TOY 1150",
    "LVDC-TOY 1151",
    "LVDC-TOY 1152",
    "LVDC-TOY 1153",
    "LVDC-TOY 1154",
    "LVDC-TOY 1155",
    "LVDC-TOY 1156",
    "LVDC-TOY 1157",
    "LVDC-TOY 1158",
    "LVDC-TOY 1159",
    "LVDC-TOY 1160",
    "LVDC-TOY 1161",
    "LVDC-TOY 1162",
    "LVDC-TOY 1163",
    "LVDC-TOY 1164",
    "LVDC-TOY 1165",
    "LVDC-TOY 1166",
    "LVDC-TOY 1167",
    "LVDC-TOY 1168",
    "LVDC-TOY 1169",
    "LVDC-TOY 1170",
    "LVDC-TOY 1172",
    "LVDC-TOY 1173",
    "LVDC-TOY 1174",
    "Ambulance-MIT 1171",
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
          hint: Text("Pilih No Lambung"),
          items: jabatanList
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
