import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:safety_apps/drawer/change_password.dart';
import 'package:safety_apps/firebase/firebase_notification_service.dart';
import 'package:safety_apps/main.dart';
import 'package:safety_apps/pages/login_page.dart';
import 'package:safety_apps/service/user_service.dart';
import '../session/auth_session.dart';

class ApiClient {
  static final storage = const FlutterSecureStorage();

  static String get _baseUrl => UserService.baseUrl;

  // =========================
  // GET
  // =========================
  static Future<http.Response> get(String url) async {
    final token = AuthSession.token ?? await storage.read(key: "jwt_token");
    final deviceId = await storage.read(key: "device_id");

    if (token == null || deviceId == null) {
      throw UnauthorizedException();
    }

    final res = await http.get(
      Uri.parse("$_baseUrl$url"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "x-device-id": deviceId,
      },
    );

    await _handleUnauthorized(res);
    return res;
  }

  // =========================
  // POST
  // =========================
  static Future<http.Response> post(
    String url, {
    Map<String, dynamic>? body,
  }) async {
    final token = AuthSession.token ?? await storage.read(key: "jwt_token");
    final deviceId = await storage.read(key: "device_id");

    debugPrint("🔹 POST URL: $_baseUrl$url");
    debugPrint("🔹 DEVICE ID: $deviceId");
    debugPrint("🔹 AUTH TOKEN: $token");
    debugPrint("🔹 BODY: $body");

    if (token == null || deviceId == null) {
      throw UnauthorizedException();
    }

    final res = await http.post(
      Uri.parse("$_baseUrl$url"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "x-device-id": deviceId,
      },
      body: body != null ? jsonEncode(body) : null,
    );

    await _handleUnauthorized(res);
    return res;
  }

  // =========================
  // PUT
  // =========================
  static Future<http.Response> put(
    String url, {
    Map<String, dynamic>? body,
  }) async {
    final token = AuthSession.token ?? await storage.read(key: "jwt_token");
    final deviceId = await storage.read(key: "device_id");

    if (token == null || deviceId == null) {
      throw UnauthorizedException();
    }

    final res = await http.put(
      Uri.parse("$_baseUrl$url"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "x-device-id": deviceId,
      },
      body: body != null ? jsonEncode(body) : null,
    );

    await _handleUnauthorized(res);
    return res;
  }

  // =========================
  // 401 HANDLER
  // =========================

  static bool _dialogShown = false;
  static bool _isHandling401 = false;

  static Future<void> _handleUnauthorized(http.Response res) async {
    // ✅ kalau FCM sedang handle role_changed → skip
    if (FirebaseNotificationService.isHandlingRoleChange) return;

    // ✅ hanya tangani 401 / 403
    if (res.statusCode != 401 && res.statusCode != 403) return;
    if (_dialogShown || _isHandling401) return;

    // ✅ parse payload sekali
    String? reason;
    String? msg;
    bool mustChangePassword = false;

    try {
      final data = jsonDecode(res.body);
      reason = data["reason"]?.toString();
      msg = data["message"]?.toString();
      mustChangePassword = data["must_change_password"] == true;
    } catch (_) {}

    // ambil context yang aman
    final context = navigatorKey.currentState?.overlay?.context;
    if (context == null) return;

    // =========================================================
    // ✅ 403 = JANGAN logout. Ini sumber loop kamu.
    // =========================================================
    if (res.statusCode == 403) {
      // ✅ kalau must_change_password, paksa pindah ChangePasswordPage
      if (mustChangePassword) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => const ChangePasswordPage(hideBack: true),
            ),
            (_) => false,
          );
        });
        return;
      }

      // ✅ 403 biasa: tampilkan pesan saja (tanpa logout / tanpa delete token)
      _isHandling401 = true;
      _dialogShown = true;

      final message = (msg != null && msg!.isNotEmpty)
          ? msg!
          : "Anda tidak punya hak akses.";

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!context.mounted) {
          _isHandling401 = false;
          _dialogShown = false;
          return;
        }

        try {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => WillPopScope(
              onWillPop: () async => false,
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                elevation: 6,
                backgroundColor: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xff1d63ff), Color(0xff4fa9ff)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xff1d63ff,
                                ).withOpacity(0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.settings_backup_restore_outlined,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Sesi Berakhir",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 2,
                              backgroundColor: const Color(0xff1d63ff),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () {
                              _dialogShown = false;
                              _isHandling401 = false;
                              Navigator.pop(context); // tutup dialog aja
                            },
                            child: const Text(
                              "OK",
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        } catch (_) {
          // kalau dialog gagal tampil, jangan nge-lock flag
          _dialogShown = false;
          _isHandling401 = false;
        }
      });

      return;
    }

    // =========================================================
    // ✅ 401 = baru logout seperti sebelumnya
    // =========================================================
    _isHandling401 = true;
    _dialogShown = true;

    String message = "Sesi Anda Berakhir.\nSilakan login ulang.";
    if (reason == "role_changed") {
      message = "Role akun Anda telah berubah.\nSilakan login ulang.";
    } else if (msg != null && msg!.isNotEmpty) {
      message = msg!;
    }

    // ✅ simpan device_id
    final deviceId = await storage.read(key: "device_id");
    await storage.deleteAll();
    if (deviceId != null) {
      await storage.write(key: "device_id", value: deviceId);
    }
    AuthSession.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) {
        _isHandling401 = false;
        _dialogShown = false;
        return;
      }

      try {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => WillPopScope(
            onWillPop: () async => false,
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              elevation: 6,
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xff1d63ff), Color(0xff4fa9ff)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xff1d63ff).withOpacity(0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.settings_backup_restore_outlined,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Sesi Berakhir",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 2,
                            backgroundColor: const Color(0xff1d63ff),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            _dialogShown = false;
                            _isHandling401 = false;

                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginPage(),
                              ),
                              (_) => false,
                            );
                          },
                          child: const Text(
                            "Login Ulang",
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      } catch (_) {
        _dialogShown = false;
        _isHandling401 = false;
      }
    });
  }

  static Future<http.Response> getBytes(String url) async {
    final token = AuthSession.token ?? await storage.read(key: "jwt_token");
    final deviceId = await storage.read(key: "device_id");

    if (token == null || deviceId == null) {
      throw UnauthorizedException();
    }

    final res = await http.get(
      Uri.parse("$_baseUrl$url"),
      headers: {"Authorization": "Bearer $token", "x-device-id": deviceId},
    );

    await _handleUnauthorized(res);
    return res;
  }
}

// =========================
// CUSTOM EXCEPTION
// =========================

class UnauthorizedException implements Exception {}

class RoleChangedException implements Exception {}
