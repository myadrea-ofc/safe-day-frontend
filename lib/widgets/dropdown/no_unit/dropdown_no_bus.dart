import 'package:flutter/material.dart';

class DropdownNoLambungBus extends StatelessWidget {
  final String? value;
  final Function(String?) onChanged;

  const DropdownNoLambungBus({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const List<String> nobusList = [
    "MHM9001",
    "MHM9002",
    "MHM9003",
    "MHM9004",
    "MHM9005",
    "MHM9006",
    "MHM9007",
    "MHM9008",
    "MHM9009",
    "MHM9010",
    "MHM9011",
    "MHM9012",
    "MHM9013",
    "MHM9014",
    "MHM9015",
    "MHM9016",
    "MHM9017",
    "MHM9018",
    "MHM9019",
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
          items: nobusList
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
