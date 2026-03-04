import 'package:flutter/material.dart';
import 'opsi_button.dart';

class OpsiRow2 extends StatelessWidget {
  final String? selected;
  final Function(String) onSelected;

  const OpsiRow2({super.key, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OpsiButton(
            text: "Layak",
            active: selected == "Layak",
            onTap: () => onSelected("Layak"),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: OpsiButton(
            text: "Tidak",
            active: selected == "Tidak",
            onTap: () => onSelected("Tidak"),
          ),
        ),
      ],
    );
  }
}
