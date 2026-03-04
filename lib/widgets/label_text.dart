import 'package:flutter/material.dart';

class LabelText extends StatelessWidget {
  final String text;
  final bool showError;

  const LabelText(this.text, {this.showError = false, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.justify,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),

          if (showError) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 14,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
