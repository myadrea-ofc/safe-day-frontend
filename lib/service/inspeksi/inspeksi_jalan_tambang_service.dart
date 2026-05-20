import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:safety_apps/models/inspeksi/inspeksi_jalan_tambang.dart';

class InspeksiJalanTambangService {
  static const _storage = FlutterSecureStorage();
  static const baseUrl = "http://safety.borneo.co.id/inspeksi_jalan_tambang";

  static Future<bool> submitInspeksiJalanTambang({
    required String nama,
    required String nrp,
    required String department,
    required String perusahaan,
    required String tanggal,
    required String jumlahInspektor,

    required String opsi1,
    required String opsi2,
    required String opsi3,
    required String opsi4,
    required String opsi5,
    required String opsi6,
    required String opsi7,
    required String opsi8,
    required String opsi9,
    required String opsi10,
    required String opsi11,
    required String opsi12,
    required String opsi13,
    required String opsi14,
    required String opsi15,
    required String opsi16,
    required String opsi17,
    required String opsi18,
    required String opsi19,
    required String opsi20,
    required String opsi21,
    required String opsi22,

    required String ketHasil,
    required String saranMasuk,
    required String statusInspeksi,
    required String apar,

    String? foto1Path,
    String? foto2Path,
    String? foto3Path,

    Uint8List? foto1Bytes,
    Uint8List? foto2Bytes,
    Uint8List? foto3Bytes,
    String? foto1Name,
    String? foto2Name,
    String? foto3Name,
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
      "nrp": nrp,
      "department": department,
      "perusahaan": perusahaan,
      "tanggal": tanggal,
      "jumlah_inspektor": jumlahInspektor,

      "opsi1": opsi1,
      "opsi2": opsi2,
      "opsi3": opsi3,
      "opsi4": opsi4,
      "opsi5": opsi5,
      "opsi6": opsi6,
      "opsi7": opsi7,
      "opsi8": opsi8,
      "opsi9": opsi9,
      "opsi10": opsi10,
      "opsi11": opsi11,
      "opsi12": opsi12,
      "opsi13": opsi13,
      "opsi14": opsi14,
      "opsi15": opsi15,
      "opsi16": opsi16,
      "opsi17": opsi17,
      "opsi18": opsi18,
      "opsi19": opsi19,
      "opsi20": opsi20,
      "opsi21": opsi21,
      "opsi22": opsi22,

      "ket_hasil": ketHasil,
      "saran_masuk": saranMasuk,
      "status_inspeksi": statusInspeksi,
      "apar": apar,
    });

    if (kIsWeb) {
      if (foto1Bytes != null && foto1Bytes.isNotEmpty) {
        request.files.add(
          http.MultipartFile.fromBytes(
            "foto1",
            foto1Bytes,
            filename: foto1Name ?? "foto1.jpg",
            contentType: MediaType("image", "jpeg"),
          ),
        );
      }

      if (foto2Bytes != null && foto2Bytes.isNotEmpty) {
        request.files.add(
          http.MultipartFile.fromBytes(
            "foto2",
            foto2Bytes,
            filename: foto2Name ?? "foto2.jpg",
            contentType: MediaType("image", "jpeg"),
          ),
        );
      }

      if (foto3Bytes != null && foto3Bytes.isNotEmpty) {
        request.files.add(
          http.MultipartFile.fromBytes(
            "foto3",
            foto3Bytes,
            filename: foto3Name ?? "foto3.jpg",
            contentType: MediaType("image", "jpeg"),
          ),
        );
      }
    } else {
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
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    debugPrint("SUBMIT INSPEKSI JALAN TAMBANG STATUS: ${response.statusCode}");
    debugPrint("SUBMIT INSPEKSI JALAN TAMBANG RESPONSE: $responseBody");

    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<List<InspeksiJalanTambangModel>>
  fetchInspeksiJalanTambang() async {
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
      return data.map((e) => InspeksiJalanTambangModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint("Error Fetch Inspeksi Jalan Tambang: $e");
      return [];
    }
  }
}
