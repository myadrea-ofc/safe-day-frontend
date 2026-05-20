import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

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
    const iosInit = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        final payload = details.payload;
        debugPrint("🔔 Local notif clicked payload: $payload");

        if (payload == null || payload.isEmpty) return;

        try {
          final data = (jsonDecode(payload) as Map).cast<String, dynamic>();
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
    await androidPlugin?.requestNotificationsPermission();
  }

  static String? extractTitle(RemoteMessage message) {
    return message.notification?.title ?? message.data['title']?.toString();
  }

  static String? extractBody(RemoteMessage message) {
    return message.notification?.body ?? message.data['body']?.toString();
  }

  static bool hasDisplayContent(RemoteMessage message) {
    final title = extractTitle(message);
    final body = extractBody(message);

    return (title != null && title.isNotEmpty) ||
        (body != null && body.isNotEmpty);
  }

  static bool isNotificationPayload(RemoteMessage message) {
    return message.notification != null;
  }

  static Future<void> show(RemoteMessage message) async {
    final title = extractTitle(message);
    final body = extractBody(message);

    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      debugPrint("⏭ Skip local notif: title/body kosong");
      return;
    }

    final notifId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

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
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }
}
