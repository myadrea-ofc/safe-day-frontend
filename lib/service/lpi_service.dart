import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:safety_apps/models/lpi.dart';

class LPIService {
  static const _storage = FlutterSecureStorage();
  static const baseUrl = "http://safety.borneo.co.id/lpi";

  static Future<bool> submitLPI({
    required String nama,
    required String perusahaan,
    required String department,
    required String tanggal,
    required String waktu,
    required String namaKorban,
    required String jabatanKorban,
    required String namaSpv,
    required String departmentSpv,
    required String jenisAsetPerusahaan,
    required String namaSaksi,
    required String jabatanSaksi,
    required String departmentSaksi,
    required String klasifikasiInsiden,
    required String kronologi,
    required String statusLokasi,

    String? filePath,
    List<String>? fotoPaths,

    Uint8List? fileBytes,
    String? fileName,
    List<Uint8List>? fotoBytesList,
    List<String>? fotoNames,
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
      "tanggal": tanggal,
      "waktu": waktu,
      "nama_korban": namaKorban,
      "jabatan_korban": jabatanKorban,
      "nama_spv": namaSpv,
      "department_spv": departmentSpv,
      "jenis_aset_perusahaan": jenisAsetPerusahaan,
      "nama_saksi": namaSaksi,
      "jabatan_saksi": jabatanSaksi,
      "department_saksi": departmentSaksi,
      "klasifikasi_insiden": klasifikasiInsiden,
      "kronologi": kronologi,
      "status_lokasi": statusLokasi,
    });

    if (kIsWeb) {
      if (fileBytes != null && fileBytes.isNotEmpty) {
        request.files.add(
          http.MultipartFile.fromBytes(
            "file",
            fileBytes,
            filename: fileName ?? "dokumen",
            contentType: MediaType("application", "octet-stream"),
          ),
        );
      }
    } else {
      if (filePath != null && filePath.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath(
            "file",
            filePath,
            contentType: MediaType("application", "octet-stream"),
          ),
        );
      }
    }

    if (kIsWeb) {
      if (fotoBytesList != null && fotoBytesList.isNotEmpty) {
        for (int i = 0; i < fotoBytesList.length; i++) {
          final bytes = fotoBytesList[i];

          if (bytes.isEmpty) continue;

          request.files.add(
            http.MultipartFile.fromBytes(
              "foto",
              bytes,
              filename: fotoNames != null && i < fotoNames.length
                  ? fotoNames[i]
                  : "foto_$i.jpg",
              contentType: MediaType("image", "jpeg"),
            ),
          );
        }
      }
    } else {
      if (fotoPaths != null && fotoPaths.isNotEmpty) {
        for (final path in fotoPaths) {
          if (path.isEmpty) continue;

          request.files.add(
            await http.MultipartFile.fromPath(
              "foto",
              path,
              contentType: MediaType("image", "jpeg"),
            ),
          );
        }
      }
    }

    final response = await request.send();

    final responseBody = await response.stream.bytesToString();

    debugPrint("SUBMIT LPI STATUS: ${response.statusCode}");
    debugPrint("SUBMIT LPI RESPONSE: $responseBody");

    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<List<LPIModel>> fetchLPI() async {
    final token = await _storage.read(key: "jwt_token");
    final deviceId = await _storage.read(key: "device_id");

    if (token == null || deviceId == null) {
      throw Exception("Token atau Device ID tidak ditemukan");
    }

    final res = await http.get(
      Uri.parse(baseUrl),
      headers: {"Authorization": "Bearer $token", "x-device-id": deviceId},
    );

    if (res.statusCode != 200) {
      throw Exception("Gagal load LPI (${res.statusCode})");
    }

    final List data = jsonDecode(res.body);
    return data.map((e) => LPIModel.fromJson(e)).toList();
  }
}
