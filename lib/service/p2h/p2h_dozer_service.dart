import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:safety_apps/models/p2h/p2h_dozer.dart';

class P2HDozerService {
  static const _storage = FlutterSecureStorage();
  static const String baseUrl = "http://safety.borneo.co.id/p2h_dozer";

  static Future<bool> submitP2HDozer({
    required String nama,
    required String nrp,
    required String jabatan,
    required String department,
    required String perusahaan,
    required String lokasiKerja,
    required String noLambungUnit,
    required String hmUnit,
    required String waktu,
    required String brandUnit,
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
    required String opsiItem20,
    required String opsiItem21,
    required String opsiItem22,
    required String opsiItem23,
    required String opsiItem24,
    required String opsiItem25,
    required String opsiItem26,
    required String opsiItem27,
    required String opsiItem28,
    required String opsiItem29,
    required String opsiItem30,
    required String opsiItem31,
    required String opsiItem32,
    required String opsiItem33,

    required String kimperBerlaku,
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
        "nrp": nrp,
        "jabatan": jabatan,
        "department": department,
        "perusahaan": perusahaan,
        "lokasi_kerja": lokasiKerja,
        "no_lambung_unit": noLambungUnit,
        "hm_unit": hmUnit,
        "waktu": waktu,
        "brand_unit": brandUnit,
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
        "opsi_item20": opsiItem20,
        "opsi_item21": opsiItem21,
        "opsi_item22": opsiItem22,
        "opsi_item23": opsiItem23,
        "opsi_item24": opsiItem24,
        "opsi_item25": opsiItem25,
        "opsi_item26": opsiItem26,
        "opsi_item27": opsiItem27,
        "opsi_item28": opsiItem28,
        "opsi_item29": opsiItem29,
        "opsi_item30": opsiItem30,
        "opsi_item31": opsiItem31,
        "opsi_item32": opsiItem32,
        "opsi_item33": opsiItem33,

        "kimper_berlaku": kimperBerlaku,
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
        print("Submit P2H DOZER Failed: ${response.statusCode}");
        print(response.body);
        return false;
      }
    } catch (e) {
      print("Submit P2H DOZER Exception: $e");
      return false;
    } finally {
      client.close();
    }
  }

  static Future<List<P2HDozerModel>> fetchP2HDozer() async {
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
      return data.map((e) => P2HDozerModel.fromJson(e)).toList();
    } catch (e) {
      print("Error Fetch P2H DOZER: $e");
      return [];
    }
  }
}
