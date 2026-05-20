import 'package:flutter/material.dart';

class ResultStatusPill extends StatelessWidget {
  final String value;

  const ResultStatusPill({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    final s = value.toLowerCase().trim();

    Color c;
    if (s == "iya" || s == "aman") {
      c = const Color(0xff16a34a);
    } else if (s == "tidak" || s == "tidak aman") {
      c = const Color(0xffef4444);
    } else {
      c = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: c.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            value.isEmpty ? "-" : value,
            style: TextStyle(
              color: Colors.black.withOpacity(0.70),
              fontWeight: FontWeight.w900,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}
