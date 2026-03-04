import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // callback untuk handle tap notif lokal
  static void Function(Map<String, dynamic> data)? onNotificationTap;

  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        final payload = details.payload;
        debugPrint("🔔 Local notif clicked payload: $payload");

        if (payload == null || payload.isEmpty) return;

        try {
          final data = jsonDecode(payload) as Map<String, dynamic>;
          onNotificationTap?.call(data);
        } catch (e) {
          debugPrint("❌ Failed to parse payload JSON: $e");
        }
      },
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(channel);

    // ✅ Android 13+ runtime permission
    await androidPlugin?.requestNotificationsPermission();
  }

  static Future<void> show(RemoteMessage message) async {
    // ✅ allow data-only di masa depan
    final title =
        message.notification?.title ?? message.data['title']?.toString();
    final body = message.notification?.body ?? message.data['body']?.toString();

    // kalau bener-bener kosong, skip
    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }

    // ✅ notifId lebih aman daripada hashCode yang bisa berubah
    final notifId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _plugin.show(
      notifId,
      title ?? "Notifikasi",
      body ?? "",
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }
}
