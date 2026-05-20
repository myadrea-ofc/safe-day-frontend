import 'package:flutter/material.dart';
import 'package:safety_apps/models/result/excel_access.dart';

class ResultExcelAccessRow extends StatelessWidget {
  final ExcelAccess access;
  final ValueChanged<bool> onChanged;
  final VoidCallback onDelete;

  const ResultExcelAccessRow({
    super.key,
    required this.access,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final a = access;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xfff5f7fb),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.userName,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  "Site: ${a.siteName} • Role: ${a.userRole}",
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.55),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Transform.scale(
                    scale: 0.92,
                    child: Switch(value: a.canDownload, onChanged: onChanged),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    a.canDownload ? "Aktif" : "Tidak Aktif",
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      color: a.canDownload
                          ? const Color(0xff16a34a)
                          : const Color(0xffef4444),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: "Hapus",
                onPressed: onDelete,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red.withOpacity(0.85),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
