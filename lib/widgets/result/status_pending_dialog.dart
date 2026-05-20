import 'package:flutter/material.dart';

enum StatusDialogType { success, error, warning }

class StatusDialog {
  static void show({
    required BuildContext context,
    required StatusDialogType type,
    required String title,
    required String message,
    required VoidCallback onDone,
  }) {
    final config = _getConfig(type);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 28,
          horizontal: 20,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(config.icon, size: 80, color: config.color),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: 140,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: config.color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: onDone,
                child: const Text("OK", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static _StatusConfig _getConfig(StatusDialogType type) {
    switch (type) {
      case StatusDialogType.success:
        return _StatusConfig(
          icon: Icons.check_circle_rounded,
          color: Colors.green,
        );

      case StatusDialogType.error:
        return _StatusConfig(icon: Icons.cancel_rounded, color: Colors.red);

      case StatusDialogType.warning:
        return _StatusConfig(
          icon: Icons.warning_amber_rounded,
          color: const Color(0xFFFFA726),
        );
    }
  }
}

class _StatusConfig {
  final IconData icon;
  final Color color;

  _StatusConfig({required this.icon, required this.color});
}
