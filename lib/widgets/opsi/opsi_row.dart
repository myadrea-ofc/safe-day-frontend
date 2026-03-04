import 'package:flutter/material.dart';
import 'opsi_button.dart';

class OpsiRow extends StatelessWidget {
  final String? selected;
  final Function(String) onSelected;

  const OpsiRow({super.key, required this.selected, required this.onSelected});

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
      ],
    );
  }
}
