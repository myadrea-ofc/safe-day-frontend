import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MasterService {
  static const _storage = FlutterSecureStorage();
  static const String baseUrl = "http://safety.borneo.co.id";

  static Future<List<Map<String, dynamic>>> getSites() async {
    final res = await http.get(Uri.parse("$baseUrl/sites"));

    if (res.statusCode != 200) {
      throw Exception("Gagal mengambil site");
    }

    final List data = jsonDecode(res.body);
    return data.map((e) => {"id": e["id"], "name": e["name"]}).toList();
  }

  static Future<List<Map<String, dynamic>>> getDepartments(int siteId) async {
    final res = await http.get(
      Uri.parse("$baseUrl/departments?site_id=$siteId"),
    );

    if (res.statusCode != 200) {
      throw Exception("Gagal mengambil department");
    }

    final List data = jsonDecode(res.body);
    return data
        .map((e) => {"id": e["id"], "name": e["department_name"]})
        .toList();
  }
}
