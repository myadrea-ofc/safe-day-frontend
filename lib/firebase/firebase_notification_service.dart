import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:safety_apps/firebase/local_notification.dart';
import 'package:safety_apps/main.dart';
import 'package:safety_apps/session/auth_session.dart';
import 'package:safety_apps/session/session_service.dart';
import 'package:safety_apps/widgets/notification/in_app_notification.dart';

import '../network/api_client.dart';

class FirebaseNotificationService {
  static bool isHandlingRoleChange = false;
  static bool _roleDialogShown = false;

  static void resetRoleDialogFlag() {
    _roleDialogShown = false;
  }

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static String? lastToken;

  static Future<void> init() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint("🔐 NOTIF PERMISSION: ${settings.authorizationStatus}");

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint("❌ Notification permission denied");
        return;
      }

      // ✅ iOS: tampilkan notifikasi saat foreground (jaga-jaga)
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );

      // ✅ sambungkan tap local notification -> navigation
      LocalNotificationService.onNotificationTap = (data) {
        _handleNotificationNavigationFromData(data);
      };

      final token = await _messaging.getToken();
      lastToken = token;
      debugPrint("🔥 FCM TOKEN: $token");

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        lastToken = newToken;
        debugPrint("🔁 FCM TOKEN REFRESHED: $newToken");

        if (AuthSession.token == null) {
          debugPrint("⏭ Token refresh saat user belum login - disimpan saja");
        } else {
          try {
            final res = await ApiClient.post(
              "/users/fcm-token",
              body: {"fcm_token": newToken},
            );
            debugPrint("✅ token refresh sync status: ${res.statusCode}");
          } catch (e) {
            debugPrint("❌ token refresh sync error: $e");
          }
        }
      });
    } catch (e) {
      debugPrint("❌ FCM INIT ERROR: $e");
    }
  }

  static Future<void> syncTokenAfterLogin() async {
    if (AuthSession.token == null) return;

    final token = lastToken ?? await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) return;

    try {
      // pakai ApiClient supaya header x-device-id dan bearer otomatis
      final res = await ApiClient.post(
        "/users/fcm-token",
        body: {"fcm_token": token},
      );

      debugPrint("✅ syncTokenAfterLogin status: ${res.statusCode}");
      debugPrint("✅ syncTokenAfterLogin body: ${res.body}");
    } catch (e) {
      debugPrint("❌ syncTokenAfterLogin error: $e");
    }
  }

  static void listeners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint("📩 FOREGROUND NOTIFICATION");

      final type = (message.data["type"] ?? "").toString().trim();
      if (type == "role_changed") {
        _handleNotificationNavigationFromData(message.data);
        return;
      }

      // ✅ tampilkan tray notif saat app aktif (seperti WA)
      await LocalNotificationService.show(message);

      final context = navigatorKey.currentContext;
      if (context == null) return;

      final title =
          message.notification?.title ?? message.data['title']?.toString();
      final body =
          message.notification?.body ?? message.data['body']?.toString();

      // in-app banner (optional)
      showInAppNotification(
        context: context,
        title: title ?? "Notifikasi",
        body: body ?? "",
        onTap: () => _handleNotificationNavigation(message),
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("➡️ NOTIFICATION CLICKED (from OS tray)");
      _handleNotificationNavigation(message);
    });
  }

  static void _handleNotificationNavigation(RemoteMessage message) {
    _handleNotificationNavigationFromData(message.data);
  }

  static void _handleNotificationNavigationFromData(Map<String, dynamic> data) {
    // di _handleNotificationNavigationFromData()
    final type = (data["type"] ?? "").toString().trim();

    if (type == "role_changed") {
      if (_roleDialogShown) return;

      isHandlingRoleChange = true;
      _roleDialogShown = true;

      void resetFlags() {
        _roleDialogShown = false;
        isHandlingRoleChange = false;
      }

      final context = navigatorKey.currentState?.overlay?.context;
      if (context == null) {
        resetFlags();
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) {
          resetFlags();
          return;
        }

        showDialog(
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
                      const Text(
                        "Sesi Anda Berakhir.\nSilakan login ulang.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
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
                          onPressed: () async {
                            resetFlags();
                            if (!context.mounted) return;
                            await SessionService.forceLogout(context);
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
      });

      return;
    }
    // ==== yang lama tetap ====
    if (type == "daily_plan") {
      final planId = int.tryParse((data["daily_plan_id"] ?? "").toString());
      if (planId == null) return;

      navigatorKey.currentState?.pushNamed(
        "/daily-plan",
        arguments: {"open_detail_id": planId},
      );
      return;
    }

    if (type == "buletin") {
      final buletinId = int.tryParse((data["buletin_id"] ?? "").toString());

      navigatorKey.currentState?.pushNamed(
        "/buletin",
        arguments: {"open_detail_id": buletinId},
      );
      return;
    }

    if (type == "lpi") {
      final lpiId = int.tryParse((data["lpi_id"] ?? "").toString());

      navigatorKey.currentState?.pushNamed(
        "/lpi-results",
        arguments: {"open_detail_id": lpiId},
      );
      return;
    }
  }

  static void handleNavigationFromMessage(RemoteMessage message) {
    _handleNotificationNavigation(message);
  }
}
