import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:safety_apps/models/result/site_item.dart';

class SiteService {
  static const String baseUrl = "http://safety.borneo.co.id";

  static Future<List<SiteItem>> fetchSites() async {
    final res = await http
        .get(Uri.parse("$baseUrl/sites"))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw Exception("Gagal ambil sites: ${res.statusCode}");
    }

    final List data = jsonDecode(res.body);
    return data.map((e) {
      final name = (e["site_name"] ?? e["name"] ?? "").toString();
      return SiteItem(id: e["id"], name: name);
    }).toList();
  }
}
