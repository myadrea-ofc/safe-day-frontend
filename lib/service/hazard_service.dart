import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:safety_apps/models/hazard.dart'; // Pastikan path model benar

class HazardService {
  static const _storage = FlutterSecureStorage();
  static const baseUrl = "http://safety.borneo.co.id/hazard";

  static Future<bool> submitHazard({
    required String nama,
    required String idKaryawan,
    required String perusahaan,
    required String jabatan,
    required String department,
    required String lokasiTemuan,
    required String tanggal,
    required String waktu,
    required String jenisTemuan,
    required String narasiTemuan,
    required String infoPerbaikan,
    required String statusSesuai,
    String? foto1Path,
    String? foto2Path,
    String? foto3Path,
  }) async {
    final token = await _storage.read(key: "jwt_token");
    final deviceId = await _storage.read(key: "device_id");

    if (token == null || deviceId == null) {
      throw Exception("Token atau Device ID tidak ditemukan");
    }
    final request = http.MultipartRequest("POST", Uri.parse(baseUrl));
    request.headers.addAll({
      "Authorization": "Bearer $token",
      "x-device-id": deviceId,
    });

    request.fields.addAll({
      "nama": nama,
      "id_karyawan": idKaryawan,
      "perusahaan": perusahaan,
      "jabatan": jabatan,
      "department": department,
      "lokasi_temuan": lokasiTemuan,
      "tanggal": tanggal,
      "waktu": waktu,
      "jenis_temuan": jenisTemuan,
      "narasi_temuan": narasiTemuan,
      "info_perbaikan": infoPerbaikan,
      "status_sesuai": statusSesuai,
    });

    if (foto1Path != null && foto1Path.isNotEmpty) {
      request.files.add(
        await http.MultipartFile.fromPath(
          "foto1",
          foto1Path,
          contentType: MediaType("image", "jpeg"),
        ),
      );
    }

    if (foto2Path != null && foto2Path.isNotEmpty) {
      request.files.add(
        await http.MultipartFile.fromPath(
          "foto2",
          foto2Path,
          contentType: MediaType("image", "jpeg"),
        ),
      );
    }

    if (foto3Path != null && foto3Path.isNotEmpty) {
      request.files.add(
        await http.MultipartFile.fromPath(
          "foto3",
          foto3Path,
          contentType: MediaType("image", "jpeg"),
        ),
      );
    }

    final response = await request.send();
    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<List<HazardModel>> fetchHazard() async {
    final token = await _storage.read(key: "jwt_token");
    final deviceId = await _storage.read(key: "device_id");

    if (token == null || deviceId == null) {
      throw Exception("Token atau Device ID tidak ditemukan");
    }

    try {
      final res = await http.get(
        Uri.parse(baseUrl),
        headers: {"Authorization": "Bearer $token", "x-device-id": deviceId},
      );

      if (res.statusCode != 200) return [];

      final List data = jsonDecode(res.body);
      return data.map((e) => HazardModel.fromJson(e)).toList();
    } catch (e) {
      print("Error Fetching Hazard: $e");
      return [];
    }
  }
}
