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
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: active ? Colors.blueAccent : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: TextAlign.center,
          softWrap: true,
          style: TextStyle(
            fontSize: 11,
            color: active ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
