import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:safety_apps/models/p5m.dart';

class P5MService {
  static const _storage = FlutterSecureStorage();
  static const baseUrl = "http://safety.borneo.co.id/p5m";

  static Future<bool> submitP5M({
    required String nama,
    required String perusahaan,
    required String department,
    required String namaPembicara,
    required String topik,
    required String jabatan,
    required String kondisiKesehatan,
    required String jamTidur,
    required String siapKerja,
    required String statusHariKerja,
    required String umpanBalik,

    String? fotoPath,

    Uint8List? fotoBytes,
    String? fotoName,
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
      "perusahaan": perusahaan,
      "department": department,
      "nama_pembicara": namaPembicara,
      "topik": topik,
      "jabatan": jabatan,
      "kondisi_kesehatan": kondisiKesehatan,
      "jam_tidur": jamTidur,
      "siap_kerja": siapKerja,
      "status_hari_kerja": statusHariKerja,
      "umpan_balik": umpanBalik,
    });

    if (kIsWeb) {
      if (fotoBytes != null && fotoBytes.isNotEmpty) {
        request.files.add(
          http.MultipartFile.fromBytes(
            "foto",
            fotoBytes,
            filename: fotoName ?? "foto_p5m.jpg",
            contentType: MediaType("image", "jpeg"),
          ),
        );
      }
    } else {
      if (fotoPath != null && fotoPath.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath(
            "foto",
            fotoPath,
            contentType: MediaType("image", "jpeg"),
          ),
        );
      }
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    debugPrint("SUBMIT P5M STATUS: ${response.statusCode}");
    debugPrint("SUBMIT P5M RESPONSE: $responseBody");

    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<List<P5MModel>> fetchP5M() async {
    final token = await _storage.read(key: "jwt_token");
    final deviceId = await _storage.read(key: "device_id");

    if (token == null || deviceId == null) {
      throw Exception("Token atau Device ID tidak ditemukan");
    }

    final res = await http.get(
      Uri.parse(baseUrl),
      headers: {"Authorization": "Bearer $token", "x-device-id": deviceId},
    );

    if (res.statusCode != 200) return [];

    final List data = jsonDecode(res.body);
    return data.map((e) => P5MModel.fromJson(e)).toList();
  }
}
