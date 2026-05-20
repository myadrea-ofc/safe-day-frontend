import 'dart:convert';
import 'package:safety_apps/network/api_client.dart';

class ExcelAccessService {
  static Future<List<dynamic>> fetchAccess() async {
    final res = await ApiClient.get("/excel-access");

    if (res.statusCode != 200) {
      throw Exception("Fetch access gagal (${res.statusCode}): ${res.body}");
    }

    return jsonDecode(res.body) as List<dynamic>;
  }

  static Future<void> grant({
    required int userId,
    required int siteId,
    required String feature,
  }) async {
    final res = await ApiClient.post(
      "/excel-access/grant",
      body: {"user_id": userId, "site_id": siteId, "feature": feature},
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception("Grant gagal (${res.statusCode}): ${res.body}");
    }
  }

  static Future<void> revoke({
    required int userId,
    required int siteId,
    required String feature,
  }) async {
    final res = await ApiClient.post(
      "/excel-access/revoke",
      body: {"user_id": userId, "site_id": siteId, "feature": feature},
    );

    if (res.statusCode != 200) {
      throw Exception("Revoke gagal (${res.statusCode}): ${res.body}");
    }
  }

  static Future<Map<String, dynamic>> myAccess({
    required String feature,
  }) async {
    final res = await ApiClient.get("/excel-access/me?feature=$feature");

    if (res.statusCode != 200) {
      throw Exception("My access gagal (${res.statusCode}): ${res.body}");
    }

    return (jsonDecode(res.body) as Map).cast<String, dynamic>();
  }

  static Future<void> delete({
    required int userId,
    required int siteId,
    required String feature,
  }) async {
    final res = await ApiClient.post(
      "/excel-access/delete",
      body: {"user_id": userId, "site_id": siteId, "feature": feature},
    );

    if (res.statusCode != 200) {
      final data = jsonDecode(res.body);
      throw Exception(data["message"] ?? "Delete gagal");
    }
  }
}
