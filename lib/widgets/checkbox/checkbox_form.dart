import 'package:flutter/material.dart';

class CheckboxForm extends StatelessWidget {
  final String? selected;
  final List<String> options;
  final Function(String) onChanged;

  const CheckboxForm({
    super.key,
    required this.selected,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      children: options.map((o) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Radio(
              value: o,
              groupValue: selected,
              onChanged: (v) => onChanged(v as String),
              activeColor: Colors.blueAccent,
            ),
            Text(o),
          ],
        );
      }).toList(),
    );
  }
}
