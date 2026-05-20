import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:safety_apps/models/buletin.dart';
import 'package:safety_apps/models/events/buletin_review.dart';
import 'package:share_plus/share_plus.dart';

class HSESBuletinService {
  static const String baseUrl = "http://safety.borneo.co.id/hses_buletin";
  static const _storage = FlutterSecureStorage();

  static Future<Map<String, String>> _authHeaders({bool json = false}) async {
    final token = await _storage.read(key: "jwt_token");
    final deviceId = await _storage.read(key: "device_id");

    if (token == null || deviceId == null) {
      throw Exception("Token atau Device ID tidak ditemukan");
    }

    return {
      "Authorization": "Bearer $token",
      "x-device-id": deviceId,
      if (json) "Content-Type": "application/json",
    };
  }

  static Future<String?> _getToken() async {
    final token = await _storage.read(key: "jwt_token");
    if (token == null || token.isEmpty) return null;
    return token;
  }

  // ================= FETCH ALL =================
  static Future<List<Buletin>> fetchAll() async {
    try {
      final token = await _storage.read(key: "jwt_token");

      if (token == null || token.isEmpty) {
        debugPrint("❌ TOKEN NULL - FORCE EMPTY");
        return [];
      }

      final res = await http.get(
        Uri.parse(baseUrl),
        headers: await _authHeaders(),
      );

      debugPrint("STATUS: ${res.statusCode}");
      debugPrint("BODY: ${res.body}");

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);

        final List data = decoded is List ? decoded : decoded["data"];

        return data.map((e) => Buletin.fromJson(e)).toList();
      }

      return [];
    } catch (e) {
      debugPrint("FETCH BULETIN ERROR: $e");
      return [];
    }
  }

  // ================= CREATE =================
  static Future<Buletin?> submit({
    required String judul,
    required String subJudul,
    required String deskripsi,
    XFile? gambar,
    required List<int> siteIds,
    required bool isForAllSites,
  }) async {
    try {
      if (siteIds.isEmpty) {
        throw Exception("Minimal 1 site harus dipilih");
      }

      final token = await _getToken();
      if (token == null) return null;

      final req = http.MultipartRequest("POST", Uri.parse(baseUrl));
      req.headers.addAll(await _authHeaders());

      req.fields["judul"] = judul;
      req.fields["subJudul"] = subJudul;
      req.fields["deskripsi"] = deskripsi;
      req.fields["is_for_all_sites"] = isForAllSites ? "1" : "0";

      for (int i = 0; i < siteIds.length; i++) {
        req.fields["site_ids[$i]"] = siteIds[i].toString();
      }

      if (gambar != null) {
        final bytes = await gambar.readAsBytes();

        req.files.add(
          http.MultipartFile.fromBytes("gambar", bytes, filename: gambar.name),
        );
      }

      final res = await req.send();
      final body = await res.stream.bytesToString();

      if (res.statusCode == 200 || res.statusCode == 201) {
        return Buletin.fromJson(jsonDecode(body));
      }

      debugPrint("CREATE BULETIN STATUS: ${res.statusCode}");
      return null;
    } catch (e) {
      debugPrint("CREATE BULETIN ERROR: $e");
      return null;
    }
  }

  // ================= UPDATE =================
  static Future<Buletin?> update({
    required int id,
    required String judul,
    required String subJudul,
    required String deskripsi,
    XFile? gambar,
    required List<int> siteIds,
    required bool isForAllSites,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return null;

      final req = http.MultipartRequest("PUT", Uri.parse("$baseUrl/$id"));
      req.headers.addAll(await _authHeaders());

      req.fields["judul"] = judul;
      req.fields["subJudul"] = subJudul;
      req.fields["deskripsi"] = deskripsi;

      for (int i = 0; i < siteIds.length; i++) {
        req.fields["site_ids[$i]"] = siteIds[i].toString();
      }

      if (gambar != null) {
        final bytes = await gambar.readAsBytes();

        req.files.add(
          http.MultipartFile.fromBytes("gambar", bytes, filename: gambar.name),
        );
      }

      final res = await req.send();
      final body = await res.stream.bytesToString();

      if (res.statusCode == 200) {
        return Buletin.fromJson(jsonDecode(body));
      }

      return null;
    } catch (e) {
      debugPrint("UPDATE BULETIN ERROR: $e");
      return null;
    }
  }

  // ================= DELETE =================
  static Future<bool> delete(int id) async {
    try {
      final token = await _getToken();
      if (token == null) return false;

      final res = await http.delete(
        Uri.parse("$baseUrl/$id"),
        headers: await _authHeaders(),
      );

      return res.statusCode == 200;
    } catch (e) {
      debugPrint("DELETE BULETIN ERROR: $e");
      return false;
    }
  }

  // ================= REVIEW =================
  static Future<bool> submitReview({
    required int buletinId,
    required String comment,
    required int rating,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return false;

      final res = await http.post(
        Uri.parse("$baseUrl/$buletinId/review"),
        headers: await _authHeaders(json: true),
        body: jsonEncode({"rating": rating, "comment": comment}),
      );

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint("REVIEW BULETIN ERROR: $e");
      return false;
    }
  }

  // ================= ADMIN TABLE =================
  static Future<List<BuletinReview>> fetchAdminTable() async {
    try {
      final token = await _getToken();
      if (token == null) return [];

      final res = await http.get(
        Uri.parse("$baseUrl/table"),
        headers: await _authHeaders(),
      );

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((e) => BuletinReview.fromJson(e)).toList();
      }

      return [];
    } catch (e) {
      debugPrint("FETCH BULETIN TABLE ERROR: $e");
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> fetchSites() async {
    final token = await _storage.read(key: "jwt_token");

    if (token == null) {
      debugPrint("FETCH SITE: TOKEN NULL");
      return [];
    }

    final res = await http.get(
      Uri.parse("http://safety.borneo.co.id/sites"),
      headers: await _authHeaders(),
    );

    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    }

    debugPrint("FETCH SITE STATUS: ${res.statusCode}");
    debugPrint("FETCH SITE BODY: ${res.body}");
    return [];
  }
}
