import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:safety_apps/firebase/firebase_notification_service.dart';
import 'package:safety_apps/main.dart';
import 'package:safety_apps/service/user_service.dart';
import 'package:safety_apps/session/auth_session.dart';
import 'package:safety_apps/pages/login_page.dart';

class SessionService {
  static Future<bool> validateSession() async {
    try {
      final headers = await UserService.getHeaders(json: false);
      final res = await http.get(
        Uri.parse("${UserService.baseUrl}/validate-session"),
        headers: headers,
      );

      if (res.statusCode != 200) return false;

      final data = jsonDecode(res.body);
      return data["valid"] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> forceLogout(BuildContext context) async {
    FirebaseNotificationService.resetRoleDialogFlag();

    const storage = FlutterSecureStorage();
    final deviceId = await storage.read(key: "device_id");

    await storage.deleteAll();

    if (deviceId != null) {
      await storage.write(key: "device_id", value: deviceId);
    }

    AuthSession.clear();

    final navigator = navigatorKey.currentState;
    if (navigator == null || !navigator.mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nav = navigatorKey.currentState;
      if (nav == null || !nav.mounted) return;

      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    });
  }
}
