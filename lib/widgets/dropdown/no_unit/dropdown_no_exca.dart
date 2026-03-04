import 'package:flutter/material.dart';

class DropdownNoUnitExca extends StatelessWidget {
  final String? value;
  final Function(String?) onChanged;

  const DropdownNoUnitExca({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const List<String> noexcaList = [
    "PC200-KOM 1011H",
    "PC200-KOM 1012H",
    "PC200-KOM 1025",
    "PC200-KOM 1031",
    "PC200-KOM 1032",
    "PC200-KOM 1044",
    "PC300-KOM 1059",
    "PC200-KOM 1060",
    "PC200-KOM 1066H",
    "PC200-KOM 1067H",
    "PC200-KOM 1069H",
    "PC210-KOM 1140",
    "PC400-KOM 2065",
    "PC400-KOM 2091H",
    "PC400-KOM 2093H",
    "PC400-KOM 2094H",
    "PC500-KOM 2124",
    "PC500-KOM 2127",
    "PC800-KOM 3095H",
    "PC800-KOM 3097H",
    "PC800-KOM 3098H",
    "R9250-LIE 4003",
    "R9250-LIE 4004",
    "R9250-LIE 4007H",
    "R9250-LIE 4008H",
    "R9200-LIE 4076",
    "R9200-LIE 4077",
    "R9200-LIE 4078",
    "R9200-LIE 4079",
    "R9350-LIE 5052",
    "R9350-LIE 5053",
    "R9350-LIE 5054",
    "R9350-LIE 5072H",
    "R9350-LIE 5073",
    "R9350-LIE 5074H",
    "PC200-SUM 1100H",
    "PC200-SUM 1101H",
    "PC200-SUM 1102H",
    "PC200-SUM 1103H",
    "PC200-SUM 1104H",
    "PC200-SUM 1105H",
    "PC200-SUM 1106H",
    "PC200-SUM 1108H",
    "PR776-LIE 3077",
    "PC200-HYU 1002",
    "PC200-KOB 1003",
    "PC300-SUMI 1008",
    "PC200-ZOM 1010H",
    "PC200-ZOM 1011H",
    "PC800-LIU 3133",
    "PC800-LIU 3134",
    "PC800-LIU 3135",
    "PC800-LIU 3136",
    "PC800-LIU 3137",
    "PC135-KOM 1070",
    "PC135-KOM 1071",
    "PC200-KOM 1116",
    "PC210-KOM 1117",
    "PC210-KOM 1118",
    "PC210-KOM 1119",
    "PC210-KOM 1119",
    "PC300-SUMI 1120",
    "PC300-SUMI 1122",
    "PC365-KOM 1125",
    "PC500-KOM 2126",
    "PC500-KOM 2128",
    "PC500-KOM 2129",
    "PC500-KOM 2130",
    "PC500-KOM 2131",
    "PC500-KOM 2132",
    "R9100-LIE-4011",
    "R9100-LIE-4012",
    "R9300-LIE-5080",
    "R9300-LIE-5081",
    "PC800-SAN-3138",
    "PC800-SAN-3139",
    "PC800-SHT-3140",
    "PC800-SHT-3141",
    "PC1250-SHT 4013",
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
          hint: Text("Pilih No Unit"),
          items: noexcaList
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
