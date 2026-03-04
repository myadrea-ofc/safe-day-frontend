import 'package:flutter/material.dart';

class DropdownNoLambungHeavyDuty extends StatelessWidget {
  final String? value;
  final Function(String?) onChanged;

  const DropdownNoLambungHeavyDuty({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const List<String> noHeavyDutyList = [
    "DT120-XCM 4001",
    "DT120-XCM 4002",
    "DT120-XCM 4003",
    "DT120-XCM 4004",
    "DT120-XCM 4005",
    "DT120-XCM 4006",
    "DT120-XCM 4007",
    "DT120-XCM 4008",
    "DT120-XCM 4009",
    "DT120-XCM 4010",
    "DT120-XCM 4011",
    "DT120-XCM 4012",
    "DT120-XCM 4013",
    "DT120-XCM 4014",
    "DT120-XCM 4015",
    "DT120-XCM 4016",
    "DT120-XCM 4017",
    "DT120-XCM 4018",
    "DT120-XCM 4019",
    "DT120-XCM 4020",
    "DT120-XCM 4021",
    "DT60-LIU 3001",
    "DT60-LIU 3002",
    "DT60-LIU 3003",
    "DT60-LIU 3004",
    "DT60-LIU 3005",
    "DT60-LIU 3006",
    "DT60-LIU 3007",
    "DT60-LIU 3008",
    "DT60-LIU 3009",
    "DT60-LIU 3010",
    "DT60-LIU 3011",
    "DT60-LIU 3012",
    "DT60-LIU 3013",
    "DT60-LIU 3014",
    "DT60-LIU 3015",
    "DT60-LIU 3016",
    "DT60-LIU 3017",
    "DT60-LIU 3018",
    "DT60-LIU 3019",
    "DT60-LIU 3020",
    "DT60-LIU 3021",
    "DT60-LIU 3022",
    "DT60-LIU 3023",
    "DT60-LIU 3024",
    "DT60-LIU 3025",
    "DT60-LIU 3026",
    "DT60-LIU 3027",
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
          items: noHeavyDutyList
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
