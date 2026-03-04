import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:safety_apps/pages/login_page.dart';
import 'package:safety_apps/session/auth_session.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionGuard {
  static bool _dialogShown = false;

  static Future<bool> handleResponse(
    BuildContext context,
    dynamic response,
  ) async {
    if (_dialogShown) return true;

    if (response.statusCode == 401) {
      final data = jsonDecode(response.body);

      if (data["reason"] == "role_changed") {
        _dialogShown = true;

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text("Sesi Berakhir"),
            content: const Text("Sesi Anda berakhir.\nSilakan login ulang."),
            actions: [
              TextButton(
                onPressed: () async {
                  const storage = FlutterSecureStorage();
                  await storage.deleteAll();
                  AuthSession.clear();

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (_) => false,
                  );
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );

        return true;
      }
    }

    return false;
  }
}
