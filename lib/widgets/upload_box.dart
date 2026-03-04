import 'package:flutter/material.dart';
import 'package:safety_apps/widgets/field_box.dart';

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
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: fieldBox(),
        child: Row(
          children: [
            Icon(icon, color: Colors.blueAccent),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                fileCount == 0 ? text : "$fileCount file dipilih",
                style: TextStyle(color: Colors.black54),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
