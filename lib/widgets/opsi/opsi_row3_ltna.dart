import 'package:flutter/material.dart';
import 'opsi_button.dart';

class OpsiRow3Ltna extends StatelessWidget {
  final String? selected;
  final Function(String) onSelected;

  const OpsiRow3Ltna({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(0.75)),
      child: Row(
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
          SizedBox(width: 10),
          Expanded(
            child: OpsiButton(
              text: "N/A",
              active: selected == "N/A",
              onTap: () => onSelected("N/A"),
            ),
          ),
        ],
      ),
    );
  }
}
