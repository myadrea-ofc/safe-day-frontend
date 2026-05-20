import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:safety_apps/models/p2h/p2h_towerlamp.dart';

class P2HTowerlampService {
  static const _storage = FlutterSecureStorage();
  static const String baseUrl = "http://safety.borneo.co.id/p2h_towerlamp";

  static Future<bool> submitP2HTowerlamp({
    required String nama,
    required String nrp,
    required String jabatan,
    required String department,
    required String perusahaan,
    required String lokasiKerja,
    required String hmUnit,
    required String tanggal,

    required String opsiItem1,
    required String opsiItem2,
    required String opsiItem3,
    required String opsiItem4,
    required String opsiItem5,
    required String opsiItem6,
    required String opsiItem7,
    required String opsiItem8,
    required String opsiItem9,
    required String opsiItem10,
    required String opsiItem11,
    required String opsiItem12,
    required String opsiItem13,
    required String opsiItem14,
    required String opsiItem15,
    required String opsiItem16,
    required String opsiItem17,
    required String opsiItem18,
    required String opsiItem19,

    required String statusSiap,

    // Mobile/Desktop
    List<String>? filePaths,

    // Web
    List<Uint8List>? fileBytesList,
    List<String>? fileNames,
  }) async {
    final token = await _storage.read(key: "jwt_token");
    final deviceId = await _storage.read(key: "device_id");

    if (token == null || deviceId == null) {
      throw Exception("Token atau Device ID tidak ditemukan");
    }

    final client = http.Client();

    try {
      final request = http.MultipartRequest("POST", Uri.parse(baseUrl));

      request.headers.addAll({
        "Authorization": "Bearer $token",
        "x-device-id": deviceId,
      });

      request.fields.addAll({
        "nama": nama,
        "nrp": nrp,
        "jabatan": jabatan,
        "department": department,
        "perusahaan": perusahaan,
        "lokasi_kerja": lokasiKerja,
        "hm_unit": hmUnit,
        "tanggal": tanggal,

        "opsi_item1": opsiItem1,
        "opsi_item2": opsiItem2,
        "opsi_item3": opsiItem3,
        "opsi_item4": opsiItem4,
        "opsi_item5": opsiItem5,
        "opsi_item6": opsiItem6,
        "opsi_item7": opsiItem7,
        "opsi_item8": opsiItem8,
        "opsi_item9": opsiItem9,
        "opsi_item10": opsiItem10,
        "opsi_item11": opsiItem11,
        "opsi_item12": opsiItem12,
        "opsi_item13": opsiItem13,
        "opsi_item14": opsiItem14,
        "opsi_item15": opsiItem15,
        "opsi_item16": opsiItem16,
        "opsi_item17": opsiItem17,
        "opsi_item18": opsiItem18,
        "opsi_item19": opsiItem19,

        "status_siap": statusSiap,
      });

      if (kIsWeb) {
        if (fileBytesList != null && fileBytesList.isNotEmpty) {
          for (int i = 0; i < fileBytesList.take(5).length; i++) {
            final bytes = fileBytesList[i];

            if (bytes.isEmpty) continue;

            final name = fileNames != null && i < fileNames.length
                ? fileNames[i]
                : "file_${i + 1}.jpg";

            request.files.add(
              http.MultipartFile.fromBytes(
                "files",
                bytes,
                filename: name,
                contentType: _getMediaType(name),
              ),
            );
          }
        }
      } else {
        if (filePaths != null && filePaths.isNotEmpty) {
          int i = 1;

          for (final path in filePaths.take(5)) {
            if (path.isEmpty) continue;

            debugPrint("Uploading P2H TOWER LAMP file $i/${filePaths.length}");

            request.files.add(
              await http.MultipartFile.fromPath(
                "files",
                path,
                filename: path.split('/').last,
                contentType: _getMediaType(path),
              ),
            );

            i++;
          }
        }
      }

      final streamedResponse = await client
          .send(request)
          .timeout(const Duration(minutes: 3));

      final response = await http.Response.fromStream(streamedResponse);

      debugPrint("SUBMIT P2H TOWER LAMP STATUS: ${response.statusCode}");
      debugPrint("SUBMIT P2H TOWER LAMP RESPONSE: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);

        if (body is Map && body.containsKey("success")) {
          return body["success"] == true;
        }

        return true;
      }

      return false;
    } catch (e) {
      debugPrint("Submit P2H TOWER LAMP Exception: $e");
      return false;
    } finally {
      client.close();
    }
  }

  static MediaType _getMediaType(String fileName) {
    final lower = fileName.toLowerCase();

    if (lower.endsWith(".jpg") || lower.endsWith(".jpeg")) {
      return MediaType("image", "jpeg");
    }

    if (lower.endsWith(".png")) {
      return MediaType("image", "png");
    }

    if (lower.endsWith(".pdf")) {
      return MediaType("application", "pdf");
    }

    if (lower.endsWith(".doc")) {
      return MediaType("application", "msword");
    }

    if (lower.endsWith(".docx")) {
      return MediaType(
        "application",
        "vnd.openxmlformats-officedocument.wordprocessingml.document",
      );
    }

    if (lower.endsWith(".xls")) {
      return MediaType("application", "vnd.ms-excel");
    }

    if (lower.endsWith(".xlsx")) {
      return MediaType(
        "application",
        "vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      );
    }

    return MediaType("application", "octet-stream");
  }

  static Future<List<P2HTowerlampModel>> fetchP2HTowerlamp() async {
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
      return data.map((e) => P2HTowerlampModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint("Error Fetch P2H TOWERLAMP: $e");
      return [];
    }
  }
}
