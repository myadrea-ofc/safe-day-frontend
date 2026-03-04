import 'package:flutter/material.dart';
import 'opsi_button.dart';

class OpsiRow3 extends StatelessWidget {
  final String? selected;
  final Function(String) onSelected;

  const OpsiRow3({super.key, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OpsiButton(
            text: "Iya",
            active: selected == "Iya",
            onTap: () => onSelected("Iya"),
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
        SizedBox(width: 10),
        Expanded(
          child: OpsiButton(
            text: "N/A",
            active: selected == "N/A",
            onTap: () => onSelected("N/A"),
          ),
        ),
      ],
    );
  }
}
