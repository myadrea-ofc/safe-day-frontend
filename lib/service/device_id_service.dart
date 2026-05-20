import 'package:android_id/android_id.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceIdService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static Future<String> getOrCreateDeviceId() async {
    final existing = await _secureStorage.read(key: "device_id");

    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    if (kIsWeb) {
      return _getOrCreateWebDeviceId();
    }

    return _getOrCreateAndroidDeviceId();
  }

  static Future<String> _getOrCreateWebDeviceId() async {
    final prefs = await SharedPreferences.getInstance();

    String? webDeviceId = prefs.getString("web_device_id");

    if (webDeviceId == null || webDeviceId.isEmpty) {
      webDeviceId = "WEB-${const Uuid().v4()}";
      await prefs.setString("web_device_id", webDeviceId);
    }

    await _secureStorage.write(key: "device_id", value: webDeviceId);

    return webDeviceId;
  }

  static Future<String> _getOrCreateAndroidDeviceId() async {
    String? androidDeviceId;

    try {
      androidDeviceId = await const AndroidId().getId();
    } catch (e) {
      debugPrint("Android device id error: $e");
    }

    final deviceId = (androidDeviceId != null && androidDeviceId.isNotEmpty)
        ? androidDeviceId
        : "ANDROID-${const Uuid().v4()}";

    await _secureStorage.write(key: "device_id", value: deviceId);

    return deviceId;
  }
}
