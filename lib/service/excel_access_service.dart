import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:safety_apps/service/user_service.dart';

class ExcelAccessService {
  static const String baseUrl = "http://safety.borneo.co.id";

  static Future<List<dynamic>> fetchAccess() async {
    final headers = await UserService.getHeaders(json: false);

    final res = await http.get(
      Uri.parse("$baseUrl/excel-access"),
      headers: headers,
    );

    if (res.statusCode != 200) {
      throw Exception("Fetch access gagal (${res.statusCode}): ${res.body}");
    }

    return jsonDecode(res.body) as List<dynamic>;
  }

  static Future<void> grant({required int userId, required int siteId}) async {
    final headers = await UserService.getHeaders();

    final res = await http.post(
      Uri.parse("$baseUrl/excel-access/grant"),
      headers: headers,
      body: jsonEncode({"user_id": userId, "site_id": siteId}),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception("Grant gagal (${res.statusCode}): ${res.body}");
    }
  }

  static Future<void> revoke({required int userId, required int siteId}) async {
    final headers = await UserService.getHeaders();

    final res = await http.post(
      Uri.parse("$baseUrl/excel-access/revoke"),
      headers: headers,
      body: jsonEncode({"user_id": userId, "site_id": siteId}),
    );

    if (res.statusCode != 200) {
      throw Exception("Revoke gagal (${res.statusCode}): ${res.body}");
    }
  }
}
