import 'dart:io';

import 'package:android_id/android_id.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class DeviceHelper {
  static const _iosKey = "stable_device_id"; // keychain key
  static const _storage = FlutterSecureStorage();
  static const _fallbackKey = "fallback_device_id";

  static Future<String> getInstallationId() async {
    if (Platform.isAndroid) {
      final id = (await const AndroidId().getId())?.trim() ?? "";
      if (id.isNotEmpty) return id;

      // fallback: simpan UUID agar tetap konsisten setidaknya di device itu
      final existing = await _storage.read(key: _fallbackKey);
      if (existing != null && existing.trim().isNotEmpty)
        return existing.trim();

      final newId = const Uuid().v4();
      await _storage.write(key: _fallbackKey, value: newId);
      return newId;
    }
    // ✅ iOS (atau platform lain): simpan UUID di secure storage
    // (di iOS biasanya tersimpan di Keychain sehingga survive reinstall)
    final existing = await _storage.read(key: _iosKey);
    if (existing != null && existing.trim().isNotEmpty) {
      return existing.trim();
    }

    final newId = const Uuid().v4();
    await _storage.write(key: _iosKey, value: newId);
    return newId;
  }
}
