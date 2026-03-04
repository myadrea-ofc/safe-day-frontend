import 'package:flutter/material.dart';
import 'field_box.dart';

class DateField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onTap;
  final IconData icon;

  const DateField({
    super.key,
    required this.controller,
    required this.onTap,
    this.icon = Icons.calendar_today,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: fieldBox(),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Text(controller.text.isEmpty ? "Pilih" : controller.text),
            ),
            Icon(icon, size: 18, color: Colors.blueAccent),
          ],
        ),
      ),
    );
  }
}
