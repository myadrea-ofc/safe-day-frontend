import 'package:flutter/material.dart';
import 'session_service.dart';

Future<void> showForceLogoutDialog(BuildContext context, String message) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: const Text("Sesi Berakhir"),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () async {
            await SessionService.forceLogout(context);
          },
          child: const Text("OK"),
        ),
      ],
    ),
  );
}
