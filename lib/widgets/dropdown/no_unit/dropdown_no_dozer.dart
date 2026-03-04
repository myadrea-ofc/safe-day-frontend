import 'package:flutter/material.dart';

class DropdownNoDozer extends StatelessWidget {
  final String? value;
  final Function(String?) onChanged;

  const DropdownNoDozer({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const List<String> noDozerList = [
    "D155-LIU 2101",
    "D155-LIU 2102",
    "D31-KOM 1030",
    "D31-KOM 1031",
    "D85SS-KOM 1074",
    "D85SS-KOM 1076",
    "D85SS-KOM 1077",
    "D85SS-KOM 1078",
    "D85SS-KOM 1079",
    "D85SS-KOM 1080",
    "D65-KOM 1089",
    "D65-KOM 1090",
    "D85SS-KOM 1091",
    "D85SS-KOM 1092",
    "D85SS-KOM 1093",
    "D85SS-KOM 1094",
    "D85SS-KOM 1095",
    "D85SS-KOM 1096",
    "D85SS-KOM 1097",
    "D85SS-KOM 1098",
    "D85SS-KOM 1099",
    "D85SS-KOM 1100",
    "D39-KOM 1101",
    "D39-KOM 1102",
    "D155-KOM 2104",
    "D155-KOM 2105",
    "PR776-LIE 3074",
    "PR776-LIE 3075",
    "PR776-LIE 3076",
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
          hint: Text("Pilih No Dozer"),
          items: noDozerList
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
