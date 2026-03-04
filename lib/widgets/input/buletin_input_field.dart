import 'package:flutter/material.dart';

class InputFieldBuletin extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;

  const InputFieldBuletin({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
