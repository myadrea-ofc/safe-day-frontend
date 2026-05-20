import 'package:flutter/material.dart';

class UploadBox extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;
  final int fileCount;

  const UploadBox({
    super.key,
    required this.text,
    required this.icon,
    required this.onTap,
    this.fileCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(16);
    final isEmpty = fileCount == 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC), // 👈 soft biru
            borderRadius: borderRadius,
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: const Color(0xFF2563EB), // 👈 biru konsisten
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isEmpty ? text : "$fileCount file dipilih",
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isEmpty ? FontWeight.w400 : FontWeight.w500,
                    color: isEmpty
                        ? const Color(0xFF9CA3AF) // hint style
                        : const Color(0xFF111827), // text aktif
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
