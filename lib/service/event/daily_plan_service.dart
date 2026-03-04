import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:safety_apps/models/daily_plan.dart';
import 'package:safety_apps/models/events/daily_plan_review.dart';

class HSESDailyPlanService {
  static const String baseUrl = "http://safety.borneo.co.id/hses_daily_plan";
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

  // ================= FETCH ALL =================
  static Future<List<DailyPlan>> fetchAll() async {
    try {
      final res = await http.get(
        Uri.parse(baseUrl),
        headers: await _authHeaders(),
      );

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((e) => DailyPlan.fromJson(e)).toList();
      }

      debugPrint("FETCH STATUS: ${res.statusCode} BODY: ${res.body}");
      return [];
    } catch (e) {
      debugPrint("FETCH ERROR: $e");
      return [];
    }
  }

  // ================= CREATE =================
  static Future<DailyPlan?> submit({
    required String judul,
    required String subJudul,
    required String deskripsi,
    File? gambar,
    required List<int> siteIds,
    required bool isForAllSites,
  }) async {
    try {
      if (siteIds.isEmpty) {
        throw Exception("Minimal 1 site harus dipilih");
      }

      final token = await _storage.read(key: "jwt_token");
      if (token == null) return null;

      final request = http.MultipartRequest("POST", Uri.parse(baseUrl));
      request.headers.addAll(await _authHeaders());

      request.fields["judul"] = judul;
      request.fields["subJudul"] = subJudul;
      request.fields["deskripsi"] = deskripsi;

      request.fields["is_for_all_sites"] = isForAllSites ? "1" : "0";

      request.fields["site_ids"] = jsonEncode(siteIds);

      if (gambar != null) {
        request.files.add(
          await http.MultipartFile.fromPath("gambar", gambar.path),
        );
      }

      final response = await request.send();

      if (response.statusCode == 201) {
        final body = await response.stream.bytesToString();
        return DailyPlan.fromJson(jsonDecode(body));
      }

      debugPrint("SUBMIT STATUS: ${response.statusCode}");
      return null;
    } catch (e) {
      debugPrint("SUBMIT ERROR: $e");
      return null;
    }
  }

  // ================= UPDATE =================
  static Future<DailyPlan?> update({
    required int id,
    required String judul,
    required String subJudul,
    required String deskripsi,
    File? gambar,
    required List<int> siteIds,
    required bool isForAllSites,
  }) async {
    try {
      final req = http.MultipartRequest("PUT", Uri.parse("$baseUrl/$id"));
      req.headers.addAll(await _authHeaders());

      req.fields["judul"] = judul;
      req.fields["subJudul"] = subJudul;
      req.fields["deskripsi"] = deskripsi;

      req.fields["is_for_all_sites"] = isForAllSites ? "1" : "0";

      for (int i = 0; i < siteIds.length; i++) {
        req.fields["site_ids[$i]"] = siteIds[i].toString();
      }

      if (gambar != null) {
        req.files.add(await http.MultipartFile.fromPath("gambar", gambar.path));
      }

      final res = await req.send();

      if (res.statusCode == 200) {
        final body = await res.stream.bytesToString();
        return DailyPlan.fromJson(jsonDecode(body));
      }

      return null;
    } catch (e) {
      debugPrint("UPDATE ERROR: $e");
      return null;
    }
  }

  // ================= DELETE =================
  static Future<bool> delete(int id) async {
    try {
      final res = await http.delete(
        Uri.parse("$baseUrl/$id"),
        headers: await _authHeaders(),
      );

      return res.statusCode == 200;
    } catch (e) {
      debugPrint("DELETE ERROR: $e");
      return false;
    }
  }

  // ================= SUBMIT REVIEW (MEMBER) =================
  static Future<bool> submitReview({
    required int planId,
    required String comment,
    required int rating,
  }) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/$planId/review"),
        headers: await _authHeaders(json: true),
        body: jsonEncode({"rating": rating, "comment": comment}),
      );

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint("REVIEW ERROR: $e");
      return false;
    }
  }

  // ================= GET REVIEW PER DAILY PLAN =================
  static Future<List<Map<String, dynamic>>> fetchReviews(int planId) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/$planId/review"),
        headers: await _authHeaders(),
      );

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.cast<Map<String, dynamic>>();
      }

      return [];
    } catch (e) {
      debugPrint("FETCH REVIEW ERROR: $e");
      return [];
    }
  }

  // ================= GET RATING SUMMARY =================
  static Future<Map<String, dynamic>?> fetchRating(int planId) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/$planId/rating"),
        headers: await _authHeaders(),
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }

      return null;
    } catch (e) {
      debugPrint("FETCH RATING ERROR: $e");
      return null;
    }
  }

  // ================= ADMIN TABLE REVIEW =================
  static Future<List<DailyPlanReview>> fetchAdminTable() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/table"),
        headers: await _authHeaders(),
      );

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((e) => DailyPlanReview.fromJson(e)).toList();
      }

      debugPrint("ADMIN TABLE STATUS: ${res.statusCode}");
      return [];
    } catch (e) {
      debugPrint("FETCH ADMIN TABLE ERROR: $e");
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
