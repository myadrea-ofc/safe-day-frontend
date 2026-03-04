import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:safety_apps/models/p2h/p2h_lv.dart';

class P2HLVService {
  static const _storage = FlutterSecureStorage();
  static const String baseUrl = "http://safety.borneo.co.id/p2h_lv";

  static Future<bool> submitP2HLV({
    required String nama,
    required String jabatan,
    required String department,
    required String perusahaan,
    required String tanggal,
    required String brandUnit,
    required String noLambungUnit,
    required String lvSekarang,
    required String shiftKerja,

    required String opsiitem1,
    required String opsiitem2,
    required String opsiitem3,
    required String opsiitem4,
    required String opsiitem5,
    required String opsiitem6,
    required String opsiitem7,
    required String opsiitem8,
    required String opsiitem9,
    required String opsiitem10,
    required String opsiitem11,
    required String opsiitem12,
    required String opsiitem13,
    required String opsiitem14,
    required String opsiitem15,
    required String opsiitem16,
    required String opsiitem17,
    required String opsiitem18,
    required String opsiitem19,

    required String opsiStandardKeselamatan1,
    required String opsiStandardKeselamatan2,
    required String opsiStandardKeselamatan3,
    required String opsiStandardKeselamatan4,
    required String opsiStandardKeselamatan5,

    required String opsiStandardMasukTambang1,
    required String opsiStandardMasukTambang2,
    required String opsiStandardMasukTambang3,
    required String opsiStandardMasukTambang4,
    required String opsiStandardMasukTambang5,
    required String opsiStandardMasukTambang6,
    required String opsiStandardMasukTambang7,

    required String laporanTemuan,
    required String jamTidur,

    required String statusKeadaan1,
    required String statusKeadaan2,
    required String statusKeadaan3,
    required String statusKeadaan4,
    required String statusKeadaan5,
    required String statusKeadaan6,

    required String statusSiap,

    List<String>? filePaths,
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
        "jabatan": jabatan,
        "department": department,
        "perusahaan": perusahaan,
        "tanggal": tanggal,
        "brand_unit": brandUnit,
        "no_lambung_unit": noLambungUnit,
        "lv_sekarang": lvSekarang,
        "shift_kerja": shiftKerja,

        "opsiitem1": opsiitem1,
        "opsiitem2": opsiitem2,
        "opsiitem3": opsiitem3,
        "opsiitem4": opsiitem4,
        "opsiitem5": opsiitem5,
        "opsiitem6": opsiitem6,
        "opsiitem7": opsiitem7,
        "opsiitem8": opsiitem8,
        "opsiitem9": opsiitem9,
        "opsiitem10": opsiitem10,
        "opsiitem11": opsiitem11,
        "opsiitem12": opsiitem12,
        "opsiitem13": opsiitem13,
        "opsiitem14": opsiitem14,
        "opsiitem15": opsiitem15,
        "opsiitem16": opsiitem16,
        "opsiitem17": opsiitem17,
        "opsiitem18": opsiitem18,
        "opsiitem19": opsiitem19,

        "opsistandardkeselamatan1": opsiStandardKeselamatan1,
        "opsistandardkeselamatan2": opsiStandardKeselamatan2,
        "opsistandardkeselamatan3": opsiStandardKeselamatan3,
        "opsistandardkeselamatan4": opsiStandardKeselamatan4,
        "opsistandardkeselamatan5": opsiStandardKeselamatan5,

        "opsistandardmasuktambang1": opsiStandardMasukTambang1,
        "opsistandardmasuktambang2": opsiStandardMasukTambang2,
        "opsistandardmasuktambang3": opsiStandardMasukTambang3,
        "opsistandardmasuktambang4": opsiStandardMasukTambang4,
        "opsistandardmasuktambang5": opsiStandardMasukTambang5,
        "opsistandardmasuktambang6": opsiStandardMasukTambang6,
        "opsistandardmasuktambang7": opsiStandardMasukTambang7,

        "laporan_temuan": laporanTemuan,
        "jam_tidur": jamTidur,

        "status_keadaan1": statusKeadaan1,
        "status_keadaan2": statusKeadaan2,
        "status_keadaan3": statusKeadaan3,
        "status_keadaan4": statusKeadaan4,
        "status_keadaan5": statusKeadaan5,
        "status_keadaan6": statusKeadaan6,

        "status_siap": statusSiap,
      });

      if (filePaths != null && filePaths.isNotEmpty) {
        int i = 1;
        for (final path in filePaths.take(5)) {
          print("Uploading file $i/${filePaths.length}");
          request.files.add(
            await http.MultipartFile.fromPath(
              "files",
              path,
              filename: path.split('/').last,
              contentType: http.MediaType("image", "jpeg"),
            ),
          );
          i++;
        }
      }

      final streamedResponse = await client
          .send(request)
          .timeout(const Duration(minutes: 3));

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        return body["success"] == true;
      } else {
        print("Submit P2H LV Failed: ${response.statusCode}");
        print(response.body);
        return false;
      }
    } catch (e) {
      print("Submit P2H LV Exception: $e");
      return false;
    } finally {
      client.close();
    }
  }

  // ===================== GET =====================
  static Future<List<P2HLVModel>> fetchP2HLV() async {
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
      return data.map((e) => P2HLVModel.fromJson(e)).toList();
    } catch (e) {
      print("Error Fetch P2H LV: $e");
      return [];
    }
  }
}
