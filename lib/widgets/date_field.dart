import 'package:flutter/material.dart';

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
    final borderRadius = BorderRadius.circular(16);
    final isEmpty = controller.text.isEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: borderRadius,
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  isEmpty ? "Pilih" : controller.text,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isEmpty ? FontWeight.w400 : FontWeight.w500,
                    color: isEmpty
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF111827),
                  ),
                ),
              ),
              Icon(icon, size: 18, color: const Color(0xFF2563EB)),
            ],
          ),
        ),
      ),
    );
  }
}
