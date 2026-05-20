import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:safety_apps/firebase/local_notification.dart';
import 'package:safety_apps/main.dart';
import 'package:safety_apps/session/auth_session.dart';
import 'package:safety_apps/session/permission_refresh.dart';
import 'package:safety_apps/session/session_service.dart';
import 'package:safety_apps/widgets/notification/in_app_notification.dart';

import '../network/api_client.dart';

class FirebaseNotificationService {
  static bool isHandlingRoleChange = false;
  static bool _roleDialogShown = false;

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static String? lastToken;

  static void resetRoleDialogFlag() {
    _roleDialogShown = false;
  }

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

      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      LocalNotificationService.onNotificationTap = (data) {
        _handleNotificationNavigationFromData(data);
      };

      final token = await _messaging.getToken();
      lastToken = token;
      debugPrint("🔥 FCM TOKEN: $token");

      _messaging.onTokenRefresh.listen((newToken) async {
        lastToken = newToken;
        debugPrint("🔁 FCM TOKEN REFRESHED: $newToken");

        if (AuthSession.token == null) {
          debugPrint(
            "⏭ Token refresh saat user belum login - disimpan lokal dulu",
          );
          return;
        }

        try {
          final res = await ApiClient.post(
            "/users/fcm-token",
            body: {"fcm_token": newToken},
          );
          debugPrint("✅ token refresh sync status: ${res.statusCode}");
          debugPrint("✅ token refresh sync body: ${res.body}");
        } catch (e) {
          debugPrint("❌ token refresh sync error: $e");
        }
      });
    } catch (e) {
      debugPrint("❌ FCM INIT ERROR: $e");
    }
  }

  static NavigatorState? get _navigator {
    final nav = navigatorKey.currentState;
    if (nav == null) {
      debugPrint("❌ Navigator belum ready");
      return null;
    }
    if (!nav.mounted) {
      debugPrint("❌ Navigator tidak mounted");
      return null;
    }
    return nav;
  }

  static void _safePushNamed(String route, {Object? arguments}) {
    final navigator = _navigator;
    if (navigator == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nav = _navigator;
      if (nav == null) return;

      try {
        nav.pushNamed(route, arguments: arguments);
      } catch (e) {
        debugPrint("❌ Navigation error: $e");
      }
    });
  }

  static Future<void> syncTokenAfterLogin() async {
    if (AuthSession.token == null) return;

    final token = lastToken ?? await _messaging.getToken();
    if (token == null || token.isEmpty) return;

    try {
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
      debugPrint("📩 FOREGROUND DATA: ${message.data}");
      debugPrint("📩 FOREGROUND TITLE: ${message.notification?.title}");
      debugPrint("📩 FOREGROUND BODY: ${message.notification?.body}");

      final type = (message.data["type"] ?? "").toString().trim();

      if (type == "role_changed") {
        _handleNotificationNavigationFromData(message.data);
        return;
      }

      if (type == "excel_access_decision" ||
          type == "excel_access_revoked" ||
          type == "excel_access_granted") {
        PermissionRefresh.notifyExcelAccessChanged();
      }

      await LocalNotificationService.show(message);

      final context = navigatorKey.currentContext;
      if (context == null) return;

      final title =
          message.notification?.title ?? message.data['title']?.toString();
      final body =
          message.notification?.body ?? message.data['body']?.toString();

      showInAppNotification(
        context: context,
        title: title ?? "Notifikasi",
        body: body ?? "",
        onTap: () => _handleNotificationNavigationFromData(message.data),
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

  static void _showRoleChangedDialog() {
    if (_roleDialogShown) return;

    final navigator = _navigator;
    if (navigator == null) return;

    _roleDialogShown = true;
    isHandlingRoleChange = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final nav = _navigator;
      if (nav == null) {
        resetRoleDialogFlag();
        isHandlingRoleChange = false;
        return;
      }

      final context = nav.context;
      if (!context.mounted) {
        resetRoleDialogFlag();
        isHandlingRoleChange = false;
        return;
      }

      await showDialog(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
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
  }

  static void _handleNotificationNavigationFromData(Map<String, dynamic> data) {
    final type = (data["type"] ?? "").toString().trim();

    if (type == "role_changed") {
      _showRoleChangedDialog();
      return;
    }

    if (type == "daily_plan") {
      final planId = int.tryParse((data["daily_plan_id"] ?? "").toString());
      if (planId == null) return;

      _safePushNamed("/daily-plan", arguments: {"open_detail_id": planId});
      return;
    }

    if (type == "buletin") {
      final buletinId = int.tryParse((data["buletin_id"] ?? "").toString());
      if (buletinId == null) return;

      _safePushNamed("/buletin", arguments: {"open_detail_id": buletinId});
      return;
    }

    if (type == "lpi") {
      final lpiId = int.tryParse((data["lpi_id"] ?? "").toString());
      if (lpiId == null) return;

      _safePushNamed("/lpi-results", arguments: {"open_detail_id": lpiId});
      return;
    }

    if (type == "excel_access_request") {
      _safePushNamed(
        "/excel-access-requests",
        arguments: {"feature": (data["feature"] ?? "").toString()},
      );
      return;
    }

    if (type == "excel_access_decision") {
      PermissionRefresh.notifyExcelAccessChanged();
      _safePushNamed(
        "/excel-access-permission",
        arguments: {"feature": (data["feature"] ?? "").toString()},
      );
      return;
    }

    if (type == "excel_access_revoked") {
      PermissionRefresh.notifyExcelAccessChanged();
      _safePushNamed(
        "/excel-access-permission",
        arguments: {"feature": (data["feature"] ?? "").toString()},
      );
      return;
    }

    if (type == "excel_access_granted") {
      PermissionRefresh.notifyExcelAccessChanged();
      _safePushNamed(
        "/excel-access-permission",
        arguments: {"feature": (data["feature"] ?? "").toString()},
      );
      return;
    }
  }

  static void handleNavigationFromMessage(RemoteMessage message) {
    _handleNotificationNavigation(message);
  }
}
