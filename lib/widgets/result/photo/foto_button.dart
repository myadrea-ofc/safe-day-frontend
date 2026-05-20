import 'package:flutter/material.dart';
import 'package:safety_apps/widgets/result/page_style.dart';

class FotoButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const FotoButton({super.key, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.35,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: ResultPageStyle.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: ResultPageStyle.primary.withOpacity(0.14),
            ),
          ),
          child: ShaderMask(
            shaderCallback: (bounds) =>
                ResultPageStyle.primaryGradient.createShader(bounds),
            child: const Icon(
              Icons.image_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
