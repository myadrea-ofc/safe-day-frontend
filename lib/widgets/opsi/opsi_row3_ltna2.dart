import 'package:flutter/material.dart';
import 'package:safety_apps/widgets/opsi/opsi_button2.dart';

class OpsiRow3Ltna2 extends StatelessWidget {
  final String? selected;
  final Function(String) onSelected;

  const OpsiRow3Ltna2({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OpsiButton2(
            text: "Ada & Layak",
            active: selected == "Ada & Layak",
            onTap: () => onSelected("Ada & Layak"),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: OpsiButton2(
            text: "Tidak Berfungsi",
            active: selected == "Tidak Berfungsi",
            onTap: () => onSelected("Tidak Berfungsi"),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: OpsiButton2(
            text: "Tidak Ada",
            active: selected == "Tidak Ada",
            onTap: () => onSelected("Tidak Ada"),
          ),
        ),
      ],
    );
  }
}
