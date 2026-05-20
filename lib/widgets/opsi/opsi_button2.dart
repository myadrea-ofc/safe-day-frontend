import 'package:flutter/material.dart';

class OpsiButton2 extends StatelessWidget {
  final String text;
  final bool active;
  final VoidCallback onTap;

  const OpsiButton2({
    super.key,
    required this.text,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(16);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
            borderRadius: borderRadius,
            border: Border.all(
              color: active ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB),
              width: active ? 1.2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            textAlign: TextAlign.center,
            softWrap: true,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: active ? const Color(0xFF1D4ED8) : const Color(0xFF374151),
            ),
          ),
        ),
      ),
    );
  }
}
