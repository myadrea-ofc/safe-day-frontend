import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserService {
  static const _storage = FlutterSecureStorage();
  static const String baseUrl = "http://safety.borneo.co.id";

  static Future<Map<String, String>> _getHeaders({bool json = true}) async {
    final token = await _storage.read(key: "jwt_token");
    final deviceId = await _storage.read(key: "device_id"); // ✅ FIX

    if (token == null) {
      throw Exception("Token tidak ditemukan, silakan login ulang");
    }

    if (deviceId == null) {
      throw Exception("Device ID tidak ditemukan, silakan login ulang");
    }

    return {
      "Authorization": "Bearer $token",
      if (json) "Content-Type": "application/json",
      "x-device-id": deviceId, // ✅ sesuai middleware backend
    };
  }

  // 🔓 PUBLIC WRAPPER (WAJIB ADA)
  static Future<Map<String, String>> getHeaders({bool json = true}) async {
    return await _getHeaders(json: json);
  }

  static Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final headers = await _getHeaders();
    final res = await http.put(
      Uri.parse("$baseUrl/users/change-password"),
      headers: headers,
      body: jsonEncode({
        "oldPassword": oldPassword,
        "newPassword": newPassword,
      }),
    );

    return res.statusCode == 200;
  }

  static Future<void> addUser({
    required String name,
    required String email,
    required String password,
    required String role,
    required int departmentId,
    int? siteId,
  }) async {
    final headers = await _getHeaders();

    final body = {
      "name": name,
      "email": email,
      "password": password,
      "role": role,
      "department_id": departmentId,
    };

    if (siteId != null) body["site_id"] = siteId;

    final res = await http.post(
      Uri.parse("$baseUrl/users"),
      headers: headers,
      body: jsonEncode(body),
    );

    if (res.statusCode != 201) {
      final msg = jsonDecode(res.body)["message"] ?? "Gagal tambah user";
      throw Exception(msg);
    }
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final headers = await _getHeaders();
    final res = await http.get(
      Uri.parse("$baseUrl/users/profile"),
      headers: headers,
    );

    if (res.statusCode != 200) {
      throw Exception("Gagal ambil profile (${res.statusCode})\n${res.body}");
    }

    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<void> changeUserRole({
    required int userId,
    required String role,
  }) async {
    final headers = await _getHeaders();
    final res = await http.put(
      Uri.parse("$baseUrl/users/$userId/role"),
      headers: headers,
      body: jsonEncode({"role": role}),
    );

    if (res.statusCode != 200) {
      final msg = jsonDecode(res.body)["message"] ?? "Gagal update role";
      throw Exception(msg);
    }
  }

  static Future<List<Map<String, dynamic>>> searchUsers({
    required int departmentId,
    int? siteId,
    String search = "",
  }) async {
    final headers = await _getHeaders(json: false);
    final queryParameters = {
      "department_id": departmentId.toString(),
      if (siteId != null) "site_id": siteId.toString(),
      "search": search,
    };

    final uri = Uri.parse(
      "$baseUrl/users",
    ).replace(queryParameters: queryParameters);

    final res = await http.get(uri, headers: headers);

    if (res.statusCode != 200) {
      throw Exception("Gagal load users: ${res.statusCode}");
    }

    final List data = jsonDecode(res.body);
    return data.map((e) => {"id": e["id"], "name": e["name"]}).toList();
  }

  static bool isRoleChangedLogout(http.Response res) {
    if (res.statusCode != 401) return false;

    try {
      final data = jsonDecode(res.body);
      return data["reason"] == "role_changed";
    } catch (_) {
      return false;
    }
  }
}
